import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../map/data/repositories/station_repository.dart';
import '../../../../shared/models/gas_station.dart';

const Color _stationPageBg = Color(0xFF0F172A);
const Color _stationCardBg = Color(0xFF1E293B);
const Color _stationCardBorder = Color(0xFF334155);
const Color _stationTextPrimary = Color(0xFFF8FAFC);
const Color _stationTextSecondary = Color(0xFFCBD5E1);

class StationDetailScreen extends StatefulWidget {
  const StationDetailScreen({super.key, required this.station});
  final GasStation station;

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  bool _isFavorite = false;
  late GasStation _station;
  bool _priceWasUpdated = false;

  @override
  void initState() {
    super.initState();
    _station = widget.station;
  }

  void _popWithResult() {
    Navigator.pop(context, _priceWasUpdated ? _station : null);
  }

  @override
  Widget build(BuildContext context) {
    final station = _station;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popWithResult();
      },
      child: Scaffold(
        backgroundColor: _stationPageBg,
        body: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              backgroundColor: _stationPageBg,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: _stationTextPrimary),
                onPressed: _popWithResult,
              ),
              title: Text(
                station.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _stationTextPrimary),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(_isFavorite),
                      color: _isFavorite ? AppColors.error : _stationTextSecondary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _shareStation(station),
                  icon: const Icon(Icons.share_outlined, color: _stationTextSecondary),
                  tooltip: 'Share station',
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StationHeader(station: station),
                  const SizedBox(height: 14),

                  _StationDataInsights(station: station),
                  const SizedBox(height: 14),

                  _CommunityConfidenceCard(station: station),
                  const SizedBox(height: 14),

                  _PriceTable(
                    station: station,
                    onPriceReported: _handlePriceReported,
                  ),
                  const SizedBox(height: 14),

                  _RecentUpdateTimeline(station: station),
                  const SizedBox(height: 14),

                  _CommunityUpdateCta(
                    station: station,
                    onPriceReported: _handlePriceReported,
                  ),
                  const SizedBox(height: 14),

                  _OwnerDetailsCard(
                    station: station,
                    onPriceReported: _handlePriceReported,
                  ),
                  const SizedBox(height: 14),

                  _AmenitiesRow(amenities: station.amenities),
                  const SizedBox(height: 14),

                  _HoursTile(hours: station.hours),
                  const SizedBox(height: 14),

                  _ActionsRow(station: station),
                  const SizedBox(height: 14),

                  _PriceAlertCta(station: station),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite() => setState(() => _isFavorite = !_isFavorite);

  void _shareStation(GasStation station) {
    // In production: Share.share('Check out ${station.name} on GasGojo...')
  }

  void _handlePriceReported(_ReportedPrice report) {
    final updatedPrices = Map<FuelGrade, double>.from(_station.prices)
      ..[report.grade] = report.price;

    setState(() {
      _priceWasUpdated = true;
      _station = _station.copyWith(
        prices: updatedPrices,
        pricesUpdatedAt: DateTime.now(),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Price updated — showing your data now.'),
        backgroundColor: AppColors.accent,
      ),
    );
  }
}

class _ReportedPrice {
  const _ReportedPrice({required this.grade, required this.price});

  final FuelGrade grade;
  final double price;
}

// ── Station Header ─────────────────────────────────────────────────────────

class _StationHeader extends StatelessWidget {
  const _StationHeader({required this.station});
  final GasStation station;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StationBrandLogo(brand: station.brand, stationName: station.name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _stationTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(station.fullAddress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _stationTextSecondary),
                    maxLines: 2),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: station.isOpen ? AppColors.accentContainer : AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        station.isOpen ? 'Open Now' : 'Closed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: station.isOpen ? AppColors.accentDark : AppColors.error,
                        ),
                      ),
                    ),
                    if (station.rating != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(
                        '${station.rating!.toStringAsFixed(1)} (${station.reviewCount ?? 0})',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: _stationTextSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationBrandLogo extends StatelessWidget {
  const _StationBrandLogo({
    required this.brand,
    required this.stationName,
  });

  final StationBrand brand;
  final String stationName;

  String? get _assetPath => switch (brand) {
        StationBrand.shell => 'assets/icons/brands/shell.png',
        StationBrand.exxon => 'assets/icons/brands/exxon.png',
        StationBrand.chevron => 'assets/icons/brands/chevron.png',
        StationBrand.bp => 'assets/icons/brands/bp.png',
        StationBrand.circleK => 'assets/icons/brands/circlek.png',
        StationBrand.mobil => 'assets/icons/brands/mobil.png',
        StationBrand.texaco => 'assets/icons/brands/texaco.svg',
        StationBrand.phillips66 => 'assets/icons/brands/phillips66.png',
        StationBrand.sunoco => 'assets/icons/brands/sunoco.png',
        _ => null,
      };

  String get _initials {
    final words = stationName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    final seed = words.isNotEmpty ? words.first : brand.label;
    return seed.substring(0, seed.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final path = _assetPath;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      clipBehavior: Clip.antiAlias,
      child: path != null
          ? Padding(
              padding: const EdgeInsets.all(7),
              child: path.endsWith('.svg')
                  ? SvgPicture.asset(path, fit: BoxFit.contain)
                  : Image.asset(path, fit: BoxFit.contain),
            )
          : Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _stationTextPrimary,
                ),
              ),
            ),
    );
  }
}

