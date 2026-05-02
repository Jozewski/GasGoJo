import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/gas_station.dart';
import '../cubit/filter_cubit.dart';

class FilterScreen extends StatelessWidget {
  const FilterScreen({super.key, this.initialFilter});
  final FuelFilter? initialFilter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FilterCubit(initialFilter),
      child: const _FilterContent(),
    );
  }
}

class _FilterContent extends StatelessWidget {
  const _FilterContent();

  static const _distanceOptions = [1.0, 5.0, 10.0, 20.0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
        ),
        title: const Text('Filters'),
        actions: [
          TextButton(
            onPressed: () => context.read<FilterCubit>().reset(),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: BlocBuilder<FilterCubit, FilterState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tune your search', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Narrow the map to the stations worth stopping for.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _FilterSection(
                  title: 'Fuel Grade',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FuelGrade.values.map((grade) {
                      final selected = state.grade == grade;
                      return _FilterChip(
                        label: grade.label,
                        selected: selected,
                        onTap: () => context.read<FilterCubit>().setGrade(grade),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _FilterSection(
                  title: 'Max Distance',
                  trailing: Text(
                    state.maxDistanceMiles != null
                        ? '${state.maxDistanceMiles!.toStringAsFixed(0)} mi'
                        : 'Any distance',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primaryDark),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Any',
                        selected: state.maxDistanceMiles == null,
                        onTap: () => context.read<FilterCubit>().setMaxDistance(null),
                      ),
                      ..._distanceOptions.map((d) => _FilterChip(
                            label: '${d.toStringAsFixed(0)} mi',
                            selected: state.maxDistanceMiles == d,
                            onTap: () => context.read<FilterCubit>().setMaxDistance(d),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FilterSection(
                  title: 'Open Now',
                  subtitle: 'Show only stations currently operating.',
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.openNow ? 'Only open stations' : 'Include closed stations',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Switch(
                        value: state.openNow,
                        onChanged: (_) => context.read<FilterCubit>().toggleOpenNow(),
                        activeThumbColor: AppColors.white,
                        activeTrackColor: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FilterSection(
                  title: 'Brands',
                  subtitle: 'Keep your preferred chains front and center.',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: StationBrand.values.map((brand) {
                      final selected = state.brands.contains(brand);
                      return _FilterChip(
                        label: brand.label,
                        selected: selected,
                        onTap: () => context.read<FilterCubit>().toggleBrand(brand),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // ── Apply Button ──────────────────────────────────────────────────────
      bottomNavigationBar: BlocBuilder<FilterCubit, FilterState>(
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: () {
                  context.pop(state.toFuelFilter());
                },
                child: const Text('Apply Filters'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SectionHeader(label: title)),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, ${selected ? 'selected' : 'not selected'}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
