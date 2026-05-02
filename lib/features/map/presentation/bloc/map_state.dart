import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/models/gas_station.dart';

sealed class MapState extends Equatable {
  const MapState();
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {
  const MapInitial();
}

class MapLocationLoading extends MapState {
  const MapLocationLoading();
}

class MapLoading extends MapState {
  const MapLoading({required this.center, required this.filter, required this.sort, this.locationJustResolved = false});
  final LatLng center;
  final FuelFilter filter;
  final SortMode sort;
  /// True when this loading state was triggered by a fresh location fix —
  /// the map screen should animate the camera to [center] immediately.
  final bool locationJustResolved;
  @override
  List<Object?> get props => [center, locationJustResolved];
}

class MapLoaded extends MapState {
  const MapLoaded({
    required this.stations,
    required this.center,
    required this.filter,
    required this.sort,
    this.selectedStation,
  });

  final List<GasStation> stations;
  final LatLng center;
  final FuelFilter filter;
  final SortMode sort;
  final GasStation? selectedStation;

  List<GasStation> get sorted => switch (sort) {
        SortMode.cheapest => [...stations]..sort((a, b) =>
            (a.regularPrice ?? 999).compareTo(b.regularPrice ?? 999)),
        SortMode.nearest => [...stations]..sort((a, b) =>
            a.distanceMiles.compareTo(b.distanceMiles)),
        SortMode.brandAZ => [...stations]..sort((a, b) =>
            a.brand.label.compareTo(b.brand.label)),
      };

  double? get minPrice {
    if (stations.isEmpty) return null;
    return stations
        .map((s) => s.regularPrice)
        .whereType<double>()
        .fold<double>(9999, (a, b) => a < b ? a : b);
  }

  double? get maxPrice {
    if (stations.isEmpty) return null;
    return stations
        .map((s) => s.regularPrice)
        .whereType<double>()
        .fold<double>(0, (a, b) => a > b ? a : b);
  }

  MapLoaded copyWith({
    List<GasStation>? stations,
    LatLng? center,
    FuelFilter? filter,
    SortMode? sort,
    GasStation? selectedStation,
    bool clearSelection = false,
  }) =>
      MapLoaded(
        stations: stations ?? this.stations,
        center: center ?? this.center,
        filter: filter ?? this.filter,
        sort: sort ?? this.sort,
        selectedStation: clearSelection ? null : selectedStation ?? this.selectedStation,
      );

  @override
  List<Object?> get props => [stations, center, filter, sort, selectedStation];
}

class MapEmpty extends MapState {
  const MapEmpty({required this.center, required this.filter});
  final LatLng center;
  final FuelFilter filter;
  @override
  List<Object?> get props => [center];
}

class MapError extends MapState {
  const MapError({required this.message, this.center});
  final String message;
  final LatLng? center;
  @override
  List<Object?> get props => [message];
}
