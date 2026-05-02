import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../shared/models/gas_station.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class FilterState extends Equatable {
  const FilterState({
    this.grade,
    this.maxDistanceMiles,
    this.openNow = false,
    this.brands = const {},
  });

  final FuelGrade? grade;
  final double? maxDistanceMiles;
  final bool openNow;
  final Set<StationBrand> brands;

  bool get hasChanges =>
      grade != null || maxDistanceMiles != null || openNow || brands.isNotEmpty;

  FuelFilter toFuelFilter() => FuelFilter(
        grade: grade,
        maxDistanceMiles: maxDistanceMiles,
        openNow: openNow,
        brands: brands,
      );

  FilterState copyWith({
    FuelGrade? grade,
    double? maxDistanceMiles,
    bool? openNow,
    Set<StationBrand>? brands,
    bool clearGrade = false,
    bool clearDistance = false,
  }) =>
      FilterState(
        grade: clearGrade ? null : grade ?? this.grade,
        maxDistanceMiles: clearDistance ? null : maxDistanceMiles ?? this.maxDistanceMiles,
        openNow: openNow ?? this.openNow,
        brands: brands ?? this.brands,
      );

  static const FilterState empty = FilterState();

  factory FilterState.fromFuelFilter(FuelFilter f) => FilterState(
        grade: f.grade,
        maxDistanceMiles: f.maxDistanceMiles,
        openNow: f.openNow,
        brands: f.brands,
      );

  @override
  List<Object?> get props => [grade, maxDistanceMiles, openNow, brands];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class FilterCubit extends Cubit<FilterState> {
  FilterCubit([FuelFilter? initialFilter])
      : super(initialFilter != null
            ? FilterState.fromFuelFilter(initialFilter)
            : FilterState.empty);

  void setGrade(FuelGrade? grade) {
    if (state.grade == grade) {
      emit(state.copyWith(clearGrade: true));
    } else {
      emit(state.copyWith(grade: grade));
    }
  }

  void setMaxDistance(double? miles) {
    if (miles == null) {
      emit(state.copyWith(clearDistance: true));
    } else {
      emit(state.copyWith(maxDistanceMiles: miles));
    }
  }

  void toggleOpenNow() => emit(state.copyWith(openNow: !state.openNow));

  void toggleBrand(StationBrand brand) {
    final updated = Set<StationBrand>.from(state.brands);
    if (updated.contains(brand)) {
      updated.remove(brand);
    } else {
      updated.add(brand);
    }
    emit(state.copyWith(brands: updated));
  }

  void reset() => emit(FilterState.empty);
}
