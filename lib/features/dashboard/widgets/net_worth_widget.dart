import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class NetWorthWidget extends StatelessWidget {
  final double totalBalance;
  final double avgMonthlySavings;

  const NetWorthWidget({
    super.key,
    required this.totalBalance,
    required this.avgMonthlySavings,
  });

  @override
  Widget build(BuildContext context) {
    final hasTrend = avgMonthlySavings != 0;

    return LcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patrimonio totale', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '€${totalBalance.toStringAsFixed(0)}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          if (hasTrend) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _Projection(months: 3, total: totalBalance, monthly: avgMonthlySavings)),
                const SizedBox(width: 8),
                Expanded(child: _Projection(months: 6, total: totalBalance, monthly: avgMonthlySavings)),
                const SizedBox(width: 8),
                Expanded(child: _Projection(months: 12, total: totalBalance, monthly: avgMonthlySavings)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Stima lineare basata sul risparmio medio mensile',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _Projection extends StatelessWidget {
  final int months;
  final double total;
  final double monthly;

  const _Projection({required this.months, required this.total, required this.monthly});

  @override
  Widget build(BuildContext context) {
    final projected = total + monthly * months;
    final color = monthly >= 0 ? AppColors.positive : AppColors.negative;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('$months mesi', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            '€${projected.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
