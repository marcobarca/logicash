import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_provider.dart';
import '../../core/database/models/fixed_expense_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  List<FixedExpenseModel>? _candidates;
  final Set<int> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    final all = await provider.detectCandidates();
    if (!mounted) return;
    setState(() {
      _candidates = all;
      _selected.addAll(List.generate(all.length, (i) => i)); // seleziona tutti di default
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidati rilevati'),
        actions: [
          if (_candidates != null && _candidates!.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                if (_selected.length == _candidates!.length) {
                  _selected.clear();
                } else {
                  _selected.addAll(List.generate(_candidates!.length, (i) => i));
                }
              }),
              child: Text(_selected.length == _candidates!.length ? 'Deseleziona tutti' : 'Seleziona tutti',
                  style: const TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _candidates != null && _candidates!.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ElevatedButton(
                  onPressed: _selected.isEmpty ? null : _confirm,
                  child: Text('Aggiungi ${_selected.length} spese fisse'),
                ),
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _candidates == null || _candidates!.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text('Nessun candidato trovato', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Importa più mesi di movimenti per permettere il rilevamento di pagamenti ricorrenti (stessa causale, importo stabile, cadenza regolare).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final candidates = _candidates!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trovati ${candidates.length} pagamenti ricorrenti. Seleziona quelli da aggiungere alle spese fisse.',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...candidates.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final checked = _selected.contains(i);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => checked ? _selected.remove(i) : _selected.add(i)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: LcCard(
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: checked ? AppColors.primary : Colors.transparent,
                          border: Border.all(color: checked ? AppColors.primary : AppColors.border, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: checked
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: TextStyle(
                                  color: checked ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600, fontSize: 14,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                _Chip(label: c.frequencyLabel),
                                if (c.category != null) ...[
                                  const SizedBox(width: 6),
                                  _Chip(label: c.category!),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('-€${c.amount.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.negative, fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('€${c.monthlyAmount.toStringAsFixed(0)}/mese',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms, delay: (i * 40).ms).slideX(begin: 0.04),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _confirm() async {
    final provider = context.read<AppProvider>();
    final toAdd = _selected.map((i) => _candidates![i]).toList();
    for (final fe in toAdd) {
      await provider.addFixedExpense(fe.copyWith(confirmedByUser: true));
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${toAdd.length} spese fisse aggiunte')),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
    );
  }
}
