import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/gas_station.dart';
import '../../app/theme/app_colors.dart';

// ─── Price Badge ──────────────────────────────────────────────────────────

enum PriceTier { cheap, mid, high, neutral }

class PriceBadge extends StatelessWidget {
  const PriceBadge({
    super.key,
    required this.price,
    this.tier = PriceTier.neutral,
    this.grade,
    this.large = false,
  });

  final double price;
  final PriceTier tier;
  final FuelGrade? grade;
  final bool large;

  Color get _bgColor => switch (tier) {
        PriceTier.cheap => AppColors.accentContainer,
        PriceTier.mid => AppColors.warningContainer,
        PriceTier.high => AppColors.errorContainer,
        PriceTier.neutral => AppColors.primaryContainer,
      };

  Color get _textColor => switch (tier) {
        PriceTier.cheap => AppColors.accentDark,
        PriceTier.mid => const Color(0xFF854D0E),
        PriceTier.high => AppColors.error,
        PriceTier.neutral => AppColors.primaryDark,
      };

  @override
  Widget build(BuildContext context) {
    final priceStr = '\$${price.toStringAsFixed(2)}';
    return Semantics(
      label: '$priceStr per gallon${grade != null ? ' ${grade!.label}' : ''}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 10,
          vertical: large ? 8 : 4,
        ),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(large ? 10 : 6),
        ),
        child: Text(
          priceStr,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: large ? 22 : 14,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
      ),
    );
  }
}

// ─── Loading Overlay (Shimmer) ────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class StationCardShimmer extends StatelessWidget {
  const StationCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE7E5E4),
      highlightColor: const Color(0xFFF5F5F4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 120, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 60, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
          ],
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) =>
      ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, __) => const StationCardShimmer(),
      );
}

// ─── Error View ──────────────────────────────────────────────────────────

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.actionLabel,
    this.icon = Icons.local_gas_station_outlined,
  });

  final String title;
  final String subtitle;
  final VoidCallback? action;
  final String? actionLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (action != null && actionLabel != null) ...[
                const SizedBox(height: 24),
                OutlinedButton(onPressed: action, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Brand Logo ──────────────────────────────────────────────────────────

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 32, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_gas_station_rounded, size: size, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          'GasGojo',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.7,
            fontWeight: FontWeight.w700,
            color: onDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
