import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import '../../core/gemini/gemini_service.dart';
import '../../core/ai/ai_catalog.dart';
import 'ai_cost_widget.dart';

class SettingsAiScreen extends StatefulWidget {
  const SettingsAiScreen({super.key});
  @override
  State<SettingsAiScreen> createState() => _SettingsAiScreenState();
}

class _SettingsAiScreenState extends State<SettingsAiScreen> {
  AiProvider? _activeProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final available = _resolveAvailable(context.read<AppProvider>());
      if (available.length == 1) setState(() => _activeProvider = available.first);
    });
  }

  List<AiProvider> _resolveAvailable(AppProvider provider) {
    final result = <AiProvider>[];
    for (final p in kAiProviders) {
      if (p.id == 'google') {
        if (provider.gemini.isConfigured) result.add(p);
      } else {
        final hasKey = provider.customApiKeys.any(
          (k) => k.name.toLowerCase().contains(p.id) ||
                 k.name.toLowerCase().contains(p.name.toLowerCase()),
        );
        if (hasKey) result.add(p);
      }
    }
    return result;
  }

  Color _colorOf(AiProvider p) => switch (p.id) {
    'google'    => const Color(0xFF4285F4),
    'openai'    => const Color(0xFF10A37F),
    'anthropic' => const Color(0xFFD4A843),
    _           => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modelli AI')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final available = _resolveAvailable(provider);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Selezione provider ────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text('PROVIDER',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              ),

              if (available.isEmpty)
                LcCard(
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Configura le chiavi AI in Impostazioni → Chiavi AI.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: available.map((p) {
                    final active = _activeProvider?.id == p.id;
                    final color = _colorOf(p);
                    return GestureDetector(
                      onTap: () => setState(() =>
                          _activeProvider = active ? null : p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: active
                              ? color.withValues(alpha: 0.12)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active ? color : AppColors.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _ProviderCircle(provider: p, color: color, size: 44),
                            const SizedBox(height: 8),
                            Text(
                              p.name,
                              style: TextStyle(
                                color: active ? color : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 28),

              // ── Slot modelli ──────────────────────────────────────
              if (_activeProvider == null) ...[
                if (available.isNotEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Seleziona un provider per configurare i modelli.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ),
                  ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('MODELLI — ${_activeProvider!.name.toUpperCase()}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Assegna modelli diversi per ottimizzare qualità e costo.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                ...GeminiModelSlot.values.map((slot) => _SlotSelector(
                  key: ValueKey('${slot.name}_${_activeProvider!.id}'),
                  slot: slot,
                  currentModelId: provider.gemini.getModelId(slot),
                  activeProvider: _activeProvider!,
                  onChanged: (id) => provider.setGeminiModel(slot, id),
                )),
              ],

              const SizedBox(height: 20),
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

class _SlotSelector extends StatefulWidget {
  final GeminiModelSlot slot;
  final String currentModelId;
  final AiProvider activeProvider;
  final ValueChanged<String> onChanged;

  const _SlotSelector({
    super.key,
    required this.slot,
    required this.currentModelId,
    required this.activeProvider,
    required this.onChanged,
  });

  @override
  State<_SlotSelector> createState() => _SlotSelectorState();
}

class _SlotSelectorState extends State<_SlotSelector> {
  bool _expanded = false;

  // Il modello corrente se appartiene al provider attivo, altrimenti null.
  AiModelDef? get _activeModel {
    final provider = providerOfModel(widget.currentModelId);
    if (provider?.id == widget.activeProvider.id) {
      return modelById(widget.currentModelId);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final current = _activeModel;
    final color = _colorOf(widget.activeProvider);

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
          // ── Header ────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: current != null ? color : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.slot.label,
                            style: const TextStyle(color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(widget.slot.description,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 10)),
                        const SizedBox(height: 3),
                        Text(
                          current?.label ?? 'Nessun modello selezionato',
                          style: TextStyle(
                            color: current != null
                                ? color
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: current != null
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),

          // ── Lista modelli ─────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...widget.activeProvider.models.map((m) {
              final selected = widget.currentModelId == m.id;
              final tagColor = m.tag.contains('Consigliato')
                  ? AppColors.positive
                  : m.tag == 'Pro'
                      ? color
                      : m.tag == 'Economico'
                          ? AppColors.positive
                          : AppColors.textMuted;

              return InkWell(
                onTap: () {
                  widget.onChanged(m.id);
                  setState(() => _expanded = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  color: selected
                      ? color.withValues(alpha: 0.08)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(m.label,
                                  style: TextStyle(
                                      color: selected
                                          ? color
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tagColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(m.tag,
                                    style: TextStyle(
                                        color: tagColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              Text(m.description,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10)),
                              const Spacer(),
                              Text(
                                '\$${m.inputPricePerM}/M · \$${m.outputPricePerM}/M',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 9),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selected)
                        Icon(Icons.check, color: color, size: 16),
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

  Color _colorOf(AiProvider p) => switch (p.id) {
    'google'    => const Color(0xFF4285F4),
    'openai'    => const Color(0xFF10A37F),
    'anthropic' => const Color(0xFFD4A843),
    _           => AppColors.primary,
  };
}

// ── Provider circle ───────────────────────────────────────────

class _ProviderCircle extends StatelessWidget {
  final AiProvider provider;
  final Color color;
  final double size;
  const _ProviderCircle({required this.provider, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(provider.initial,
            style: TextStyle(
                color: color,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