class _CommunityConfidenceCard extends StatelessWidget {
  const _CommunityConfidenceCard({required this.station});

  final GasStation station;

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(station.pricesUpdatedAt);
    final hasManyPrices = station.prices.length >= 2;
    final confidence = switch ((age.inHours, hasManyPrices)) {
      (<6, true) => 'High confidence',
      (<24, _) => 'Moderate confidence',
      _ => 'Low confidence',
    };
    final color = switch (confidence) {
      'High confidence' => AppColors.priceCheap,
      'Moderate confidence' => AppColors.warning,
      _ => AppColors.error,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shield_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Confidence',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _stationTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '$confidence • ${station.freshnessLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _stationTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentUpdateTimeline extends StatelessWidget {
  const _RecentUpdateTimeline({required this.station});

  final GasStation station;

  @override
  Widget build(BuildContext context) {
    final entries = station.prices.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Price Activity',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _stationTextPrimary),
          ),
          const SizedBox(height: 10),
          ...entries.take(4).map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.timeline_rounded, size: 16, color: _stationTextSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key.label} updated to \$${entry.value.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _stationTextPrimary),
                      ),
                    ),
                    Text(
                      station.freshnessLabel.replaceFirst('Updated ', ''),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _stationTextSecondary),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _OwnerDetailsCard extends StatelessWidget {
  const _OwnerDetailsCard({required this.station, required this.onPriceReported});

  final GasStation station;
  final ValueChanged<_ReportedPrice> onPriceReported;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _stationTextPrimary),
          ),
          const SizedBox(height: 10),
          _OwnerDetailRow(icon: Icons.location_on_outlined, text: station.fullAddress),
          if (station.phoneNumber != null)
            _OwnerDetailRow(icon: Icons.phone_outlined, text: station.phoneNumber!),
          if (station.website != null)
            _OwnerDetailRow(icon: Icons.language_rounded, text: station.website!),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => _UpdateEntrySheet(
                  station: station,
                  initialRole: _UpdateRole.owner,
                  onPriceReported: onPriceReported,
                ),
              );
            },
            icon: const Icon(Icons.badge_outlined, size: 18),
            label: const Text('Do you own this business?'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _stationTextPrimary,
              side: const BorderSide(color: _stationCardBorder),
              backgroundColor: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerDetailRow extends StatelessWidget {
  const _OwnerDetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _stationTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _stationTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price Table ─────────────────────────────────────────────────────────────

class _PriceTable extends StatelessWidget {
  const _PriceTable({required this.station, required this.onPriceReported});
  final GasStation station;
  final ValueChanged<_ReportedPrice> onPriceReported;

  @override
  Widget build(BuildContext context) {
    final grades = [FuelGrade.regular, FuelGrade.midGrade, FuelGrade.premium, FuelGrade.diesel];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price per Gallon',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _stationTextPrimary),
              ),
              Text(
                station.freshnessLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _stationTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 2-column grid of fuel grades
          Row(
            children: grades
                .map((grade) {
                  final price = station.prices[grade];
                  return Expanded(
                    child: _PriceCell(grade: grade, price: price),
                  );
                })
                .toList(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _openUpdateEntrySheet(context),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Update this station'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }

  void _openUpdateEntrySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UpdateEntrySheet(
        station: station,
        onPriceReported: onPriceReported,
      ),
    );
  }
}

// ── Community Update CTA ──────────────────────────────────────────────────

class _CommunityUpdateCta extends StatelessWidget {
  const _CommunityUpdateCta({required this.station, required this.onPriceReported});
  final GasStation station;
  final ValueChanged<_ReportedPrice> onPriceReported;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'Help keep prices accurate',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _stationTextPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Submit current pump prices or station details to improve local price accuracy for everyone nearby.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _stationTextSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => _UpdateEntrySheet(
                        station: station,
                        initialRole: _UpdateRole.customer,
                        onPriceReported: onPriceReported,
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_gas_station_rounded, size: 18),
                  label: const Text('Customer Update'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => _UpdateEntrySheet(
                        station: station,
                        initialRole: _UpdateRole.owner,
                        onPriceReported: onPriceReported,
                      ),
                    );
                  },
                  icon: const Icon(Icons.storefront_rounded, size: 18),
                  label: const Text('Business Owner'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    side: const BorderSide(color: _stationCardBorder),
                    foregroundColor: _stationTextPrimary,
                    backgroundColor: const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _stationPageBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _stationCardBorder),
            ),
            child: Text(
              'Updates are reviewed with validation checks and rate limits before they influence pricing views.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _stationTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationDataInsights extends StatelessWidget {
  const _StationDataInsights({required this.station});

  final GasStation station;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Station Data Snapshot',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _stationTextPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InsightPill(icon: Icons.update_rounded, label: station.freshnessLabel),
              _InsightPill(icon: Icons.pin_drop_outlined, label: station.distanceLabel),
              _InsightPill(
                icon: Icons.verified_outlined,
                label: station.rating != null ? 'Rated ${station.rating!.toStringAsFixed(1)}' : 'Newly indexed',
              ),
              const _InsightPill(icon: Icons.fact_check_outlined, label: 'Validated inputs'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _stationTextSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _stationTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCell extends StatelessWidget {
  const _PriceCell({required this.grade, this.price});
  final FuelGrade grade;
  final double? price;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${grade.label}: ${price != null ? '\$${price!.toStringAsFixed(2)} per gallon' : 'unavailable'}',
      child: Column(
        children: [
          Text(
            grade.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _stationTextSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          if (price != null)
            Text(
              '\$${price!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            )
          else
            const Text('—', style: TextStyle(fontSize: 20, color: AppColors.textDisabled)),
        ],
      ),
    );
  }
}

// ── Amenities ──────────────────────────────────────────────────────────────

class _AmenitiesRow extends StatelessWidget {
  const _AmenitiesRow({required this.amenities});
  final List<Amenity> amenities;

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _stationTextPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: amenities
                .map((a) => _AmenityChip(amenity: a))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.amenity});
  final Amenity amenity;

  static const _iconMap = {
    Amenity.carWash: Icons.local_car_wash_rounded,
    Amenity.atm: Icons.atm_rounded,
    Amenity.restroom: Icons.wc_rounded,
    Amenity.snacks: Icons.storefront_outlined,
    Amenity.airPump: Icons.tire_repair_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconMap[amenity] ?? Icons.check_circle_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            amenity.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: _stationTextPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Hours ──────────────────────────────────────────────────────────────────

class _HoursTile extends StatefulWidget {
  const _HoursTile({required this.hours});
  final OpeningHours hours;

  @override
  State<_HoursTile> createState() => _HoursTileState();
}

class _HoursTileState extends State<_HoursTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hours = widget.hours;
    if (hours.days.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _stationCardBorder),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.schedule_rounded, color: _stationTextSecondary),
        collapsedIconColor: _stationTextSecondary,
        iconColor: _stationTextSecondary,
        title: Text(
          'Hours',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _stationTextPrimary),
        ),
        trailing: Icon(
          _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          color: _stationTextSecondary,
        ),
        onExpansionChanged: (v) => setState(() => _expanded = v),
        children: hours.days.entries.map((entry) {
          final dayName = hours.dayLabel(entry.key);
          final isToday = DateTime.now().weekday - 1 == entry.key;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    dayName,
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: isToday ? AppColors.primary : _stationTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  entry.value.display,
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    color: isToday ? _stationTextPrimary : _stationTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Actions Row ────────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.station});
  final GasStation station;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _launchDirections(station),
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: Text('Directions  •  ${station.distanceLabel}'),
            ),
          ),
          if (station.phoneNumber != null) ...[
            const SizedBox(width: 10),
            IconButton.outlined(
              onPressed: () => _callStation(station.phoneNumber!),
              icon: const Icon(Icons.phone_outlined),
              tooltip: 'Call station',
              style: IconButton.styleFrom(
                side: const BorderSide(color: _stationCardBorder),
                minimumSize: const Size(52, 52),
                backgroundColor: const Color(0xFF334155),
                foregroundColor: _stationTextPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchDirections(GasStation station) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${station.location.latitude},${station.location.longitude}'
        '&travelmode=driving');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _callStation(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}

// ── Price Alert CTA ────────────────────────────────────────────────────────

class _PriceAlertCta extends StatelessWidget {
  const _PriceAlertCta({required this.station});
  final GasStation station;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _stationCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _stationCardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get price drop alerts',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _stationTextPrimary),
                ),
                Text(
                  'Be notified when this station\'s price hits your target.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _stationTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              // context.push('/alerts/create', extra: station)
            },
            child: const Text('Set Alert'),
          ),
        ],
      ),
    );
  }
}

