import 'package:flutter/material.dart';
import '../../../core/database/db_helper.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class AnomalyCard extends StatelessWidget {
  final List<CategorySummary> current;
  final Map<String, double> averages;

  const AnomalyCard({super.key, required this.current, required this.averages});

  List<_Anomaly> get _anomalies {
    final result = <_Anomaly>[];
    for (final cat in current) {
      final avg = averages[cat.category];
      if (avg == null || avg == 0) continue;
      final ratio = cat.total / avg;
      if (ratio > 1.3) {
        result.add(_Anomaly(category: cat.category, current: cat.total, avg: avg, ratio: ratio));
      }
    }
    result.sort((a, b) => b.ratio.compareTo(a.ratio));
    return result.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final anomalies = _anomalies;
    if (anomalies.isEmpty) {
      return LcCard(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.positive.withValues(alpha: 0.08), AppColors.cardGradientEnd],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.positive.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check_circle_outline, color: AppColors.positive, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nessuna anomalia', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  SizedBox(height: 2),
                  Text('Tutte le categorie sono nella norma', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return LcCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.warning.withValues(alpha: 0.08), AppColors.cardGradientEnd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Spese anomale', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          ...anomalies.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.category, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                      Text('Media: €${a.avg.toStringAsFixed(0)} → Questo mese: €${a.current.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('+${((a.ratio - 1) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _Anomaly {
  final String category;
  final double current;
  final double avg;
  final double ratio;
  const _Anomaly({required this.category, required this.current, required this.avg, required this.ratio});
}
