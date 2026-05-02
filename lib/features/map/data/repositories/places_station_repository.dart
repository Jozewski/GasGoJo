import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/places_service.dart';
import '../../../../shared/models/gas_station.dart';
import 'station_repository.dart';

class PlacesStationRepository implements StationRepository {
  PlacesStationRepository({
    required PlacesService placesService,
    required FirebaseFirestore firestore,
  })  : _places = placesService,
        _firestore = firestore;

  final PlacesService _places;
  final FirebaseFirestore _firestore;

  @override
  Future<Either<Failure, List<GasStation>>> getStationsNearby({
    required LatLng center,
    required double radiusMeters,
    FuelFilter? filter,
  }) async {
    try {
      final results = await _places.getNearbyGasStations(
        latitude: center.latitude,
        longitude: center.longitude,
        radiusMeters: radiusMeters,
        maxResults: AppConstants.stationPageSize,
      );

      if (results.isEmpty) return const Right([]);

      // Fetch any user-reported prices from Firestore
      final placeIds = results.map((r) => r.placeId).toList();
      final pricesByPlaceId = await _fetchPrices(placeIds);

      // Fetch EIA state-level baseline prices (keyed by 2-letter state code)
      final eiaByState = await _fetchEiaBaselines(results);

      // Map to GasStation model
      var stations = results.map((place) {
        final distanceM = Geolocator.distanceBetween(
          center.latitude, center.longitude,
          place.location.latitude, place.location.longitude,
        );
        final priceData = pricesByPlaceId[place.placeId];
        // Use user-reported prices if available, else fall back to EIA baseline
        final prices = (priceData?['prices'] as Map<FuelGrade, double>?)
            ?? eiaByState[_extractState(place.formattedAddress)]
            ?? {};
        final updatedAt = priceData?['updatedAt'] as DateTime? ?? DateTime.now();

        return _toGasStation(place, prices, updatedAt, distanceM / 1609.34);
      }).toList();

      // Apply filters
      if (filter != null) {
        if (filter.brands.isNotEmpty) {
          stations =
              stations.where((s) => filter.brands.contains(s.brand)).toList();
        }
        if (filter.openNow) {
          stations = stations.where((s) => s.isOpen).toList();
        }
        if (filter.maxDistanceMiles != null) {
          stations = stations
              .where((s) => s.distanceMiles <= filter.maxDistanceMiles!)
              .toList();
        }
      }

      stations.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
      return Right(stations);
    } on FirebaseFunctionsException catch (_) {
      return _fallbackToFirestore(
        center: center,
        radiusMeters: radiusMeters,
        filter: filter,
      );
    } catch (e) {
      return _fallbackToFirestore(
        center: center,
        radiusMeters: radiusMeters,
        filter: filter,
      );
    }
  }

  Future<Either<Failure, List<GasStation>>> _fallbackToFirestore({
    required LatLng center,
    required double radiusMeters,
    FuelFilter? filter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('stations');

      if (filter?.brands.isNotEmpty == true) {
        final brandNames = filter!.brands.map((b) => b.name).toList();
        query = query.where('brand', whereIn: brandNames);
      }

      final snapshot = await query
          .limit(AppConstants.stationPageSize * 2)
          .get()
          .timeout(AppConstants.apiTimeout);

      var stations = snapshot.docs
          .map((doc) => GasStation.fromFirestore(doc.data(), doc.id))
          .map((s) {
            final distanceM = Geolocator.distanceBetween(
              center.latitude,
              center.longitude,
              s.location.latitude,
              s.location.longitude,
            );
            return s.copyWith(distanceMiles: distanceM / 1609.34);
          })
          .where((s) => s.distanceMiles * 1609.34 <= radiusMeters)
          .toList();

      if (filter != null) {
        if (filter.openNow) {
          stations = stations.where((s) => s.isOpen).toList();
        }
        if (filter.maxDistanceMiles != null) {
          stations = stations
              .where((s) => s.distanceMiles <= filter.maxDistanceMiles!)
              .toList();
        }
      }

      stations.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));

      if (stations.length > AppConstants.stationPageSize) {
        stations = stations.sublist(0, AppConstants.stationPageSize);
      }

