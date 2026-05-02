import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:equatable/equatable.dart';

// ─── Enums ────────────────────────────────────────────────────────────────

enum FuelGrade {
  regular('Regular'),
  midGrade('Mid-Grade'),
  premium('Premium'),
  diesel('Diesel');

  const FuelGrade(this.label);
  final String label;
}

enum Amenity {
  carWash('Car Wash', 'local_car_wash'),
  atm('ATM', 'atm'),
  restroom('Restroom', 'wc'),
  snacks('Snacks', 'local_convenience_store'),
  airPump('Air Pump', 'tire_repair');

  const Amenity(this.label, this.iconName);
  final String label;
  final String iconName;
}

enum SortMode { cheapest, nearest, brandAZ }

enum StationBrand {
  shell, exxon, chevron, circleK, bp, mobil, texaco, phillips66, sunoco, other;

  String get label => switch (this) {
        StationBrand.circleK => 'Circle K',
        StationBrand.phillips66 => 'Phillips 66',
        _ => name[0].toUpperCase() + name.substring(1),
      };
}

// ─── Opening Hours ─────────────────────────────────────────────────────────

class DayHours extends Equatable {
  const DayHours({required this.open, required this.close, this.is24Hours = false});

  final String open;   // e.g. "06:00 AM"
  final String close;  // e.g. "10:00 PM"
  final bool is24Hours;

  String get display => is24Hours ? '24 Hours' : '$open – $close';

  @override
  List<Object?> get props => [open, close, is24Hours];

  factory DayHours.fromJson(Map<String, dynamic> json) => DayHours(
        open: json['open'] as String,
        close: json['close'] as String,
        is24Hours: json['is24Hours'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'open': open, 'close': close, 'is24Hours': is24Hours};
}

class OpeningHours extends Equatable {
  const OpeningHours({required this.days});

  /// Key: weekday index 0 (Mon) – 6 (Sun)
  final Map<int, DayHours> days;

  static const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool get isOpenNow {
    final now = DateTime.now();
    final day = now.weekday - 1; // DateTime.monday == 1, we want 0-indexed
    final hours = days[day];
    if (hours == null) return false;
    if (hours.is24Hours) return true;
    // Simplified check — production would parse open/close times properly
    return true;
  }

  String dayLabel(int index) => _dayNames[index];

  @override
  List<Object?> get props => [days];

  factory OpeningHours.fromJson(Map<String, dynamic> json) => OpeningHours(
        days: json.map((k, v) => MapEntry(int.parse(k), DayHours.fromJson(v as Map<String, dynamic>))),
      );

