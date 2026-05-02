// functions/index.js
// Deploy: firebase deploy --only functions
// Runtime: Node.js 20

const functions = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();
const db = admin.firestore();

// ─── Constants ────────────────────────────────────────────────────────────

const EIA_API_KEY = process.env.EIA_API_KEY;
const EIA_BASE_URL = 'https://api.eia.gov/v2';

// Price outlier guard: reject any price > 150% of EIA regional average
const OUTLIER_THRESHOLD = 1.5;

// ─── 1. Price Ingestion (Scheduled every 30 minutes) ─────────────────────

exports.priceIngest = functions.scheduler.onSchedule(
  {
    schedule: 'every 30 minutes',
    timeZone: 'America/New_York',
    memory: '512MiB',
  },
  async () => {
    try {
      const config = await admin.remoteConfig().getTemplate();
      const params = config.parameters;

      const eiaEnabled = params['data_source_eia_enabled']?.defaultValue?.value === 'true';
      const gasBuddyEnabled = params['data_source_gasbuddy_enabled']?.defaultValue?.value === 'true';

      const results = [];

      if (eiaEnabled) {
        const eiaData = await fetchEiaPrices();
        results.push(...eiaData);
      }

      if (gasBuddyEnabled) {
        // GasBuddy partner API — requires approved partner key
        // const gbData = await fetchGasBuddyPrices();
        // results.push(...gbData);
        console.log('GasBuddy integration placeholder — add partner key to enable.');
      }

      if (results.length > 0) {
        await batchWriteStations(results);
        console.log(`Ingested ${results.length} price records.`);
      }
    } catch (err) {
      console.error('Price ingest failed:', err);
    }
  }
);

// ─── 2. Alert Trigger (Firestore onWrite — stations collection) ───────────

exports.checkPriceAlerts = functions.firestore.onDocumentUpdated(
  'stations/{stationId}',
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const stationId = event.params.stationId;

    if (!before || !after) return;

    const grades = ['regular', 'midGrade', 'premium', 'diesel'];

    for (const grade of grades) {
      const oldPrice = before.prices?.[grade];
      const newPrice = after.prices?.[grade];

      if (!newPrice || newPrice >= oldPrice) continue; // Only alert on price drops

      // Find users with alerts for this station/grade at or above new price
      const alertsSnap = await db
        .collectionGroup('alerts')
        .where('stationId', '==', stationId)
        .where('grade', '==', grade)
        .where('targetPrice', '>=', newPrice)
        .where('notifyEnabled', '==', true)
        .get();

      if (alertsSnap.empty) continue;

      const stationName = after.name || 'Station';
      const priceStr = `$${newPrice.toFixed(2)}`;

      const message = {
        topic: `station_${stationId}_${grade}`,
        notification: {
          title: `Price drop at ${stationName}!`,
          body: `${gradeLabel(grade)} is now ${priceStr}/gal — your target reached.`,
        },
        data: {
          type: 'price_alert',
          stationId,
          grade,
          price: newPrice.toString(),
        },
        android: {
          channelId: 'gasgojo_price_alerts',
          priority: 'high',
          notification: {
            icon: 'ic_notification',
            color: '#F97316',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
      };

      await admin.messaging().send(message);
      console.log(`Alert sent: ${stationId}/${grade} at ${priceStr}`);
    }
  }
);

// ─── 3. Price Report Validation (Firestore onCreate) ─────────────────────

exports.validatePriceReport = functions.firestore.onDocumentCreated(
  'priceHistory/{stationId}/entries/{entryId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const stationId = event.params.stationId;
    const { grade, price, reportedBy } = data;

    // Rate limiting: check how many reports this user submitted in the last hour
    const oneHourAgo = Date.now() - 3600000;
    const recentSnap = await db
      .collectionGroup('entries')
      .where('reportedBy', '==', reportedBy)
      .where('reportedAt', '>=', new admin.firestore.Timestamp(Math.floor(oneHourAgo / 1000), 0))
      .get();

    if (recentSnap.size > 5) {
      console.warn(`Rate limit hit for user ${reportedBy}`);
      await event.data.ref.delete();
      return;
    }

    // Outlier check vs. EIA regional average
    const stationDoc = await db.collection('stations').doc(stationId).get();
    const stationData = stationDoc.data();
    const currentPrice = stationData?.prices?.[grade];

    if (currentPrice && price > currentPrice * OUTLIER_THRESHOLD) {
      console.warn(`Outlier price rejected: $${price} vs current $${currentPrice}`);
      await event.data.ref.delete();
      return;
    }

    // Blend with existing price: 70% current API, 30% community report
    if (currentPrice) {
      const blended = currentPrice * 0.7 + price * 0.3;
      await db.collection('stations').doc(stationId).update({
        [`prices.${grade}`]: parseFloat(blended.toFixed(3)),
        pricesUpdatedAt: Date.now(),
        lastReportedBy: 'community',
      });
    }
  }
);

