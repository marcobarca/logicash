import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/database/db_helper.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MonthlySummary> summaries;
  const MonthlyBarChart({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox();

    final recent = summaries.length > 6 ? summaries.sublist(summaries.length - 6) : summaries;
    final maxY = recent.map((s) => s.income > s.expenses ? s.income : s.expenses).reduce((a, b) => a > b ? a : b);

    return LcCard(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.15,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final s = recent[group.x];
                      final label = rodIndex == 0 ? 'Entrate' : 'Uscite';
                      final amount = rodIndex == 0 ? s.income : s.expenses;
                      return BarTooltipItem('$label\n€${amount.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= recent.length) return const SizedBox();
                        final month = recent[i].yearMonth.substring(5);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(month, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: recent.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: s.income, color: AppColors.positive, width: 8, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: s.expenses, color: AppColors.negative, width: 8, borderRadius: BorderRadius.circular(4)),
                    ],
                    barsSpace: 4,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: AppColors.positive, label: 'Entrate'),
              const SizedBox(width: 24),
              _Legend(color: AppColors.negative, label: 'Uscite'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
