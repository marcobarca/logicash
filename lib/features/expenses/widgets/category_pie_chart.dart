import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/database/db_helper.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategorySummary> categories;
  const CategoryPieChart({super.key, required this.categories});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _touched;

  static const _colors = [
    AppColors.primary, AppColors.positive, AppColors.warning, AppColors.negative,
    Color(0xFF9B59B6), Color(0xFF3498DB), Color(0xFF1ABC9C), Color(0xFFE67E22),
    Color(0xFF95A5A6), Color(0xFFD35400),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return LcCard(child: Center(child: Text('Nessuna spesa', style: Theme.of(context).textTheme.bodyMedium)));
    }

    final total = widget.categories.fold<double>(0, (s, c) => s + c.total);
    final topCats = widget.categories.take(8).toList();

    return LcCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                pieTouchData: PieTouchData(
                  touchCallback: (e, r) => setState(() => _touched = r?.touchedSection?.touchedSectionIndex),
                ),
                sections: topCats.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  final pct = (cat.total / total * 100);
                  final isTouched = i == _touched;
                  return PieChartSectionData(
                    color: _colors[i % _colors.length],
                    value: cat.total,
                    title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                    radius: isTouched ? 70 : 60,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...topCats.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final pct = cat.total / total * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _colors[i % _colors.length], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(cat.category, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                  Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('€${cat.total.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.negative, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