// ─── Helpers ──────────────────────────────────────────────────────────────

async function fetchEiaPrices() {
  try {
    const response = await axios.get(`${EIA_BASE_URL}/petroleum/pri/gnd/data/`, {
      params: {
        api_key: EIA_API_KEY,
        frequency: 'weekly',
        'data[0]': 'value',
        'facets[product][]': 'EPM0',  // Regular gasoline
        sort: [{ column: 'period', direction: 'desc' }],
        length: 50,
      },
      timeout: 8000,
    });

    return response.data?.response?.data || [];
  } catch (err) {
    console.error('EIA fetch error:', err.message);
    return [];
  }
}

async function batchWriteStations(records) {
  const batchSize = 500;
  for (let i = 0; i < records.length; i += batchSize) {
    const batch = db.batch();
    const chunk = records.slice(i, i + batchSize);
    for (const record of chunk) {
      if (!record.stationId) continue;
      const ref = db.collection('stations').doc(record.stationId);
      batch.update(ref, {
        [`prices.${record.grade}`]: record.price,
        pricesUpdatedAt: Date.now(),
        lastIngestionSource: record.source || 'eia',
      });
    }
    await batch.commit();
  }
}

function gradeLabel(grade) {
  return { regular: 'Regular', midGrade: 'Mid-Grade', premium: 'Premium', diesel: 'Diesel' }[grade] || grade;
}

// ─── 4. Places API Proxy (HTTPS callable) ────────────────────────────────
// Proxies Google Places API (New) requests server-side to avoid CORS issues
// when called from the Flutter web app in the browser.

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;

exports.nearbyGasStations = onCall(
  { cors: true },
  async (request) => {
    const { latitude, longitude, radiusMeters = 8000, maxResults = 20 } = request.data;

    if (typeof latitude !== 'number' || typeof longitude !== 'number') {
      throw new HttpsError('invalid-argument', 'latitude and longitude are required numbers.');
    }

    if (!GOOGLE_MAPS_API_KEY) {
      throw new HttpsError(
        'failed-precondition',
        'GOOGLE_MAPS_API_KEY is not configured for nearbyGasStations.'
      );
    }

    try {
      const response = await axios.post(
        'https://places.googleapis.com/v1/places:searchNearby',
        {
          includedTypes: ['gas_station'],
          maxResultCount: Math.min(maxResults, 20),
          locationRestriction: {
            circle: {
              center: { latitude, longitude },
              radius: radiusMeters,
            },
          },
        },
        {
          headers: {
            'X-Goog-Api-Key': GOOGLE_MAPS_API_KEY,
            'X-Goog-FieldMask': [
              'places.id',
              'places.displayName',
              'places.formattedAddress',
              'places.location',
              'places.rating',
              'places.nationalPhoneNumber',
              'places.regularOpeningHours.openNow',
              'places.businessStatus',
            ].join(','),
            'Content-Type': 'application/json',
          },
          timeout: 10000,
        }
      );

      const rawPlaces = response.data?.places || [];
      const places = rawPlaces.map((p) => ({
        id: p.id || '',
        displayName: {
          text: p.displayName?.text || '',
          languageCode: p.displayName?.languageCode || 'en',
        },
        formattedAddress: p.formattedAddress || '',
        location: {
          latitude: Number(p.location?.latitude || 0),
          longitude: Number(p.location?.longitude || 0),
        },
        rating: p.rating != null ? Number(p.rating) : null,
        nationalPhoneNumber: p.nationalPhoneNumber || null,
        regularOpeningHours: {
          openNow: Boolean(p.regularOpeningHours?.openNow ?? true),
        },
        businessStatus: p.businessStatus || 'OPERATIONAL',
      }));

      return { places };
    } catch (err) {
      const status = err?.response?.status;
      const message = err?.response?.data?.error?.message || err?.message || 'Unknown Places API error';

      console.error('Places API error:', err?.response?.data || err?.message);

      if (status === 403) {
        throw new HttpsError(
          'failed-precondition',
          'Places API access denied. Enable Places API (New) and verify API key restrictions.',
          { upstreamMessage: message }
        );
      }

      if (status === 400) {
        throw new HttpsError('invalid-argument', 'Invalid Places API request payload.', {
          upstreamMessage: message,
        });
      }

      throw new HttpsError('internal', 'Failed to fetch nearby gas stations.', {
        upstreamMessage: message,
      });
    }
  }
);
