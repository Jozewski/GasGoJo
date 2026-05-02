import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/gas_station.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<GasStation> _compareList = [];

  // In production, this comes from FavoritesCubit backed by Firestore
  final List<GasStation> _favorites = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Favorites'),
        leading: const BackButton(),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Edit'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'My Stations'),
            Tab(text: 'Compare'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyStationsTab(
            favorites: _favorites,
            onRemove: _removeFavorite,
            onAddToCompare: _addToCompare,
            compareList: _compareList,
          ),
          _CompareTab(stations: _compareList, onRemove: _removeFromCompare),
        ],
      ),
    );
  }

  void _removeFavorite(GasStation station) {
    setState(() => _favorites.remove(station));
  }

  void _addToCompare(GasStation station) {
    if (_compareList.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can compare up to 3 stations.')),
      );
      return;
    }
    if (!_compareList.contains(station)) {
      setState(() => _compareList.add(station));
      _tabController.animateTo(1);
    }
  }

  void _removeFromCompare(GasStation station) {
    setState(() => _compareList.remove(station));
  }
}

// ── My Stations Tab ────────────────────────────────────────────────────────

class _MyStationsTab extends StatelessWidget {
  const _MyStationsTab({
    required this.favorites,
    required this.onRemove,
    required this.onAddToCompare,
    required this.compareList,
  });

  final List<GasStation> favorites;
  final ValueChanged<GasStation> onRemove;
  final ValueChanged<GasStation> onAddToCompare;
  final List<GasStation> compareList;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No favorites yet',
        subtitle: 'Tap the heart icon on any station to save it here for quick access.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final station = favorites[index];
        final inCompare = compareList.contains(station);
        return Dismissible(
          key: Key(station.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) => onRemove(station),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => context.push('/station/${station.id}', extra: station),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _BrandAvatar(brand: station.brand),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(station.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(station.address, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              station.distanceLabel,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (station.regularPrice != null)
                          PriceBadge(price: station.regularPrice!, large: true),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: Icon(
                            inCompare ? Icons.compare_arrows_rounded : Icons.add_chart_outlined,
                            size: 20,
                            color: inCompare ? AppColors.primary : AppColors.textSecondary,
                          ),
                          tooltip: inCompare ? 'In compare list' : 'Add to compare',
                          onPressed: () => onAddToCompare(station),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Compare Tab ────────────────────────────────────────────────────────────

class _CompareTab extends StatelessWidget {
  const _CompareTab({required this.stations, required this.onRemove});

  final List<GasStation> stations;
  final ValueChanged<GasStation> onRemove;

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return const EmptyState(
        icon: Icons.compare_arrows_rounded,
        title: 'Nothing to compare',
        subtitle: 'Add up to 3 stations from your favorites to see prices side by side.',
        action: null,
      );
    }

    final grades = [FuelGrade.regular, FuelGrade.midGrade, FuelGrade.premium, FuelGrade.diesel];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Station header row
          Row(
            children: [
              const SizedBox(width: 80),
              ...stations.map((s) => Expanded(
                    child: Column(
                      children: [
                        _BrandAvatar(brand: s.brand),
                        const SizedBox(height: 4),
                        Text(
                          s.name,
                          style: Theme.of(context).textTheme.labelMedium,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                          onPressed: () => onRemove(s),
                          tooltip: 'Remove from compare',
                        ),
                      ],
                    ),
                  )),
            ],
          ),

          const Divider(height: 24),

          // Price rows per grade
          ...grades.map((grade) {
            final prices = stations.map((s) => s.prices[grade]).toList();
            final validPrices = prices.whereType<double>().toList();
            final minPrice = validPrices.isEmpty ? null : validPrices.reduce((a, b) => a < b ? a : b);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      grade.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  ...stations.asMap().entries.map((entry) {
                    final price = entry.value.prices[grade];
                    final isBest = price != null && price == minPrice;
                    return Expanded(
                      child: Center(
                        child: price != null
                            ? PriceBadge(
                                price: price,
                                tier: isBest ? PriceTier.cheap : PriceTier.neutral,
                                grade: grade,
                              )
                            : Text('—', style: Theme.of(context).textTheme.bodySmall),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          const Divider(height: 24),

          // Distance row
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text('Distance',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
              ),
              ...stations.map((s) => Expanded(
                    child: Center(
                      child: Text(s.distanceLabel,
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandAvatar extends StatelessWidget {
  const _BrandAvatar({required this.brand});
  final StationBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          brand.label.substring(0, 2).toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
