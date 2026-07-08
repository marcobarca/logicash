import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_provider.dart';
import '../../core/database/models/fixed_expense_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import 'widgets/fixed_expense_form.dart';
import 'candidates_screen.dart';
import '../../shared/widgets/lc_empty_state.dart';

class FixedExpensesScreen extends StatelessWidget {
  const FixedExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spese Fisse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.warning),
            tooltip: 'Analizza movimenti',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CandidatesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            tooltip: 'Aggiungi spesa fissa',
            onPressed: () => _showForm(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final all = provider.fixedExpenses;
          final confirmed = all.where((e) => e.confirmedByUser).toList();
          final pending = all.where((e) => !e.confirmedByUser).toList();
          final totalMonthly = confirmed.fold<double>(0, (s, e) => s + e.monthlyAmount);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Summary — visibile solo se ci sono spese
                    if (all.isNotEmpty) ...[
                      LcCard(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.negative.withValues(alpha: 0.10), AppColors.cardGradientEnd],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Impegno mensile fisso', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('€${totalMonthly.toStringAsFixed(2)}',
                                      style: const TextStyle(color: AppColors.negative, fontSize: 28, fontWeight: FontWeight.w800)),
                                  Text('€${(totalMonthly * 12).toStringAsFixed(0)} all\'anno',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${confirmed.length}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                                const Text('voci attive', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Da confermare (rilevate automaticamente)
                    if (pending.isNotEmpty) ...[
                      LcSectionTitle(title: 'Rilevate automaticamente (${pending.length})'),
                      const SizedBox(height: 4),
                      const Text(
                        'Pagamenti con importo costante e cadenza regolare — confermali o eliminali',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ...pending.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FixedExpenseTile(
                          item: e.value,
                          onConfirm: () => provider.confirmFixedExpense(e.value.id!, true),
                          onDelete: () => provider.deleteFixedExpense(e.value.id!),
                          onEdit: () => _showForm(context, existing: e.value),
                        ).animate().fadeIn(duration: 300.ms, delay: (e.key * 60).ms),
                      )),
                      const SizedBox(height: 20),
                    ],

                    // Confermate
                    if (confirmed.isNotEmpty) ...[
                      LcSectionTitle(title: 'Attive'),
                      const SizedBox(height: 12),
                      ...confirmed.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FixedExpenseTile(
                          item: e.value,
                          confirmed: true,
                          onDelete: () => provider.deleteFixedExpense(e.value.id!),
                          onEdit: () => _showForm(context, existing: e.value),
                        ).animate().fadeIn(duration: 300.ms, delay: (e.key * 60).ms),
                      )),
                    ],

                    if (all.isEmpty)
                      LcEmptyState(
                        emoji: '🔄',
                        title: 'Nessuna spesa fissa',
                        body: 'Aggiungi affitto, abbonamenti e bollette per calcolare il tuo impegno mensile fisso.',
                        actionLabel: 'Aggiungi spesa fissa',
                        onAction: () => _showForm(context),
                        secondaryLabel: 'Analizza i movimenti',
                        onSecondary: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CandidatesScreen()),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, {FixedExpenseModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => FixedExpenseForm(existing: existing),
    );
  }
}

class _FixedExpenseTile extends StatelessWidget {
  final FixedExpenseModel item;
  final bool confirmed;
  final VoidCallback? onConfirm;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _FixedExpenseTile({
    required this.item,
    this.confirmed = false,
    this.onConfirm,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = confirmed ? AppColors.negative : AppColors.warning;

    return LcCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: item.emoji != null
                  ? Text(item.emoji!, style: const TextStyle(fontSize: 20))
                  : Icon(item.isManual ? Icons.edit_note : Icons.repeat, color: color, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(4)),
                      child: Text(item.frequencyLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    ),
                    if (item.category != null) ...[
                      const SizedBox(width: 6),
                      Flexible(child: Text(item.category!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('-€${item.amount.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.negative, fontWeight: FontWeight.w700, fontSize: 15)),
              Text('€${item.monthlyAmount.toStringAsFixed(0)}/mese',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            color: AppColors.surfaceElevated,
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
              if (v == 'confirm' && onConfirm != null) onConfirm!();
            },
            itemBuilder: (_) => [
              if (!confirmed && onConfirm != null)
                const PopupMenuItem(value: 'confirm', child: Text('Conferma', style: TextStyle(color: AppColors.positive))),
              const PopupMenuItem(value: 'edit', child: Text('Modifica', style: TextStyle(color: AppColors.textPrimary))),
              const PopupMenuItem(value: 'delete', child: Text('Elimina', style: TextStyle(color: AppColors.negative))),
            ],
          ),
        ],
      ),
    );
  }
}
