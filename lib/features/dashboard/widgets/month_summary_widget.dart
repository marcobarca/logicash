import 'package:flutter/material.dart';
import '../../../core/database/db_helper.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class MonthSummaryWidget extends StatelessWidget {
  final MonthlySummary? summary;
  const MonthSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final income = summary?.income ?? 0;
    final expenses = summary?.expenses ?? 0;
    final savings = summary?.savings ?? 0;

    return LcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Questo mese', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatItem(label: 'Entrate', amount: income, color: AppColors.positive, icon: Icons.arrow_downward)),
              _Divider(),
              Expanded(child: _StatItem(label: 'Uscite', amount: expenses, color: AppColors.negative, icon: Icons.arrow_upward)),
              _Divider(),
              Expanded(child: _StatItem(label: 'Risparmiato', amount: savings, color: savings >= 0 ? AppColors.positive : AppColors.negative, icon: Icons.savings)),
            ],
          ),
          if (income > 0) ...[
            const SizedBox(height: 16),
            _SavingsBar(savings: savings, income: income),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 48, color: AppColors.border);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _StatItem({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text('€${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _SavingsBar extends StatelessWidget {
  final double savings;
  final double income;

  const _SavingsBar({required this.savings, required this.income});

  @override
  Widget build(BuildContext context) {
    final rate = (savings / income).clamp(0.0, 1.0);
    final pct = (rate * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tasso di risparmio', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text('$pct%', style: TextStyle(
              color: rate >= 0.2 ? AppColors.positive : rate >= 0.1 ? AppColors.warning : AppColors.negative,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: AlwaysStoppedAnimation(
              rate >= 0.2 ? AppColors.positive : rate >= 0.1 ? AppColors.warning : AppColors.negative,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