// ── Report Price Dialog ────────────────────────────────────────────────────

class _ReportPriceDialog extends StatefulWidget {
  const _ReportPriceDialog({required this.station});
  final GasStation station;

  @override
  State<_ReportPriceDialog> createState() => _ReportPriceDialogState();
}

class _ReportPriceDialogState extends State<_ReportPriceDialog> {
  FuelGrade _selectedGrade = FuelGrade.regular;
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Price'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.station.name, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          SegmentedButton<FuelGrade>(
            segments: FuelGrade.values
                .map((g) => ButtonSegment(value: g, label: Text(g.label, style: const TextStyle(fontSize: 11))))
                .toList(),
            selected: {_selectedGrade},
            onSelectionChanged: (s) => setState(() => _selectedGrade = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price per gallon',
              prefixText: '\$ ',
              suffixText: '/gal',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submitReport,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    final raw = _priceController.text.trim();
    final parsed = double.tryParse(raw);

    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price greater than 0.')),
      );
      return;
    }

    // Dismiss immediately so the UI feels instant, then write in background
    final report = _ReportedPrice(grade: _selectedGrade, price: parsed);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, report);

    final repository = GetIt.instance<StationRepository>();
    final result = await repository.reportPrice(
      stationId: widget.station.id,
      grade: _selectedGrade,
      price: parsed,
      userId: 'anonymous',
    );

    result.fold(
      (failure) {
        messenger.showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
        );
      },
      (_) {},
    );
  }
}

