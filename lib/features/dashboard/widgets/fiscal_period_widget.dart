import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class FiscalPeriodWidget extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final int daysPassed;
  final int daysInPeriod;

  const FiscalPeriodWidget({
    super.key,
    required this.start,
    required this.end,
    required this.daysPassed,
    required this.daysInPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final progress = daysInPeriod > 0 ? (daysPassed / daysInPeriod).clamp(0.0, 1.0) : 0.0;
    final daysRemaining = (daysInPeriod - daysPassed).clamp(0, daysInPeriod);
    final dateFmt = DateFormat('d MMM', 'it');

    return LcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Periodo fiscale', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(
                daysRemaining == 0 ? 'Ultimo giorno' : '$daysRemaining giorni rimasti',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateFmt.format(start), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(dateFmt.format(end), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
