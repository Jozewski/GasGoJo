import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/gas_station.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import 'sort_bar.dart';
import 'station_card.dart';

class StationBottomSheet extends StatelessWidget {
  const StationBottomSheet({
    super.key,
    required this.controller,
    required this.state,
    required this.favoriteIds,
    this.initialChildSize = AppConstants.sheetInitialSize,
    this.minChildSize = AppConstants.sheetMinSize,
    this.maxChildSize = AppConstants.sheetMaxSize,
    this.snapSizes = const [
      AppConstants.sheetInitialSize,
      0.65,
      AppConstants.sheetMaxSize,
    ],
  });

  final DraggableScrollableController controller;
  final MapState state;
  final Set<String> favoriteIds;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final List<double> snapSizes;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: true,
      snapSizes: snapSizes,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 32,
                spreadRadius: 0,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              Semantics(
                label: 'Drag to resize station list',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nearby now',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Best stations around you',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state is MapLoaded
                                  ? '${(state as MapLoaded).stations.length} results sorted for quick decisions'
                                  : 'Live prices and station details near your current map area',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _FilterButton(
                        active: state is MapLoaded && (state as MapLoaded).filter.isActive,
                        onTap: () => _openFilters(context, state),
                      ),
                    ],
                  ),
                ),
              ),

              if (state is MapLoaded) ...[
                SortBar(
                  selected: (state as MapLoaded).sort,
                  stationCount: (state as MapLoaded).stations.length,
                  filterActive: (state as MapLoaded).filter.isActive,
                  onChanged: (sort) => context.read<MapBloc>().add(MapSortChanged(sort)),
                  dark: true,
                ),
              ],

              const Divider(height: 1, color: Color(0xFF1E293B)),

              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFF0F172A),
                  child: _SheetContent(
                    state: state,
                    scrollController: scrollController,
                    favoriteIds: favoriteIds,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFilters(BuildContext context, MapState state) async {
    final currentFilter = state is MapLoaded ? (state).filter : FuelFilter.empty;
    final result = await context.push<FuelFilter>('/filters', extra: currentFilter);
    if (result != null && context.mounted) {
      context.read<MapBloc>().add(MapFiltersApplied(result));
    }
  }
}

class StationSidePanel extends StatelessWidget {
  const StationSidePanel({
    super.key,
    required this.state,
    required this.favoriteIds,
  });

  final MapState state;
  final Set<String> favoriteIds;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 32,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stations near you',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state is MapLoaded
                              ? '${(state as MapLoaded).stations.length} stations ready to browse'
                              : 'Browse the list without the map taking over scroll',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _FilterButton(
                    active: state is MapLoaded && (state as MapLoaded).filter.isActive,
                    onTap: () => _openFilters(context, state),
                  ),
                ],
              ),
            ),
          ),
          if (state is MapLoaded)
            SortBar(
              selected: (state as MapLoaded).sort,
              stationCount: (state as MapLoaded).stations.length,
              filterActive: (state as MapLoaded).filter.isActive,
              onChanged: (sort) => context.read<MapBloc>().add(MapSortChanged(sort)),
              dark: true,
            ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          Expanded(
            child: ColoredBox(
              color: AppColors.secondary,
              child: _SheetContent(
                state: state,
                favoriteIds: favoriteIds,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFilters(BuildContext context, MapState state) async {
    final currentFilter = state is MapLoaded ? state.filter : FuelFilter.empty;
    final result = await context.push<FuelFilter>('/filters', extra: currentFilter);
    if (result != null && context.mounted) {
      context.read<MapBloc>().add(MapFiltersApplied(result));
    }
  }
}

// ── Mobile Panel ───────────────────────────────────────────────────────────
// Non-overlay panel used on small screens. The map sits above this in a Column
// so scroll gestures on the list never reach the map.

class StationMobilePanel extends StatelessWidget {
  const StationMobilePanel({
    super.key,
    required this.state,
    required this.favoriteIds,
  });

  final MapState state;
  final Set<String> favoriteIds;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 32,
            spreadRadius: 0,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag indicator (visual only — no longer draggable, just matches style)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearby now',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state is MapLoaded
                              ? '${(state as MapLoaded).stations.length} stations nearby'
                              : 'Best stations around you',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _FilterButton(
                    active: state is MapLoaded && (state as MapLoaded).filter.isActive,
                    onTap: () => _openFilters(context, state),
                  ),
                ],
              ),
            ),
          ),
          if (state is MapLoaded)
            SortBar(
              selected: (state as MapLoaded).sort,
              stationCount: (state as MapLoaded).stations.length,
              filterActive: (state as MapLoaded).filter.isActive,
              onChanged: (sort) => context.read<MapBloc>().add(MapSortChanged(sort)),
              dark: true,
            ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFF0F172A),
              child: _SheetContent(
                state: state,
                favoriteIds: favoriteIds,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFilters(BuildContext context, MapState state) async {
    final currentFilter = state is MapLoaded ? state.filter : FuelFilter.empty;
    final result = await context.push<FuelFilter>('/filters', extra: currentFilter);
    if (result != null && context.mounted) {
      context.read<MapBloc>().add(MapFiltersApplied(result));
    }
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filters${active ? ', active' : ''}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: active ? AppColors.primary : const Color(0xFF334155)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 16,
                color: active ? AppColors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Text(
                'Filters',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.white : const Color(0xFFCBD5E1),
                ),
              ),
              if (active) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.state,
    this.scrollController,
    required this.favoriteIds,
  });

  final MapState state;
  final ScrollController? scrollController;
  final Set<String> favoriteIds;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      MapInitial() || MapLocationLoading() => const LoadingOverlay(message: 'Finding your location...'),
      MapLoading() => const ShimmerList(),
      MapEmpty() => const EmptyState(
          icon: Icons.local_gas_station_outlined,
          title: 'No stations in this area',
          subtitle: 'Try zooming out or adjusting your filters to find more stations.',
        ),
      MapError(:final message) => ErrorView(
          message: message,
          icon: message.contains('location') || message.contains('Location')
              ? Icons.location_off_outlined
              : Icons.wifi_off_rounded,
          onRetry: () => context.read<MapBloc>().add(const MapRefreshRequested()),
        ),
      MapLoaded(:final sorted) => _StationList(
          stations: sorted,
          scrollController: scrollController,
          favoriteIds: favoriteIds,
          minPrice: (state as MapLoaded).minPrice,
          maxPrice: (state as MapLoaded).maxPrice,
        ),
    };
  }
}

class _StationList extends StatelessWidget {
  const _StationList({
    required this.stations,
    this.scrollController,
    required this.favoriteIds,
    this.minPrice,
    this.maxPrice,
  });

  final List<GasStation> stations;
  final ScrollController? scrollController;
  final Set<String> favoriteIds;
  final double? minPrice;
  final double? maxPrice;

  PriceTier _tier(GasStation station) {
    final p = station.regularPrice;
    if (p == null || minPrice == null || maxPrice == null) return PriceTier.neutral;
    if (maxPrice == minPrice) return PriceTier.neutral;
    final range = maxPrice! - minPrice!;
    if (p <= minPrice! + range * 0.33) return PriceTier.cheap;
    if (p <= minPrice! + range * 0.66) return PriceTier.mid;
    return PriceTier.high;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      itemCount: stations.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        if (index == stations.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('View all stations'),
            ),
          );
        }
        final station = stations[index];
        return StationCard(
          station: station,
          priceTier: _tier(station),
          isFavorite: favoriteIds.contains(station.id),
          onTap: () => context.push('/station/${station.id}', extra: station),
        );
      },
    );
  }
}
