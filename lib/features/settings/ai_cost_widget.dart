import 'package:flutter/material.dart';
import '../../core/gemini/gemini_service.dart';
import '../../core/ai_usage/usage_tracker.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';

class AiCostWidget extends StatefulWidget {
  final GeminiService gemini;
  const AiCostWidget({super.key, required this.gemini});

  @override
  State<AiCostWidget> createState() => _AiCostWidgetState();
}

class _AiCostWidgetState extends State<AiCostWidget> {
  List<_ModelCostRow> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final allIds = kGeminiModels.map((m) => m.id).toList();
    final usages = await widget.gemini.tracker.getAllUsage(allIds);

    final rows = usages.map((u) {
      final model = kGeminiModels.firstWhere((m) => m.id == u.modelId,
          orElse: () => kGeminiModels.first);
      final cost = model.costFor(u.inputTokens, u.outputTokens);
      return _ModelCostRow(model: model, usage: u, cost: cost);
    }).toList();
    rows.sort((a, b) => b.cost.compareTo(a.cost));

    setState(() { _rows = rows; _loading = false; });
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Azzera contatori', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Questa operazione azzera i contatori di token e costo. Non è reversibile.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Azzera'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.gemini.tracker.resetAll(kGeminiModels.map((m) => m.id).toList());
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _rows.fold(0.0, (s, r) => s + r.cost);
    final totalTokens = _rows.fold(0, (s, r) => s + r.usage.totalTokens);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.attach_money, color: AppColors.warning, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('COSTO AI STIMATO',
                  style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ),
            if (_rows.isNotEmpty)
              TextButton(
                onPressed: _reset,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Azzera', style: TextStyle(color: AppColors.negative, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
        else if (_rows.isEmpty)
          LcCard(
            child: Row(children: const [
              Icon(Icons.info_outline, color: AppColors.textMuted, size: 16),
              SizedBox(width: 10),
              Expanded(child: Text('Nessun utilizzo registrato ancora', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            ]),
          )
        else ...[
          // Totale
          LcCard(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.warning.withValues(alpha: 0.08), AppColors.cardGradientEnd],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Costo totale stimato', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('\$${total.toStringAsFixed(4)}',
                          style: const TextStyle(color: AppColors.warning, fontSize: 24, fontWeight: FontWeight.w800)),
                      Text('≈ €${(total * 0.92).toStringAsFixed(4)}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatTokens(totalTokens),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                    const Text('token totali', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Breakdown per modello
          ..._rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: LcCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.model.label,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      Text('\$${r.cost.toStringAsFixed(4)}',
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _TokenBadge(label: '↑ ${_formatTokens(r.usage.inputTokens)}', color: AppColors.primary),
                      const SizedBox(width: 6),
                      _TokenBadge(label: '↓ ${_formatTokens(r.usage.outputTokens)}', color: AppColors.positive),
                      const Spacer(),
                      Text('${_formatTokens(r.usage.totalTokens)} tot',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Barra proporzionale
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? r.cost / total : 0,
                      backgroundColor: AppColors.surfaceElevated,
                      color: AppColors.warning,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 4),
          const Text(
            '* Stima basata su prezzi pay-as-you-go USD. Il cambio EUR è indicativo. Non include context caching.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ],
    );
  }

  String _formatTokens(int t) {
    if (t >= 1000000) return '${(t / 1000000).toStringAsFixed(2)}M';
    if (t >= 1000) return '${(t / 1000).toStringAsFixed(1)}K';
    return '$t';
  }
}

class _ModelCostRow {
  final GeminiModelOption model;
  final ModelUsage usage;
  final double cost;
  const _ModelCostRow({required this.model, required this.usage, required this.cost});
}

class _TokenBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TokenBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
