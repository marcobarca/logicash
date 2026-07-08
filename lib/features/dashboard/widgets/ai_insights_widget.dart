import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/charts/chart_spec.dart';
import '../../../providers/app_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';
import '../../../shared/widgets/chart_widget.dart';

// ── Modello insight ───────────────────────────────────────────

class _Insight {
  final String type;  // "positive" | "warning" | "tip"
  final String emoji;
  final String title;
  final String body;
  final String detail;
  final ChartSpec? chart;
  const _Insight({required this.type, required this.emoji, required this.title, required this.body, required this.detail, this.chart});

  factory _Insight.fromMap(Map<String, dynamic> m) => _Insight(
    type:   m['type']   as String? ?? 'tip',
    emoji:  m['emoji']  as String? ?? '💡',
    title:  m['title']  as String? ?? '',
    body:   m['body']   as String? ?? '',
    detail: m['detail'] as String? ?? '',
    chart:  ChartSpec.fromMap(m['chart'] as Map<String, dynamic>?),
  );

  Color get color {
    switch (type) {
      case 'positive': return AppColors.positive;
      case 'warning':  return const Color(0xFFF59E0B);
      default:         return AppColors.primary;
    }
  }

  Color get bgColor => color.withValues(alpha: 0.08);
}

// ── Widget principale ─────────────────────────────────────────

class AiInsightsWidget extends StatefulWidget {
  const AiInsightsWidget({super.key});

  @override
  State<AiInsightsWidget> createState() => _AiInsightsWidgetState();
}

class _AiInsightsWidgetState extends State<AiInsightsWidget> {
  List<_Insight>? _insights;
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  Future<void> _loadInsights(AppProvider provider) async {
    if (_loading || _loaded) return;
    if (!provider.gemini.isConfigured) return;

    setState(() { _loading = true; _error = null; });
    try {
      final summary = await provider.getAiSummary();
      final raw = await provider.gemini.getMonthlyInsights(summary);
      if (raw.isEmpty) {
        setState(() { _error = 'Nessun dato disponibile.'; _loaded = true; });
        return;
      }
      final list = (jsonDecode(raw) as List)
          .map((e) => _Insight.fromMap(e as Map<String, dynamic>))
          .toList();
      setState(() { _insights = list; _loaded = true; });
    } catch (_) {
      setState(() { _error = 'Errore nel caricamento dei consigli.'; _loaded = true; });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _refresh(AppProvider provider) {
    setState(() { _loaded = false; _insights = null; _error = null; });
    _loadInsights(provider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Non configurato
        if (!provider.gemini.isConfigured) {
          return LcCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Consigli AI', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      const Text('Configura la chiave Gemini per ricevere analisi personalizzate.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                  child: const Text('Configura', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ),
              ],
            ),
          );
        }

        if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadInsights(provider));
        }

        return LcCard(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary.withValues(alpha: 0.10), AppColors.cardGradientEnd],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analisi di Logi', style: Theme.of(context).textTheme.titleMedium),
                      const Text('Aggiornata ai tuoi dati reali', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  if (!_loading)
                    GestureDetector(
                      onTap: () => _refresh(provider),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 16),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Contenuto
              if (_loading)
                _InsightSkeleton()
              else if (_error != null)
                _ErrorState(message: _error!, onRetry: () => _refresh(provider))
              else if (_insights != null && _insights!.isNotEmpty)
                Column(
                  children: _insights!.asMap().entries.map((e) =>
                    _InsightTile(insight: e.value, index: e.key),
                  ).toList(),
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Importa delle transazioni per ricevere consigli personalizzati.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Tile singolo insight ──────────────────────────────────────

class _InsightTile extends StatelessWidget {
  final _Insight insight;
  final int index;
  const _InsightTile({required this.insight, required this.index});

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _InsightDetailSheet(insight: insight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDetail = insight.detail.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: index < 2 ? 10 : 0),
      child: GestureDetector(
        onTap: hasDetail ? () => _showDetail(context) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: insight.bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: insight.color.withValues(alpha: 0.20)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: insight.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(insight.emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.title,
                        style: TextStyle(color: insight.color, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text(insight.body,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.45)),
                  ],
                ),
              ),
              if (hasDetail) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: insight.color.withValues(alpha: 0.6), size: 18),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (index * 120).ms).slideY(begin: 0.06);
  }
}

// ── Bottom sheet approfondimento ──────────────────────────────

class _InsightDetailSheet extends StatelessWidget {
  final _Insight insight;
  const _InsightDetailSheet({required this.insight});

  String get _typeLabel {
    switch (insight.type) {
      case 'positive': return 'Punto di forza';
      case 'warning':  return 'Attenzione';
      default:         return 'Consiglio';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: insight.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag tipo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: insight.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_typeLabel,
                      style: TextStyle(color: insight.color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 14),
                // Emoji + titolo
                Row(
                  children: [
                    Text(insight.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(insight.title,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, height: 1.2)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Summary
                Text(insight.body,
                    style: TextStyle(color: insight.color, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
                const SizedBox(height: 16),
                // Divisore
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                // Testo "Approfondimento"
                const Text('Approfondimento',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                // Detail
                Text(insight.detail,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.6)),

                // Grafico (se presente)
                if (insight.chart != null) ...[
                  const SizedBox(height: 20),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  ChartWidget(spec: insight.chart!, height: 180),
                ],

                const SizedBox(height: 20),
                // Pulsante "Chiedimi di più"
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: insight.color.withValues(alpha: 0.4)),
                      foregroundColor: insight.color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: const Text('Chiedimi di più in chat', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/chat', arguments: {
                        'autoSend': true,
                        'message': 'Approfondisci questo insight: "${insight.title}". ${insight.body} ${insight.detail}',
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────

class _InsightSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (i) => Padding(
        padding: EdgeInsets.only(bottom: i < 2 ? 10 : 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 100, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(height: 10, decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 4),
                    Container(height: 10, width: 160, decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 1200.ms, color: AppColors.primary.withValues(alpha: 0.06)),
      )),
    );
  }
}

// ── Stato errore ──────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.negative.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.negative.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.negative, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          TextButton(onPressed: onRetry, child: const Text('Riprova', style: TextStyle(color: AppColors.primary, fontSize: 12))),
        ],
      ),
    );
  }
}
