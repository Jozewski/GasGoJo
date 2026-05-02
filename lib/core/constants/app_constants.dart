import 'api_keys.dart';

abstract final class AppConstants {
  // Map
  static const double defaultLatitude = 37.7749;   // San Francisco fallback
  static const double defaultLongitude = -122.4194;
  static const double defaultZoom = 13.5;
  static const double stationFetchRadiusMeters = 8000; // ~5 miles

  // Bottom sheet snap points (fraction of screen height)
  static const double sheetMinSize = 0.12;
  static const double sheetInitialSize = 0.38;
  static const double sheetMaxSize = 0.92;

  // Prices
  static const double minAlertPrice = 1.00;
  static const double priceStalenessHours = 4;

  // Pagination
  static const int stationPageSize = 20;

  // Hive boxes
  static const String stationsBox = 'stations_cache';
  static const String favoritesBox = 'favorites_cache';
  static const String alertsBox = 'alerts_cache';
  static const String settingsBox = 'settings';

  // FCM
  static const String fcmTopicPrefix = 'station_';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration cacheExpiry = Duration(minutes: 30);
}

abstract final class ApiConstants {
  static const String googleMapsApiKey = kGoogleMapsApiKeyWindows;
  static const String googleMapsApiKeyAndroid = kGoogleMapsApiKeyAndroid;
  static const String eiaBaseUrl = 'https://api.eia.gov/v2';
}
