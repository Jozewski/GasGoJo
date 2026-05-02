import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/models/gas_station.dart';
import '../features/map/presentation/screens/map_screen.dart';
import '../features/station_detail/presentation/screens/station_detail_screen.dart';
import '../features/filters/presentation/screens/filter_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/price_alerts/presentation/screens/price_alert_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    // ── Map (Home) ──────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      name: 'map',
      builder: (context, state) => const MapScreen(),
    ),

    // ── Station Detail ──────────────────────────────────────────────────
    GoRoute(
      path: '/station/:id',
      name: 'stationDetail',
      builder: (context, state) {
        final station = state.extra as GasStation?;
        if (station != null) {
          return StationDetailScreen(station: station);
        }
        // If no station in extras (deep link), show loading + fetch
        final id = state.pathParameters['id']!;
        return _StationDetailLoader(stationId: id);
      },
    ),

    // ── Filters ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/filters',
      name: 'filters',
      pageBuilder: (context, state) {
        final filter = state.extra as FuelFilter?;
        return ModalBottomSheetPage(
          key: state.pageKey,
          builder: (context) => FilterScreen(initialFilter: filter),
          isScrollControlled: true,
          useSafeArea: true,
        );
      },
    ),

    // ── Favorites ────────────────────────────────────────────────────────
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),

    // ── Price Alerts ─────────────────────────────────────────────────────
    GoRoute(
      path: '/alerts',
      name: 'alerts',
      builder: (context, state) => const PriceAlertScreen(),
    ),

    GoRoute(
      path: '/alerts/create',
      name: 'createAlert',
      builder: (context, state) {
        final station = state.extra as GasStation?;
        return PriceAlertScreen(station: station);
      },
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text('Page not found', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);

// ── Deep-Link Station Loader ───────────────────────────────────────────────

class _StationDetailLoader extends StatelessWidget {
  const _StationDetailLoader({required this.stationId});
  final String stationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: const Center(child: CircularProgressIndicator()),
    );
    // In production: FutureBuilder that fetches the station then shows StationDetailScreen
  }
}

// ── Modal Bottom Sheet Page ───────────────────────────────────────────────

class ModalBottomSheetPage<T> extends Page<T> {
  const ModalBottomSheetPage({
    required this.builder,
    super.key,
    this.isScrollControlled = false,
    this.useSafeArea = false,
  });

  final WidgetBuilder builder;
  final bool isScrollControlled;
  final bool useSafeArea;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      builder: builder,
    );
  }
}
