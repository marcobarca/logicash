import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class QuickStatsWidget extends StatelessWidget {
  final double avgSavings;
  final int period;
  final int totalMonths;

  const QuickStatsWidget({
    super.key,
    required this.avgSavings,
    required this.period,
    required this.totalMonths,
  });

  @override
  Widget build(BuildContext context) {
    return LcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistiche ($period mesi)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickStat(
                  label: 'Risparmio medio',
                  value: '€${avgSavings.toStringAsFixed(0)}/mese',
                  color: avgSavings >= 0 ? AppColors.positive : AppColors.negative,
                  icon: Icons.savings_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStat(
                  label: 'Mesi analizzati',
                  value: '$totalMonths mesi',
                  color: AppColors.primary,
                  icon: Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _QuickStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
