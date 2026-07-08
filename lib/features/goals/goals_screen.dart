import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_provider.dart';
import '../../core/database/models/goal_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import 'widgets/goal_card.dart';
import 'widgets/goal_form.dart';
import 'widgets/goal_simulator.dart';
import '../../shared/widgets/lc_empty_state.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obiettivi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'Nuovo obiettivo',
            onPressed: () => _showGoalForm(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final goals = provider.goals;
          final avgSavings = provider.avgMonthlySavings;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    GoalSimulator(avgMonthlySavings: avgSavings),
                    const SizedBox(height: 24),
                    LcSectionTitle(title: 'I tuoi obiettivi'),
                    const SizedBox(height: 12),
                    if (goals.isEmpty)
                      LcEmptyState(
                        emoji: '🎯',
                        title: 'Nessun obiettivo',
                        body: 'Crea il tuo primo obiettivo di risparmio e scopri in quanto tempo puoi raggiungerlo.',
                        actionLabel: 'Crea obiettivo',
                        onAction: () => _showGoalForm(context),
                      )
                    else
                      ...goals.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GoalCard(
                          goal: entry.value,
                          avgMonthlySavings: avgSavings,
                          onDelete: () => provider.deleteGoal(entry.value.id!),
                          onEdit: () => _showGoalForm(context, goal: entry.value),
                        ).animate().fadeIn(duration: 300.ms, delay: (entry.key * 80).ms),
                      )),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGoalForm(BuildContext context, {GoalModel? goal}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => GoalForm(existing: goal),
    );
  }
}

