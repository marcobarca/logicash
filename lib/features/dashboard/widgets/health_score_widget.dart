import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class HealthScoreWidget extends StatelessWidget {
  final int score;
  const HealthScoreWidget({super.key, required this.score});

  Color get _scoreColor {
    if (score >= 75) return AppColors.positive;
    if (score >= 50) return AppColors.warning;
    return AppColors.negative;
  }

  String get _scoreLabel {
    if (score >= 80) return 'Ottimo';
    if (score >= 65) return 'Buono';
    if (score >= 50) return 'Nella media';
    if (score >= 35) return 'Da migliorare';
    return 'Attenzione';
  }

  String get _scoreEmoji {
    if (score >= 80) return '🚀';
    if (score >= 65) return '✅';
    if (score >= 50) return '📊';
    if (score >= 35) return '⚠️';
    return '🔴';
  }

  @override
  Widget build(BuildContext context) {
    return LcCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _scoreColor.withValues(alpha: 0.15),
          AppColors.cardGradientEnd,
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 48,
            lineWidth: 8,
            percent: score / 100,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    color: _scoreColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('/ 100', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
            progressColor: _scoreColor,
            backgroundColor: AppColors.surfaceElevated,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1200,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health Score', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_scoreEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      _scoreLabel,
                      style: TextStyle(color: _scoreColor, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getDescription(),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDescription() {
    if (score >= 80) return 'Stai gestendo le finanze in modo eccellente.';
    if (score >= 65) return 'Buona gestione, piccoli margini di miglioramento.';
    if (score >= 50) return 'Nella media. Controlla le spese anomale.';
    if (score >= 35) return 'Alcune categorie superano la tua media storica.';
    return 'Questo mese le uscite superano significativamente la norma.';
  }
}
