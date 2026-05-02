import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/models/gas_station.dart';
import '../../data/repositories/station_repository.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc({required StationRepository stationRepository})
      : _repo = stationRepository,
        super(const MapInitial()) {
    on<MapStarted>(_onStarted);
    on<MapCameraIdle>(_onCameraIdle,
        transformer: (events, mapper) => events
            .debounceTime(const Duration(milliseconds: 600))
            .switchMap(mapper));
    on<MapFiltersApplied>(_onFiltersApplied);
    on<MapSortChanged>(_onSortChanged);
    on<MapRefreshRequested>(_onRefreshRequested);
    on<MapSearchLocationSelected>(_onSearchLocationSelected);
    on<MapStationPriceUpdated>(_onStationPriceUpdated);
  }

  final StationRepository _repo;
  LatLng _currentCenter = const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);
  FuelFilter _filter = FuelFilter.empty;
  SortMode _sort = SortMode.nearest;

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onStarted(MapStarted event, Emitter<MapState> emit) async {
    emit(const MapLocationLoading());

    final locationResult = await _determinePosition();

    await locationResult.fold(
      (failure) async {
        // Use default location on permission denial
        await _fetchStations(emit, _currentCenter);
      },
      (position) async {
        _currentCenter = LatLng(position.latitude, position.longitude);
        // Emit loading with locationJustResolved=true so the map screen
        // immediately pans the camera to the user's real location.
        emit(MapLoading(center: _currentCenter, filter: _filter, sort: _sort, locationJustResolved: true));
        await _fetchStations(emit, _currentCenter, skipLoadingEmit: true);
      },
    );
  }

  Future<void> _onCameraIdle(MapCameraIdle event, Emitter<MapState> emit) async {
    final moved = _hasCameraMoved(event.center);
    if (!moved) return;
    _currentCenter = event.center;
    await _fetchStations(emit, event.center);
  }

  Future<void> _onFiltersApplied(MapFiltersApplied event, Emitter<MapState> emit) async {
    _filter = event.filter;
    await _fetchStations(emit, _currentCenter);
  }

  void _onSortChanged(MapSortChanged event, Emitter<MapState> emit) {
    _sort = event.sort;
    final current = state;
    if (current is MapLoaded) {
      emit(current.copyWith(sort: event.sort));
    }
  }

  Future<void> _onRefreshRequested(MapRefreshRequested event, Emitter<MapState> emit) async {
    await _fetchStations(emit, _currentCenter);
  }

  Future<void> _onSearchLocationSelected(MapSearchLocationSelected event, Emitter<MapState> emit) async {
    _currentCenter = event.location;
    await _fetchStations(emit, event.location);
  }

  void _onStationPriceUpdated(MapStationPriceUpdated event, Emitter<MapState> emit) {
    final current = state;
    if (current is! MapLoaded) return;
    final updated = current.stations.map((s) {
      return s.id == event.station.id ? event.station : s;
    }).toList();
    emit(current.copyWith(stations: updated));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _fetchStations(Emitter<MapState> emit, LatLng center, {bool skipLoadingEmit = false}) async {
    if (!skipLoadingEmit) emit(MapLoading(center: center, filter: _filter, sort: _sort));

    final result = await _repo.getStationsNearby(
      center: center,
      radiusMeters: AppConstants.stationFetchRadiusMeters,
      filter: _filter,
    );

    result.fold(
      (failure) => emit(MapError(message: failure.message, center: center)),
      (stations) {
        if (stations.isEmpty) {
          emit(MapEmpty(center: center, filter: _filter));
        } else {
          emit(MapLoaded(
            stations: stations,
            center: center,
            filter: _filter,
            sort: _sort,
          ));
        }
      },
    );
  }

  bool _hasCameraMoved(LatLng newCenter) {
    const threshold = 0.002; // ~200 meters
    return (newCenter.latitude - _currentCenter.latitude).abs() > threshold ||
        (newCenter.longitude - _currentCenter.longitude).abs() > threshold;
  }

  Future<Either<Failure, Position>> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const Left(LocationFailure());
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const Left(LocationPermissionDeniedFailure());
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const Left(LocationPermissionDeniedFailure(
          'Location is permanently disabled. Enable it in your phone\'s Settings > Apps > GasGojo.'));
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return Right(position);
    } catch (_) {
      return const Left(LocationFailure());
    }
  }
}