      return Right(stations);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Could not load stations.'));
    } catch (_) {
      return const Left(NetworkFailure('Could not fetch gas stations.'));
    }
  }

  @override
  Future<Either<Failure, GasStation>> getStationById(String id) async {
    return const Left(NotFoundFailure('Station not found.'));
  }

  @override
  Future<Either<Failure, void>> reportPrice({
    required String stationId,
    required FuelGrade grade,
    required double price,
    required String userId,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Run both writes in parallel — they are independent
      await Future.wait([
        _firestore.collection('stationPrices').doc(stationId).set(
          {
            'prices': {grade.name: price},
            'updatedAt': now,
          },
          SetOptions(merge: true),
        ),
        _firestore
            .collection('priceHistory')
            .doc(stationId)
            .collection('entries')
            .add({
          'grade': grade.name,
          'price': price,
          'reportedBy': userId,
          'reportedAt': FieldValue.serverTimestamp(),
        }),
      ]);

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(
          FirestoreFailure(e.message ?? 'Could not submit price report.'));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Fetches EIA state-level baseline prices for all unique states in results.
  Future<Map<String, Map<FuelGrade, double>>> _fetchEiaBaselines(
      List<PlaceResult> results) async {
    final states = results
        .map((r) => _extractState(r.formattedAddress))
        .whereType<String>()
        .toSet();
    if (states.isEmpty) return {};

    try {
      final snapshot = await _firestore
          .collection('eiaStatePrices')
          .where(FieldPath.documentId, whereIn: states.toList())
          .get();

      final result = <String, Map<FuelGrade, double>>{};
      for (final doc in snapshot.docs) {
        final pricesRaw = doc.data()['prices'] as Map<String, dynamic>? ?? {};
        final prices = <FuelGrade, double>{};
        for (final entry in pricesRaw.entries) {
          final grade =
              FuelGrade.values.where((g) => g.name == entry.key).firstOrNull;
          if (grade != null) prices[grade] = (entry.value as num).toDouble();
        }
        if (prices.isNotEmpty) result[doc.id] = prices;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Extracts the 2-letter state code from a formatted address like
  /// "123 Main St, Phoenix, AZ 85001, USA"
  String? _extractState(String formattedAddress) {
    final parts = formattedAddress.split(', ');
    if (parts.length < 3) return null;
    final stateZip = parts[parts.length - 2].trim().split(' ');
    final code = stateZip.first.trim();
    return code.length == 2 ? code : null;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<Map<String, Map<String, dynamic>>> _fetchPrices(
      List<String> placeIds) async {
    if (placeIds.isEmpty) return {};
    try {
      final snapshot = await _firestore
          .collection('stationPrices')
          .where(FieldPath.documentId, whereIn: placeIds)
          .get();

      final result = <String, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final pricesRaw = data['prices'] as Map<String, dynamic>? ?? {};
        final prices = <FuelGrade, double>{};
        for (final entry in pricesRaw.entries) {
          final grade =
              FuelGrade.values.where((g) => g.name == entry.key).firstOrNull;
          if (grade != null) prices[grade] = (entry.value as num).toDouble();
        }
        result[doc.id] = {
          'prices': prices,
          'updatedAt': data['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
              : DateTime.now(),
        };
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  GasStation _toGasStation(
    PlaceResult place,
    Map<FuelGrade, double> prices,
    DateTime pricesUpdatedAt,
    double distanceMiles,
  ) {
    final parts = _parseAddress(place.formattedAddress);
    return GasStation(
      id: place.placeId,
      name: place.name,
      brand: _detectBrand(place.name),
      location: place.location,
      address: parts['address'] ?? '',
      city: parts['city'] ?? '',
      state: parts['state'] ?? '',
      zip: parts['zip'] ?? '',
      prices: prices,
      pricesUpdatedAt: pricesUpdatedAt,
      distanceMiles: distanceMiles,
      isOpen: place.isOpen,
      amenities: const [],
      hours: const OpeningHours(days: {}),
      rating: place.rating,
      reviewCount: place.userRatingCount,
      placeId: place.placeId,
      phoneNumber: place.phoneNumber,
    );
  }

  /// Parses "123 Main St, Phoenix, AZ 85001, USA" into components.
  Map<String, String> _parseAddress(String formattedAddress) {
    final parts = formattedAddress.split(', ');
    if (parts.length < 2) return {'address': formattedAddress};

    final address = parts[0];
    final city = parts.length > 1 ? parts[1] : '';
    String state = '';
    String zip = '';

    if (parts.length > 2) {
      // "AZ 85001" or just "AZ"
      final stateZip = parts[2].split(' ');
      state = stateZip.isNotEmpty ? stateZip[0] : '';
      zip = stateZip.length > 1 ? stateZip[1] : '';
    }

    return {'address': address, 'city': city, 'state': state, 'zip': zip};
  }

  StationBrand _detectBrand(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('shell')) return StationBrand.shell;
    if (lower.contains('exxon')) return StationBrand.exxon;
    if (lower.contains('chevron')) return StationBrand.chevron;
    if (lower.contains('circle k') || lower.contains('circlek')) {
      return StationBrand.circleK;
    }
    if (lower.contains(' bp') || lower.startsWith('bp')) return StationBrand.bp;
    if (lower.contains('mobil')) return StationBrand.mobil;
    if (lower.contains('texaco')) return StationBrand.texaco;
    if (lower.contains('phillips 66') || lower.contains('phillips66')) {
      return StationBrand.phillips66;
    }
    if (lower.contains('sunoco')) return StationBrand.sunoco;
    return StationBrand.other;
  }
}
