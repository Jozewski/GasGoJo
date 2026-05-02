import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceResult {
  const PlaceResult({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.location,
    required this.isOpen,
    this.rating,
    this.userRatingCount,
    this.phoneNumber,
  });

  final String placeId;
  final String name;
  final String formattedAddress;
  final LatLng location;
  final bool isOpen;
  final double? rating;
  final int? userRatingCount;
  final String? phoneNumber;
}

class PlacesService {
  PlacesService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _functionUrl =
      'https://us-central1-gasgojo-app-c4d11.cloudfunctions.net/nearbyGasStations';

  Future<List<PlaceResult>> getNearbyGasStations({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    int maxResults = 20,
  }) async {
    // Use plain HTTP to avoid cloud_functions SDK issues on web
    // (Int64 in dart2js, Pigeon channel unsupported in WASM).
    final response = await _dio.post<dynamic>(
      _functionUrl,
      data: {
        'data': {
          'latitude': latitude,
          'longitude': longitude,
          'radiusMeters': radiusMeters,
          'maxResults': maxResults,
        },
      },
      options: Options(
        headers: const {'Content-Type': 'application/json'},
        responseType: ResponseType.json,
        sendTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ),
    );

    final root = Map<String, dynamic>.from(response.data as Map);
    // Cloud Functions v2 wraps response in { result: { places: [...] } }
    final inner = root['result'] is Map
        ? Map<String, dynamic>.from(root['result'] as Map)
        : root;
    final rawPlaces = inner['places'] as List<dynamic>? ?? [];
    debugPrint('[PlacesService] Got ${rawPlaces.length} places');
    return rawPlaces.map(_parsePlace).whereType<PlaceResult>().toList();
  }

  PlaceResult? _parsePlace(dynamic json) {
    try {
      // Safely convert nested maps (web returns Map<Object?, Object?>)
      final map = Map<String, dynamic>.from(json as Map);
      final locationMap = Map<String, dynamic>.from(map['location'] as Map);
      final rawHours = map['regularOpeningHours'];
      final openingHours = rawHours != null
          ? Map<String, dynamic>.from(rawHours as Map)
          : null;
      final rawDisplay = Map<String, dynamic>.from(map['displayName'] as Map);

      return PlaceResult(
        placeId: map['id'] as String,
        name: rawDisplay['text'] as String,
        formattedAddress: map['formattedAddress'] as String? ?? '',
        location: LatLng(
          (locationMap['latitude'] as num).toDouble(),
          (locationMap['longitude'] as num).toDouble(),
        ),
        isOpen: openingHours?['openNow'] as bool? ?? true,
        rating: (map['rating'] as num?)?.toDouble(),
        userRatingCount: (map['userRatingCount'] as num?)?.toInt(),
        phoneNumber: map['nationalPhoneNumber'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
