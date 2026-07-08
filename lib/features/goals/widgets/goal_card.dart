import 'package:flutter/material.dart';
import '../../../core/database/models/goal_model.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final double avgMonthlySavings;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const GoalCard({
    super.key,
    required this.goal,
    required this.avgMonthlySavings,
    required this.onDelete,
    required this.onEdit,
  });

  int get _monthsNeeded {
    if (avgMonthlySavings <= 0) return 999;
    return (goal.target / avgMonthlySavings).ceil();
  }

  DateTime get _arrivalDate => DateTime.now().add(Duration(days: (_monthsNeeded * 30.44).round()));

  String get _arrivalLabel {
    if (avgMonthlySavings <= 0) return 'Aumenta il risparmio';
    final d = _arrivalDate;
    final months = ['Gen','Feb','Mar','Apr','Mag','Giu','Lug','Ago','Set','Ott','Nov','Dic'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return LcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (goal.emoji != null)
                Text(goal.emoji!, style: const TextStyle(fontSize: 24)),
              if (goal.emoji != null) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: Theme.of(context).textTheme.titleMedium),
                    Text('Obiettivo: €${goal.target.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.surfaceElevated,
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifica', style: TextStyle(color: AppColors.textPrimary))),
                  const PopupMenuItem(value: 'delete', child: Text('Elimina', style: TextStyle(color: AppColors.negative))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stima arrivo', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(_arrivalLabel,
                        style: const TextStyle(color: AppColors.positive, fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Mesi necessari', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('$_monthsNeeded mesi',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.savings_outlined, color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text('€${avgMonthlySavings.toStringAsFixed(0)}/mese di media',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
