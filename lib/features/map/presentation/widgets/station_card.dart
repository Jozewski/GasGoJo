import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/gas_station.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.station,
    required this.onTap,
    this.priceTier = PriceTier.neutral,
    this.isFavorite = false,
  });

  final GasStation station;
  final VoidCallback onTap;
  final PriceTier priceTier;
  final bool isFavorite;

  Color get _tierColor => switch (priceTier) {
        PriceTier.cheap => AppColors.priceCheap,
        PriceTier.mid => AppColors.priceMid,
        PriceTier.high => AppColors.priceHigh,
        PriceTier.neutral => AppColors.textDisabled,
      };

  @override
  Widget build(BuildContext context) {
    final price = station.regularPrice;
    final isQuikTrip =
      station.brand == StationBrand.other &&
      (station.name.toLowerCase().contains('quiktrip') ||
        station.name.toLowerCase().startsWith('qt '));
    return Semantics(
      label: '${station.name}, ${station.distanceLabel}, '
          '${price != null ? '\$${price.toStringAsFixed(2)} per gallon' : 'price unavailable'}, '
          '${station.isOpen ? 'Open' : 'Closed'}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: const [
                BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 10)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandIcon(
                  brand: station.brand,
                  stationName: station.name,
                  useQtLogo: isQuikTrip,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              station.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFavorite)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.favorite_rounded, size: 16, color: AppColors.error),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        station.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB8C5D6),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaPill(icon: Icons.near_me_rounded, label: station.distanceLabel),
                          _StatusPill(isOpen: station.isOpen),
                          if (station.rating != null)
                            _MetaPill(
                              icon: Icons.star_rounded,
                              label: station.rating!.toStringAsFixed(1),
                              iconColor: AppColors.warning,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 34,
                          child: FilledButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.system_update_alt_rounded, size: 16),
                            label: const Text('Update'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _PricePanel(price: price, tierColor: _tierColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({
    required this.brand,
    required this.stationName,
    this.useQtLogo = false,
  });
  final StationBrand brand;
  final String stationName;
  final bool useQtLogo;

  Color get _color => switch (brand) {
        StationBrand.shell => const Color(0xFFE8251B),
        StationBrand.exxon => const Color(0xFF003087),
        StationBrand.chevron => const Color(0xFF0067B1),
        StationBrand.bp => const Color(0xFF00A651),
        StationBrand.circleK => const Color(0xFFE30613),
        StationBrand.mobil => const Color(0xFFE21B3C),
        StationBrand.texaco => const Color(0xFFE41E3A),
        StationBrand.phillips66 => const Color(0xFFD4202A),
        StationBrand.sunoco => const Color(0xFF003DA5),
        _ => AppColors.textSecondary,
      };

  // Returns 'png' or 'svg' asset path, or null if no local asset exists
  String? get _assetPath => switch (brand) {
      _ when useQtLogo => 'assets/icons/brands/qt_mark.svg',
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
    final clean = stationName.trim();
    if (clean.isEmpty) {
      final brandLabel = brand.label;
      if (brandLabel.contains(' ')) {
        return brandLabel.split(' ').map((w) => w[0]).take(2).join();
      }
      return brandLabel.substring(0, brandLabel.length.clamp(0, 2));
    }
    final words = clean
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]);
    }
    return clean.substring(0, clean.length.clamp(0, 2));
  }

  @override
  Widget build(BuildContext context) {
    final path = _assetPath;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF475569)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: path != null
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: path.endsWith('.svg')
                  ? SvgPicture.asset(path, fit: BoxFit.contain)
                  : Image.asset(path, fit: BoxFit.contain),
            )
          : _InitialsFallback(initials: _initials, color: _color),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({required this.initials, required this.color});
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.04)],
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD6E1EF),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.accentContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'Open now' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isOpen ? AppColors.accentDark : AppColors.error,
        ),
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  const _PricePanel({required this.price, required this.tierColor});

  final double? price;
  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1DCE8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (price != null) ...[
            Text(
              '\$${price!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.priceCheap,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'per gal',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            const Text(
              'N/A',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDisabled,
              ),
            ),
        ],
      ),
    );
  }
}
