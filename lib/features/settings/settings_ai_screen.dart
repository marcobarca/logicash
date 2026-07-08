import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import '../../core/gemini/gemini_service.dart';
import 'ai_cost_widget.dart';

class SettingsAiScreen extends StatefulWidget {
  const SettingsAiScreen({super.key});
  @override
  State<SettingsAiScreen> createState() => _SettingsAiScreenState();
}

class _SettingsAiScreenState extends State<SettingsAiScreen> {
  final _apiKeyCtrl = TextEditingController();
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await context.read<AppProvider>().getGeminiApiKey();
    if (key != null && mounted) _apiKeyCtrl.text = key;
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente AI')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Chiave API ────────────────────────────────────
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chiave API Gemini',
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('Ottieni la chiave su Google AI Studio',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: provider.gemini.isConfigured
                                ? AppColors.positive.withValues(alpha: 0.15)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            provider.gemini.isConfigured ? 'Attivo' : 'Non configurato',
                            style: TextStyle(
                              color: provider.gemini.isConfigured ? AppColors.positive : AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _apiKeyCtrl,
                      obscureText: !_showKey,
                      decoration: InputDecoration(
                        hintText: 'AIza...',
                        labelText: 'Chiave API',
                        suffixIcon: IconButton(
                          icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textMuted, size: 18),
                          onPressed: () => setState(() => _showKey = !_showKey),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await provider.setGeminiApiKey(_apiKeyCtrl.text.trim());
                              if (!mounted) return;
                              ScaffoldMessenger.of(context) // ignore: use_build_context_synchronously
                                  .showSnackBar(const SnackBar(content: Text('Chiave API salvata')));
                            },
                            child: const Text('Salva'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.showSnackBar(const SnackBar(
                                content: Row(children: [
                                  SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                  SizedBox(width: 12),
                                  Text('Test in corso...'),
                                ]),
                                duration: Duration(seconds: 10),
                              ));
                              final error = await provider.gemini.testConnection();
                              if (!mounted) return;
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(SnackBar( // ignore: use_build_context_synchronously
                                content: Text(error == null ? '✓ Connessione OK' : '✗ $error'),
                                backgroundColor: error == null ? AppColors.positive : AppColors.negative,
                              ));
                            },
                            child: const Text('Testa', style: TextStyle(color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Modelli per funzione ───────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('MODELLI PER FUNZIONE',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Assegna modelli diversi per ottimizzare qualità e costo in base al tipo di elaborazione.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              ...GeminiModelSlot.values.map((slot) => _GeminiSlotSelector(
                slot: slot,
                currentModelId: provider.gemini.getModelId(slot),
                onChanged: (id) => provider.setGeminiModel(slot, id),
              )),
              const SizedBox(height: 20),

              // ── Costo AI ──────────────────────────────────────
              AiCostWidget(gemini: provider.gemini),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

// ── Selettore slot ────────────────────────────────────────────

class _GeminiSlotSelector extends StatefulWidget {
  final GeminiModelSlot slot;
  final String currentModelId;
  final ValueChanged<String> onChanged;

  const _GeminiSlotSelector({
    required this.slot,
    required this.currentModelId,
    required this.onChanged,
  });

  @override
  State<_GeminiSlotSelector> createState() => _GeminiSlotSelectorState();
}

class _GeminiSlotSelectorState extends State<_GeminiSlotSelector> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final current = kGeminiModels.firstWhere(
      (m) => m.id == widget.currentModelId,
      orElse: () => kGeminiModels.first,
    );
    final isDefault = widget.currentModelId == widget.slot.defaultModel;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(widget.slot.label,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                          if (isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.textMuted.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('default',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(widget.slot.description,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(current.label,
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...kGeminiModels.map((m) {
              final selected = widget.currentModelId == m.id;
              final isRecommended = m.tag.contains('★');
              final isPreview = m.tag == 'Anteprima';
              final tagColor = isRecommended ? AppColors.positive
                  : isPreview ? AppColors.warning
                  : AppColors.textMuted;
              return InkWell(
                onTap: () {
                  widget.onChanged(m.id);
                  setState(() => _expanded = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(m.label,
                                  style: TextStyle(
                                      color: selected ? AppColors.primary : AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tagColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(m.tag,
                                    style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.w700)),
                              ),
                            ]),
                            Text(m.description,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                          ],
                        ),
                      ),
                      if (selected) const Icon(Icons.check, color: AppColors.primary, size: 16),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