  Map<String, dynamic> toJson() => days.map((k, v) => MapEntry(k.toString(), v.toJson()));
}

// ─── Gas Station ───────────────────────────────────────────────────────────

class GasStation extends Equatable {
  const GasStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.location,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.prices,
    required this.pricesUpdatedAt,
    required this.distanceMiles,
    required this.isOpen,
    required this.amenities,
    required this.hours,
    this.rating,
    this.reviewCount,
    this.placeId,
    this.phoneNumber,
    this.website,
  });

  final String id;
  final String name;
  final StationBrand brand;
  final LatLng location;
  final String address;
  final String city;
  final String state;
  final String zip;
  final Map<FuelGrade, double> prices;
  final DateTime pricesUpdatedAt;
  final double distanceMiles;
  final bool isOpen;
  final List<Amenity> amenities;
  final OpeningHours hours;
  final double? rating;
  final int? reviewCount;
  final String? placeId;
  final String? phoneNumber;
  final String? website;

  String get fullAddress => '$address, $city, $state $zip';
  double? get regularPrice => prices[FuelGrade.regular];
  double? get cheapestPrice {
    if (prices.isEmpty) return null;
    return prices.values.reduce((a, b) => a < b ? a : b);
  }

  String get freshnessLabel {
    final diff = DateTime.now().difference(pricesUpdatedAt);
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }

  String get distanceLabel =>
      distanceMiles < 0.1 ? 'Nearby' : '${distanceMiles.toStringAsFixed(1)} mi';

  GasStation copyWith({
    double? distanceMiles,
    Map<FuelGrade, double>? prices,
    DateTime? pricesUpdatedAt,
    bool? isOpen,
  }) =>
      GasStation(
        id: id,
        name: name,
        brand: brand,
        location: location,
        address: address,
        city: city,
        state: state,
        zip: zip,
        prices: prices ?? this.prices,
        pricesUpdatedAt: pricesUpdatedAt ?? this.pricesUpdatedAt,
        distanceMiles: distanceMiles ?? this.distanceMiles,
        isOpen: isOpen ?? this.isOpen,
        amenities: amenities,
        hours: hours,
        rating: rating,
        reviewCount: reviewCount,
        placeId: placeId,
        phoneNumber: phoneNumber,
        website: website,
      );

  @override
  List<Object?> get props => [id, prices, distanceMiles, isOpen];

  factory GasStation.fromFirestore(Map<String, dynamic> data, String docId) {
    final geo = data['geopoint'] as Map<String, dynamic>;
    final pricesRaw = data['prices'] as Map<String, dynamic>? ?? {};
    final prices = <FuelGrade, double>{};
    for (final entry in pricesRaw.entries) {
      final grade = FuelGrade.values.where((g) => g.name == entry.key).firstOrNull;
      if (grade != null) prices[grade] = (entry.value as num).toDouble();
    }

    final amenitiesRaw = (data['amenities'] as List<dynamic>? ?? []).cast<String>();
    final amenities = amenitiesRaw
        .map((a) => Amenity.values.where((e) => e.name == a).firstOrNull)
        .whereType<Amenity>()
        .toList();

    final brandStr = data['brand'] as String? ?? 'other';
    final brand = StationBrand.values.where((b) => b.name == brandStr).firstOrNull ?? StationBrand.other;

    return GasStation(
      id: docId,
      name: data['name'] as String,
      brand: brand,
      location: LatLng((geo['lat'] as num).toDouble(), (geo['lng'] as num).toDouble()),
      address: data['address'] as String,
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      zip: data['zip'] as String? ?? '',
      prices: prices,
      pricesUpdatedAt: DateTime.fromMillisecondsSinceEpoch(
          (data['pricesUpdatedAt'] as int? ?? 0)),
      distanceMiles: 0, // computed after fetch
      isOpen: data['isOpen'] as bool? ?? true,
      amenities: amenities,
      hours: data['hours'] != null
          ? OpeningHours.fromJson(data['hours'] as Map<String, dynamic>)
          : const OpeningHours(days: {}),
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'] as int?,
      placeId: data['placeId'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      website: data['website'] as String?,
    );
  }
}

// ─── Filter State Model ─────────────────────────────────────────────────────

class FuelFilter extends Equatable {
  const FuelFilter({
    this.grade,
    this.maxDistanceMiles,
    this.openNow = false,
    this.brands = const {},
  });

  final FuelGrade? grade;
  final double? maxDistanceMiles;
  final bool openNow;
  final Set<StationBrand> brands;

  bool get isActive =>
      grade != null || maxDistanceMiles != null || openNow || brands.isNotEmpty;

  FuelFilter copyWith({
    FuelGrade? grade,
    double? maxDistanceMiles,
    bool? openNow,
    Set<StationBrand>? brands,
    bool clearGrade = false,
    bool clearDistance = false,
  }) =>
      FuelFilter(
        grade: clearGrade ? null : grade ?? this.grade,
        maxDistanceMiles:
            clearDistance ? null : maxDistanceMiles ?? this.maxDistanceMiles,
        openNow: openNow ?? this.openNow,
        brands: brands ?? this.brands,
      );

  static const FuelFilter empty = FuelFilter();

  @override
  List<Object?> get props => [grade, maxDistanceMiles, openNow, brands];
}

// ─── Price Alert ────────────────────────────────────────────────────────────

class PriceAlert extends Equatable {
  const PriceAlert({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.grade,
    required this.targetPrice,
    required this.notifyEnabled,
    required this.createdAt,
  });

  final String id;
  final String stationId;
  final String stationName;
  final FuelGrade grade;
  final double targetPrice;
  final bool notifyEnabled;
  final DateTime createdAt;

  String get fcmTopic => 'station_${stationId}_${grade.name}';

  @override
  List<Object?> get props => [id, stationId, grade, targetPrice];

  Map<String, dynamic> toFirestore() => {
        'stationId': stationId,
        'stationName': stationName,
        'grade': grade.name,
        'targetPrice': targetPrice,
        'notifyEnabled': notifyEnabled,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory PriceAlert.fromFirestore(Map<String, dynamic> data, String docId) => PriceAlert(
        id: docId,
        stationId: data['stationId'] as String,
        stationName: data['stationName'] as String,
        grade: FuelGrade.values.byName(data['grade'] as String),
        targetPrice: (data['targetPrice'] as num).toDouble(),
        notifyEnabled: data['notifyEnabled'] as bool? ?? true,
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      );
}
