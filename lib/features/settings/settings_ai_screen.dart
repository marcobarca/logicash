import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import '../../core/gemini/gemini_service.dart';
import '../../core/ai/ai_catalog.dart';
import 'ai_cost_widget.dart';

class SettingsAiScreen extends StatelessWidget {
  const SettingsAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente AI')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final availableProviders = _resolveAvailableProviders(provider);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Info chiavi ───────────────────────────────────────
              if (!provider.gemini.isConfigured && provider.customApiKeys.isEmpty)
                LcCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nessuna chiave AI configurata',
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 2),
                            const Text('Configura una chiave in Impostazioni → Chiavi AI.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (provider.gemini.isConfigured || provider.customApiKeys.isNotEmpty)
                LcCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.positive, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _providersLabel(provider),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── Modelli per funzione ───────────────────────────────
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

              if (availableProviders.isEmpty)
                LcCard(
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Configura almeno una chiave AI per selezionare i modelli.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),
                )
              else
                ...GeminiModelSlot.values.map((slot) => _SlotSelector(
                  slot: slot,
                  currentModelId: provider.gemini.getModelId(slot),
                  availableProviders: availableProviders,
                  onChanged: (id) => provider.setGeminiModel(slot, id),
                )),

              const SizedBox(height: 20),
              AiCostWidget(gemini: provider.gemini),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  String _providersLabel(AppProvider provider) {
    final names = <String>[];
    if (provider.gemini.isConfigured) names.add('Google');
    for (final p in kAiProviders.where((p) => p.id != 'google')) {
      final hasKey = provider.customApiKeys.any(
        (k) => k.name.toLowerCase().contains(p.id) ||
               k.name.toLowerCase().contains(p.name.toLowerCase()),
      );
      if (hasKey) names.add(p.name);
    }
    return 'Chiavi attive: ${names.join(', ')}';
  }

  List<AiProvider> _resolveAvailableProviders(AppProvider provider) {
    final result = <AiProvider>[];
    if (provider.gemini.isConfigured) {
      result.add(kAiProviders.firstWhere((p) => p.id == 'google'));
    }
    for (final p in kAiProviders.where((p) => p.id != 'google')) {
      final hasKey = provider.customApiKeys.any(
        (k) => k.name.toLowerCase().contains(p.id) ||
               k.name.toLowerCase().contains(p.name.toLowerCase()),
      );
      if (hasKey) result.add(p);
    }
    return result;
  }
}

// ── Selettore slot ────────────────────────────────────────────

class _SlotSelector extends StatefulWidget {
  final GeminiModelSlot slot;
  final String currentModelId;
  final List<AiProvider> availableProviders;
  final ValueChanged<String> onChanged;

  const _SlotSelector({
    required this.slot,
    required this.currentModelId,
    required this.availableProviders,
    required this.onChanged,
  });

  @override
  State<_SlotSelector> createState() => _SlotSelectorState();
}

class _SlotSelectorState extends State<_SlotSelector> {
  bool _expanded = false;
  late AiProvider _selectedProvider;

  @override
  void initState() {
    super.initState();
    _selectedProvider = _inferProvider();
  }

  AiProvider _inferProvider() {
    final fromModel = providerOfModel(widget.currentModelId);
    if (fromModel != null &&
        widget.availableProviders.any((p) => p.id == fromModel.id)) {
      return fromModel;
    }
    return widget.availableProviders.first;
  }

  @override
  void didUpdateWidget(_SlotSelector old) {
    super.didUpdateWidget(old);
    if (old.currentModelId != widget.currentModelId ||
        old.availableProviders != widget.availableProviders) {
      _selectedProvider = _inferProvider();
    }
  }

  AiModelDef get _currentModel =>
      modelById(widget.currentModelId) ?? _selectedProvider.models.first;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _ProviderAvatar(provider: _selectedProvider, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(widget.slot.label,
                              style: const TextStyle(color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(width: 6),
                          Text('· ${_selectedProvider.name}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ]),
                        const SizedBox(height: 2),
                        Text(widget.slot.description,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        const SizedBox(height: 3),
                        Text(_currentModel.label,
                            style: const TextStyle(color: AppColors.primary,
                                fontSize: 12, fontWeight: FontWeight.w500)),
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

            if (widget.availableProviders.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: widget.availableProviders.map((p) {
                    final sel = p.id == _selectedProvider.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedProvider = p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ProviderAvatar(provider: p, size: 18, fontSize: 9),
                            const SizedBox(width: 5),
                            Text(p.name,
                                style: TextStyle(
                                  color: sel ? AppColors.primary : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const Divider(height: 1, color: AppColors.border),

            ..._selectedProvider.models.map((m) {
              final selected = widget.currentModelId == m.id;
              final tagColor = m.tag.contains('Consigliato') ? AppColors.positive
                  : m.tag == 'Pro' ? AppColors.primary
                  : m.tag == 'Economico' ? AppColors.positive
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
                                    style: TextStyle(color: tagColor,
                                        fontSize: 9, fontWeight: FontWeight.w700)),
                              ),
                            ]),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(m.description,
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                const Spacer(),
                                Text(
                                  '\$${m.inputPricePerM}/M in · \$${m.outputPricePerM}/M out',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selected)
                        const Icon(Icons.check, color: AppColors.primary, size: 16),
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

// ── Widget riutilizzabili ─────────────────────────────────────

class _ProviderAvatar extends StatelessWidget {
  final AiProvider provider;
  final double size;
  final double fontSize;
  const _ProviderAvatar({required this.provider, this.size = 36, this.fontSize = 14});

  Color get _color => switch (provider.id) {
    'google' => const Color(0xFF4285F4),
    'openai' => const Color(0xFF10A37F),
    'anthropic' => const Color(0xFFD4A843),
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(provider.initial,
            style: TextStyle(color: _color, fontSize: fontSize,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
