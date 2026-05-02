import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../shared/models/gas_station.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();
  @override
  List<Object?> get props => [];
}

class MapStarted extends MapEvent {
  const MapStarted();
}

class MapLocationChanged extends MapEvent {
  const MapLocationChanged(this.center);
  final LatLng center;
  @override
  List<Object?> get props => [center];
}

class MapCameraIdle extends MapEvent {
  const MapCameraIdle(this.center, this.zoom);
  final LatLng center;
  final double zoom;
  @override
  List<Object?> get props => [center, zoom];
}

class MapFiltersApplied extends MapEvent {
  const MapFiltersApplied(this.filter);
  final FuelFilter filter;
  @override
  List<Object?> get props => [filter];
}

class MapSortChanged extends MapEvent {
  const MapSortChanged(this.sort);
  final SortMode sort;
  @override
  List<Object?> get props => [sort];
}

class MapRefreshRequested extends MapEvent {
  const MapRefreshRequested();
}

class MapStationTapped extends MapEvent {
  const MapStationTapped(this.station);
  final GasStation station;
  @override
  List<Object?> get props => [station.id];
}

class MapSearchLocationSelected extends MapEvent {
  const MapSearchLocationSelected(this.location, this.label);
  final LatLng location;
  final String label;
  @override
  List<Object?> get props => [location];
}

class MapStationPriceUpdated extends MapEvent {
  const MapStationPriceUpdated(this.station);
  final GasStation station;
  @override
  List<Object?> get props => [station.id];
}
