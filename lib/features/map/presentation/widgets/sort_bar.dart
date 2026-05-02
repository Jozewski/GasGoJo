import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/gas_station.dart';

class SortBar extends StatelessWidget {
  const SortBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.stationCount = 0,
    this.filterActive = false,
    this.dark = false,
  });

  final SortMode selected;
  final ValueChanged<SortMode> onChanged;
  final int stationCount;
  final bool filterActive;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SortChip(
                    label: 'Cheapest',
                    icon: Icons.attach_money_rounded,
                    selected: selected == SortMode.cheapest,
                    onTap: () => onChanged(SortMode.cheapest),
                    dark: dark,
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: 'Nearest',
                    icon: Icons.near_me_rounded,
                    selected: selected == SortMode.nearest,
                    onTap: () => onChanged(SortMode.nearest),
                    dark: dark,
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: 'Brand',
                    icon: Icons.sort_by_alpha_rounded,
                    selected: selected == SortMode.brandAZ,
                    onTap: () => onChanged(SortMode.brandAZ),
                    dark: dark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: filterActive
                  ? AppColors.primaryContainer
                  : dark ? const Color(0xFF1E293B) : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: filterActive
                    ? AppColors.primary
                    : dark ? const Color(0xFF334155) : AppColors.border,
              ),
            ),
            child: Text(
              '$stationCount',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: filterActive
                        ? AppColors.primaryDark
                        : dark ? Colors.white : AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final unselectedBg = dark ? const Color(0xFF1E293B) : AppColors.white;
    final unselectedBorder = dark ? const Color(0xFF334155) : AppColors.border;
    final unselectedText = dark ? Colors.white : AppColors.textPrimary;
    final unselectedIcon = dark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
    return Semantics(
      label: '$label sort, ${selected ? 'selected' : 'not selected'}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : unselectedBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.primary : unselectedBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : unselectedIcon,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : unselectedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
