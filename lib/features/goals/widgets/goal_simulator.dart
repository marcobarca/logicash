import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class GoalSimulator extends StatefulWidget {
  final double avgMonthlySavings;
  const GoalSimulator({super.key, required this.avgMonthlySavings});

  @override
  State<GoalSimulator> createState() => _GoalSimulatorState();
}

class _GoalSimulatorState extends State<GoalSimulator> {
  double _target = 5000;
  double _extraMonthly = 0;

  double get _effectiveSavings => widget.avgMonthlySavings + _extraMonthly;
  double get _months => _effectiveSavings > 0 ? _target / _effectiveSavings : double.infinity;

  String get _estimateText {
    if (_effectiveSavings <= 0) return 'Aumenta il risparmio mensile';
    final m = _months.round();
    final date = DateTime.now().add(Duration(days: (m * 30.44).round()));
    final monthNames = ['Gen','Feb','Mar','Apr','Mag','Giu','Lug','Ago','Set','Ott','Nov','Dic'];
    return '${monthNames[date.month - 1]} ${date.year} (${m} mesi)';
  }

  @override
  Widget build(BuildContext context) {
    return LcCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.cardGradientEnd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Simulatore', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 20),

          // Target amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Obiettivo', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('€${_target.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceElevated,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _target,
              min: 500,
              max: 50000,
              divisions: 99,
              onChanged: (v) => setState(() => _target = v),
            ),
          ),

          const SizedBox(height: 12),

          // Extra monthly savings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Risparmio extra/mese', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(
                _extraMonthly > 0 ? '+€${_extraMonthly.toStringAsFixed(0)}' : '€0',
                style: TextStyle(
                  color: _extraMonthly > 0 ? AppColors.positive : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.positive,
              inactiveTrackColor: AppColors.surfaceElevated,
              thumbColor: AppColors.positive,
              overlayColor: AppColors.positive.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _extraMonthly,
              min: 0,
              max: 2000,
              divisions: 40,
              onChanged: (v) => setState(() => _extraMonthly = v),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: AppColors.positive, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Arrivi a', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(_estimateText, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Risparmio effettivo', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text('€${_effectiveSavings.toStringAsFixed(0)}/mese',
                        style: const TextStyle(color: AppColors.positive, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
