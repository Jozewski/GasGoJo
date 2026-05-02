import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/models/gas_station.dart';

class PriceAlertScreen extends StatefulWidget {
  const PriceAlertScreen({super.key, this.station});
  final GasStation? station;

  @override
  State<PriceAlertScreen> createState() => _PriceAlertScreenState();
}

class _PriceAlertScreenState extends State<PriceAlertScreen> {
  FuelGrade _selectedGrade = FuelGrade.regular;
  bool _notifyEnabled = true;
  double _targetPrice = 2.89;
  static const double _minPrice = 1.00;
  static const double _maxPrice = 6.00;

  String get _formattedTarget => '\$${_targetPrice.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    // Seed target price slightly below current price
    final currentPrice = widget.station?.prices[_selectedGrade];
    if (currentPrice != null) {
      _targetPrice = (currentPrice - 0.20).clamp(_minPrice, _maxPrice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Price Alert'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Create a price alert',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Set a target and we will watch the pump price for you.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Station ───────────────────────────────────────────────────
            const _FieldLabel(label: 'Station'),
            const SizedBox(height: 8),
            _StationSelector(station: station),

            const SizedBox(height: 20),

            // ── Fuel Grade ────────────────────────────────────────────────
            const _FieldLabel(label: 'Fuel Grade'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FuelGrade.values.map((grade) {
                  final selected = _selectedGrade == grade;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGrade = grade;
                          final p = station?.prices[grade];
                          if (p != null) {
                            _targetPrice = (p - 0.20).clamp(_minPrice, _maxPrice);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                            color: selected ? AppColors.secondary : AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: selected ? AppColors.secondary : AppColors.border,
                              width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_gas_station_rounded, size: 16,
                                color: selected ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              grade.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Target Price ──────────────────────────────────────────────
            const _FieldLabel(label: 'Target Price'),
            const SizedBox(height: 8),
            _TargetPriceCard(price: _formattedTarget),
            const SizedBox(height: 12),

            // Price slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                thumbColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                overlayColor: AppColors.primary.withValues(alpha: 0.1),
                trackHeight: 4,
              ),
              child: Slider(
                value: _targetPrice,
                min: _minPrice,
                max: _maxPrice,
                divisions: ((_maxPrice - _minPrice) * 100).round(),
                onChanged: (v) => setState(() => _targetPrice = v),
              ),
            ),

            // Slider labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('\$${_minPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelSmall),
                  Text('\$${((_minPrice + _maxPrice) / 2).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelSmall),
                  Text('\$${_maxPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notify Me', style: Theme.of(context).textTheme.titleSmall),
                        Text('Push notification', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notifyEnabled,
                    onChanged: (v) => setState(() => _notifyEnabled = v),
                    activeThumbColor: AppColors.white,
                    activeTrackColor: AppColors.secondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Confirmation note ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You\'ll receive a notification when ${station?.name ?? 'this station'}\'s '
                      '${_selectedGrade.label} price falls to $_formattedTarget/gal or lower.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _save,
            child: const Text('Save Alert'),
          ),
        ),
      ),
    );
  }

  void _save() {
    // In production: dispatch SaveAlertEvent via AlertCubit → writes to Firestore, subscribes FCM topic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert saved! We\'ll notify you when the price hits \$$_formattedTarget.'),
        backgroundColor: AppColors.accent,
      ),
    );
    Navigator.pop(context);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _StationSelector extends StatelessWidget {
  const _StationSelector({this.station});
  final GasStation? station;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_gas_station_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station?.name ?? 'Select a station',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (station != null)
                  Text(station!.address, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled, size: 20),
        ],
      ),
    );
  }
}

class _TargetPriceCard extends StatelessWidget {
  const _TargetPriceCard({required this.price});
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, Color(0xFF3B1F0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            price,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const Text(
            ' /gal',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