enum _UpdateRole {
  customer,
  owner,
}

class _UpdateEntrySheet extends StatefulWidget {
  const _UpdateEntrySheet({
    required this.station,
    required this.onPriceReported,
    this.initialRole = _UpdateRole.customer,
  });

  final GasStation station;
  final ValueChanged<_ReportedPrice> onPriceReported;
  final _UpdateRole initialRole;

  @override
  State<_UpdateEntrySheet> createState() => _UpdateEntrySheetState();
}

class _UpdateEntrySheetState extends State<_UpdateEntrySheet> {
  late _UpdateRole _role;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _stationCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _stationCardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Update Station Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _stationTextPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              widget.station.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _stationTextSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              'Choose how you are contributing:',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: _stationTextPrimary),
            ),
            const SizedBox(height: 10),
            SegmentedButton<_UpdateRole>(
              segments: const [
                ButtonSegment<_UpdateRole>(
                  value: _UpdateRole.customer,
                  icon: Icon(Icons.local_gas_station_rounded, size: 16),
                  label: Text('Are you a customer?'),
                ),
                ButtonSegment<_UpdateRole>(
                  value: _UpdateRole.owner,
                  icon: Icon(Icons.store_rounded, size: 16),
                  label: Text('Do you own this business?'),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (value) => setState(() => _role = value.first),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _stationPageBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _stationCardBorder),
              ),
              child: Text(
                _role == _UpdateRole.customer
                    ? 'Share current pump prices you observed on-site. Your report helps keep nearby pricing fresh.'
                    : 'Request business-owner update access to maintain station details like contact info, amenities, and hours.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _stationTextSecondary),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                if (_role == _UpdateRole.customer) {
                  final report = await showDialog<_ReportedPrice>(
                    context: context,
                    builder: (_) => _ReportPriceDialog(station: widget.station),
                  );

                  if (!context.mounted) return;

                  if (report != null) {
                    widget.onPriceReported(report);
                    navigator.pop();
                  }
                  return;
                }

                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Business owner onboarding is coming soon.'),
                  ),
                );
              },
              icon: Icon(_role == _UpdateRole.customer ? Icons.price_change_rounded : Icons.verified_user_rounded),
              label: Text(_role == _UpdateRole.customer ? 'Continue as Customer' : 'Continue as Business Owner'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            ),
          ],
        ),
      ),
    );
  }
}
