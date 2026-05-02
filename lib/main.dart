import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/platform/maps_init.dart';
import 'core/error/failures.dart';
import 'core/services/places_service.dart';
import 'features/map/data/repositories/station_repository.dart';
import 'features/map/data/repositories/places_station_repository.dart';
import 'shared/models/gas_station.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Google Maps API key (web/Windows renderer) ──────────────────────
  await initializeMapsApiKey(ApiConstants.googleMapsApiKey);

  // ── System UI ───────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase ─────────────────────────────────────────────────────────────
  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseAvailable = true;

    // Route Flutter errors to Crashlytics in release mode (not supported on Windows)
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }

    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    // Firebase not configured yet — run `flutterfire configure` to set up.
    // The app will run in offline/demo mode.
    debugPrint('Firebase init skipped: $e');
  }

  // ── Dependency Injection ──────────────────────────────────────────────────
  _setupDependencies(firebaseAvailable: firebaseAvailable);

  runApp(const GasGojoApp());
}

void _setupDependencies({required bool firebaseAvailable}) {
  final getIt = GetIt.instance;

  // Data layer
  if (firebaseAvailable) {
    final placesService = PlacesService();
    getIt.registerLazySingleton<StationRepository>(
      () => PlacesStationRepository(
        placesService: placesService,
        firestore: FirebaseFirestore.instance,
      ),
    );
  } else {
    getIt.registerLazySingleton<StationRepository>(
      () => _OfflineStationRepository(),
    );
  }

  // Repositories for other features registered here as they are built:
  // getIt.registerLazySingleton<FavoritesRepository>(...)
  // getIt.registerLazySingleton<AuthRepository>(...)
  // getIt.registerLazySingleton<AlertsRepository>(...)
}

/// Fallback repository used when Firebase is not yet configured.
/// Returns empty results so the UI can still render.
class _OfflineStationRepository implements StationRepository {
  @override
  Future<Either<Failure, List<GasStation>>> getStationsNearby({
    required LatLng center,
    required double radiusMeters,
    FuelFilter? filter,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, GasStation>> getStationById(String id) async =>
      const Left(FirestoreFailure('Firebase not configured'));

  @override
  Future<Either<Failure, void>> reportPrice({
    required String stationId,
    required FuelGrade grade,
    required double price,
    required String userId,
  }) async =>
      const Left(FirestoreFailure('Firebase not configured'));
}
