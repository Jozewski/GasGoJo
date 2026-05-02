# GasGojo — Setup Guide

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | ≥ 3.3.0 (stable) | flutter.dev |
| Dart SDK | ≥ 3.3.0 (bundled with Flutter) | — |
| Android Studio / VS Code | Latest | — |
| Firebase CLI | ≥ 13.0 | `npm install -g firebase-tools` |
| FlutterFire CLI | Latest | `dart pub global activate flutterfire_cli` |
| Node.js | ≥ 20 LTS | nodejs.org (for Cloud Functions) |

---

## Step 1 — Clone & Install Dependencies

```bash
# After unzipping the project
cd gasgojo
flutter pub get
```

---

## Step 2 — Firebase Project Setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a new project named **GasGojo**.
2. Enable these products:
   - Authentication → Email/Password + Google Sign-In
   - Firestore Database (start in **production** mode)
   - Cloud Messaging
   - Analytics
   - Remote Config
   - Crashlytics
3. Register your Android app with package name `com.gasgojo.app`.
4. Download `google-services.json` and place it at `android/app/google-services.json`.

### Run FlutterFire Configure

```bash
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

This generates `lib/firebase_options.dart`. Then uncomment this line in `lib/main.dart`:

```dart
// import 'firebase_options.dart';
// options: DefaultFirebaseOptions.currentPlatform,
```

---

## Step 3 — Google Maps API Key

1. Go to [console.cloud.google.com](https://console.cloud.google.com) → APIs & Services → Credentials.
2. Create an API Key. Restrict it to:
   - **Android apps** (your SHA-1 + package name)
   - **APIs**: Maps SDK for Android, Places API, Directions API.
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml`.
4. Also update `lib/core/constants/app_constants.dart`.

> **Security:** Never commit your raw API key to git. Use a CI secret or `android/local.properties` for the key, referenced in `build.gradle`.

---

## Step 4 — Firestore Indexes

Create these composite indexes in your Firestore console (or deploy via `firestore.indexes.json`):

```json
{
  "indexes": [
    {
      "collectionGroup": "stations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "geopoint.lat", "order": "ASCENDING" },
        { "fieldPath": "brand", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "entries",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "reportedBy", "order": "ASCENDING" },
        { "fieldPath": "reportedAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## Step 5 — Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

---

## Step 6 — Deploy Cloud Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

Set the EIA API key as a Firebase secret:
```bash
firebase functions:secrets:set EIA_API_KEY
```

---

## Step 7 — Remote Config Setup

In Firebase Console → Remote Config, create these parameters:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `data_source_eia_enabled` | Boolean | `true` | Enable EIA price ingestion |
| `data_source_gasbuddy_enabled` | Boolean | `false` | Enable GasBuddy (needs partner key) |
| `price_staleness_threshold_hours` | Number | `4` | Hours before price is shown as stale |
| `max_alerts_per_user` | Number | `20` | Cap on user price alerts |

---

## Step 8 — Android Signing (Release Build)

1. Generate a keystore:
```bash
keytool -genkey -v -keystore gasgojo-release.jks \
  -alias gasgojo -keyalg RSA -keysize 2048 -validity 10000
```

2. Create `android/key.properties` (NOT committed to git — add to `.gitignore`):
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=gasgojo
storeFile=../gasgojo-release.jks
```

3. Build release AAB:
```bash
flutter build appbundle --release
```

---

## Step 9 — First Run (Debug)

```bash
flutter run --debug
```

The app will open on a device/emulator at the default map position (San Francisco). It will show an empty station list until you populate Firestore with station data.

### Seed Test Data

In Firebase Console → Firestore, create a document in the `stations` collection:

```json
{
  "name": "Shell Test Station",
  "brand": "shell",
  "geopoint": { "lat": 37.7749, "lng": -122.4194 },
  "address": "123 Main St",
  "city": "San Francisco",
  "state": "CA",
  "zip": "94102",
  "prices": {
    "regular": 3.09,
    "midGrade": 3.59,
    "premium": 3.99,
    "diesel": 3.79
  },
  "pricesUpdatedAt": 1700000000000,
  "isOpen": true,
  "amenities": ["carWash", "atm", "restroom", "snacks"],
  "hours": {
    "0": { "open": "06:00 AM", "close": "10:00 PM", "is24Hours": false },
    "1": { "open": "06:00 AM", "close": "10:00 PM", "is24Hours": false },
    "2": { "open": "06:00 AM", "close": "10:00 PM", "is24Hours": false },
    "3": { "open": "06:00 AM", "close": "10:00 PM", "is24Hours": false },
    "4": { "open": "06:00 AM", "close": "10:00 PM", "is24Hours": false },
    "5": { "open": "06:00 AM", "close": "10:00 PM", "is24Hours": false },
    "6": { "open": "07:00 AM", "close": "09:00 PM", "is24Hours": false }
  },
  "rating": 4.2,
  "reviewCount": 128
}
```

---

## Project File Map

```
lib/
  main.dart                        ← Firebase init, DI setup, app entry
  app/
    app.dart                       ← MaterialApp.router, BLoC providers
    router.dart                    ← go_router route definitions
    theme/
      app_colors.dart              ← Brand color constants
      app_theme.dart               ← ThemeData (Material 3)
  core/
    constants/app_constants.dart   ← Map radius, sheet sizes, Hive box names
    error/failures.dart            ← Sealed Failure classes
  shared/
    models/gas_station.dart        ← All data models (GasStation, FuelFilter, PriceAlert)
    widgets/shared_widgets.dart    ← PriceBadge, LoadingOverlay, ErrorView, EmptyState
  features/
    map/
      data/repositories/           ← Firestore station query logic
      presentation/
        bloc/                      ← MapBloc, MapEvent, MapState
        screens/map_screen.dart    ← Home screen (Map + Bottom Sheet)
        widgets/
          bottom_sheet.dart        ← Draggable station list
          sort_bar.dart            ← Cheapest/Nearest/Brand chips
          station_card.dart        ← List card
    station_detail/
      presentation/screens/        ← Station detail (prices, hours, amenities)
    filters/
      presentation/
        cubit/                     ← FilterCubit + FilterState
        screens/filter_screen.dart ← Full-screen filter UI
    favorites/
      presentation/screens/        ← My Stations + Compare tabs
    price_alerts/
      presentation/screens/        ← Alert creation screen
functions/
  index.js                         ← Price ingestion, alert trigger, report validation
android/
  app/
    build.gradle                   ← App ID, signing, ProGuard, Firebase plugins
    proguard-rules.pro             ← Keep rules for release build
    src/main/AndroidManifest.xml   ← Permissions, Maps key, FCM config
firestore.rules                    ← Firestore security rules
```

---

## Next Features to Build

The following are stubbed/noted in the code but not yet implemented:

- [ ] Auth screen (login/register with email + Google Sign-In)
- [ ] FavoritesCubit backed by Firestore
- [ ] AlertsCubit with FCM topic management
- [ ] Google Places autocomplete in the search bar
- [ ] Hive local cache for offline-first station list
- [ ] GasBuddy partner API integration (needs partner approval)
- [ ] In-app review prompt (`in_app_review` package) after 3rd gas trip
- [ ] Analytics event logging (`firebase_analytics`)
- [ ] Push notification deep-link routing

---

## Useful Commands

```bash
flutter analyze                    # Static analysis (zero warnings target)
flutter test                       # Run unit + widget tests
flutter build appbundle --release  # Release AAB for Play Store
firebase deploy --only functions   # Deploy Cloud Functions
firebase emulators:start           # Local Firebase emulator (recommended for dev)
```
