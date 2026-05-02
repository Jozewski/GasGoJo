import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../widgets/bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _desktopBreakpoint = 1100.0;
  static const _mapStyle = '''[
      {"featureType":"poi","stylers":[{"visibility":"off"}]},
      {"featureType":"transit","stylers":[{"visibility":"off"}]},
      {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]}
    ]''';
  final _sheetController = DraggableScrollableController();
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  bool _mapReady = false;

  // Demo favorite IDs (in production these come from Firestore via a FavoritesCubit)
  final Set<String> _favoriteIds = {};

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
    zoom: AppConstants.defaultZoom,
  );

  @override
  void initState() {
    super.initState();
    context.read<MapBloc>().add(const MapStarted());
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopLayout = screenWidth >= _desktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.mapBackground,
      body: BlocListener<MapBloc, MapState>(
        listener: _handleStateChanges,
        child: BlocBuilder<MapBloc, MapState>(
          buildWhen: (prev, curr) =>
              curr is MapLoaded ||
              curr is MapLoading ||
              curr is MapEmpty ||
              curr is MapError ||
              curr is MapInitial ||
              curr is MapLocationLoading,
          builder: (context, state) {
            if (isDesktopLayout) {
              return Row(
                children: [
                  Expanded(
                    child: _MapPane(
                      map: _buildGoogleMap(context, state, isDesktopLayout: true),
                      searchBar: _SearchBar(
                        controller: _searchController,
                        onMenuTap: () => context.push('/favorites'),
                        onNotificationTap: () => context.push('/alerts'),
                      ),
                      locateButton: _LocateMeFab(onTap: _onLocateMeTapped),
                    ),
                  ),
                  SizedBox(
                    width: 460,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                        child: StationSidePanel(
                          state: state,
                          favoriteIds: _favoriteIds,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Mobile: map fixed at top third, station list as separate section below.
            // This prevents the map from intercepting list scroll gestures.
            final mapHeight = MediaQuery.of(context).size.height / 3;
            return Column(
              children: [
                SizedBox(
                  height: mapHeight,
                  child: Stack(
                    children: [
                      _buildGoogleMap(context, state, isDesktopLayout: false),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _SearchBar(
                            controller: _searchController,
                            onMenuTap: () => context.push('/favorites'),
                            onNotificationTap: () => context.push('/alerts'),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: _LocateMeFab(onTap: _onLocateMeTapped),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StationMobilePanel(
                    state: state,
                    favoriteIds: _favoriteIds,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGoogleMap(
    BuildContext context,
    MapState state, {
    required bool isDesktopLayout,
  }) {
    // google_maps_flutter only supports Android, iOS, and Web.
    // Show a placeholder on unsupported desktop platforms.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return Container(
        color: AppColors.mapBackground,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: AppColors.textDisabled),
              SizedBox(height: 12),
              Text(
                'Map not supported on Windows desktop.\nUse the web app for the full map experience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return GoogleMap(
      initialCameraPosition: _initialCameraPosition,
      onMapCreated: _onMapCreated,
      onCameraIdle: _onCameraIdle,
      onCameraMove: (_) {},
      markers: _buildMarkers(state),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      style: _mapStyle,
      padding: EdgeInsets.zero,
    );
  }

  // ── Map Callbacks ──────────────────────────────────────────────────────────

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() => _mapReady = true);
  }

  void _onCameraIdle() {
    _mapController?.getVisibleRegion().then((bounds) {
      if (!mounted) return;
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      context.read<MapBloc>().add(MapCameraIdle(center, AppConstants.defaultZoom));
    });
  }

  void _onLocateMeTapped() {
    context.read<MapBloc>().add(const MapStarted());
  }

  // ── State Listener ─────────────────────────────────────────────────────────

  void _handleStateChanges(BuildContext context, MapState state) {
    if (_mapReady && _mapController != null) {
      if (state is MapLoading && state.locationJustResolved) {
        // Pan immediately to the user's real location as soon as we get a fix
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(state.center, 13),
        );
      } else if (state is MapLoaded) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(state.center),
        );
      }
    }

    if (state is MapError && state.message.contains('permission')) {
      _showPermissionDialog(context);
    }
  }

  // ── Markers ────────────────────────────────────────────────────────────────

  Set<Marker> _buildMarkers(MapState state) {
    if (state is! MapLoaded) return {};

    final minPrice = state.minPrice;
    final maxPrice = state.maxPrice;

    return state.stations.map((station) {
      final price = station.regularPrice;
      final tier = _priceTier(price, minPrice, maxPrice);
      final color = switch (tier) {
        PriceTier.cheap => BitmapDescriptor.hueGreen,
        PriceTier.mid => BitmapDescriptor.hueYellow,
        PriceTier.high => BitmapDescriptor.hueRed,
        PriceTier.neutral => BitmapDescriptor.hueOrange,
      };

      return Marker(
        markerId: MarkerId(station.id),
        position: station.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(color),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: price != null ? '\$${price.toStringAsFixed(2)}/gal' : 'Price N/A',
          onTap: () => context.push('/station/${station.id}', extra: station),
        ),
        onTap: () {},
      );
    }).toSet();
  }

  PriceTier _priceTier(double? price, double? min, double? max) {
    if (price == null || min == null || max == null || max == min) return PriceTier.neutral;
    final range = max - min;
    if (price <= min + range * 0.33) return PriceTier.cheap;
    if (price <= min + range * 0.66) return PriceTier.mid;
    return PriceTier.high;
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Location Required'),
        content: const Text(
          'GasGojo needs location access to show stations near you. '
          'Enable it in Settings > Apps > GasGojo > Permissions.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // In production: openAppSettings() from app_settings package
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

}

class _MapPane extends StatelessWidget {
  const _MapPane({
    required this.map,
    required this.searchBar,
    required this.locateButton,
  });

  final Widget map;
  final Widget searchBar;
  final Widget locateButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                map,
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: searchBar,
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: locateButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  final TextEditingController controller;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              // Menu icon with primary color tint
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.menu_rounded, size: 22, color: AppColors.textSecondary),
                tooltip: 'Menu',
              ),

              // Divider
              Container(width: 1, height: 20, color: AppColors.border),
              const SizedBox(width: 10),

              // Search icon + field
              const Icon(Icons.search_rounded, size: 18, color: AppColors.textDisabled),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Search for a location…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(fontSize: 14, color: AppColors.textDisabled),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Notification bell with badge
              IconButton(
                onPressed: onNotificationTap,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.textSecondary),
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                tooltip: 'Price alerts',
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Locate Me FAB ──────────────────────────────────────────────────────────

class _LocateMeFab extends StatelessWidget {
  const _LocateMeFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Find my location',
      button: true,
      child: FloatingActionButton(
        onPressed: onTap,
        mini: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.my_location_rounded, size: 22),
      ),
    );
  }
}
