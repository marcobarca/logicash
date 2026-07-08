import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
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

  /// Solo i provider con chiave configurata.
  List<AiProvider> _resolveAvailable(AppProvider provider) {
    final result = <AiProvider>[];
    for (final p in kAiProviders) {
      final hasKey = p.id == 'google'
          ? provider.gemini.isConfigured
          : provider.customApiKeys.any(
              (k) => k.name.toLowerCase().contains(p.id) ||
                     k.name.toLowerCase().contains(p.name.toLowerCase()),
            );
      if (hasKey) result.add(p);
    }
    return result;
  }

  static Color _colorOf(AiProvider p) => switch (p.id) {
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
              // ── Provider ──────────────────────────────────────────
              const _SectionLabel('PROVIDER'),
              const SizedBox(height: 8),

              if (available.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Nessuna chiave AI configurata. Vai in Impostazioni → Chiavi AI.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                )
              else
                _ProviderDropdown(
                  available: available,
                  selected: _activeProvider,
                  colorOf: _colorOf,
                  onChanged: (p) => setState(() => _activeProvider = p),
                ),

              const SizedBox(height: 24),

              // ── Modelli per slot ──────────────────────────────────
              const _SectionLabel('MODELLO PER FUNZIONE'),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 12),
                child: Text(
                  _activeProvider == null
                      ? 'Seleziona prima un provider.'
                      : 'Assegna un modello ${_activeProvider!.name} a ogni funzione.',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),


              ...GeminiModelSlot.values.map((slot) {
                final currentId = provider.gemini.getModelId(slot);
                final currentModel = _activeProvider?.models
                    .cast<AiModelDef?>()
                    .firstWhere((m) => m!.id == currentId, orElse: () => null);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Opacity(
                    opacity: _activeProvider != null ? 1.0 : 0.4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 2, bottom: 6),
                          child: Row(children: [
                            Text(slot.label,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(width: 6),
                            Text('· ${slot.description}',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ]),
                        ),
                        _ModelDropdown(
                          value: _activeProvider != null ? currentModel : null,
                          items: _activeProvider?.models ?? [],
                          accentColor: _activeProvider != null
                              ? _colorOf(_activeProvider!)
                              : AppColors.textMuted,
                          onChanged: _activeProvider == null
                              ? (_) {}
                              : (m) {
                                  if (m != null) provider.setGeminiModel(slot, m.id);
                                },
                        ),
                      ],
                    ),
                  ),
                );
              }),

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

// ── Provider dropdown (con stati abilitato/disabilitato) ──────

class _ProviderDropdown extends StatelessWidget {
  final List<AiProvider> available;
  final AiProvider? selected;
  final Color Function(AiProvider) colorOf;
  final ValueChanged<AiProvider?> onChanged;

  const _ProviderDropdown({
    required this.available,
    required this.selected,
    required this.colorOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected != null;
    final color = isActive ? colorOf(selected!) : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AiProvider>(
          value: selected,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: Icon(Icons.expand_more,
              color: isActive ? color : AppColors.textMuted, size: 20),
          hint: const Text('Seleziona provider',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          onChanged: onChanged,
          selectedItemBuilder: (context) => available.map((p) =>
              Text(p.name,
                  style: TextStyle(
                      color: colorOf(p),
                      fontWeight: FontWeight.w600,
                      fontSize: 14))).toList(),
          items: available.map((p) => DropdownMenuItem<AiProvider>(
            value: p,
            child: Text(p.name,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          )).toList(),
        ),
      ),
    );
  }
}

// ── Model dropdown ────────────────────────────────────────────

class _ModelDropdown extends StatelessWidget {
  final AiModelDef? value;
  final List<AiModelDef> items;
  final Color accentColor;
  final ValueChanged<AiModelDef?> onChanged;

  const _ModelDropdown({
    required this.value,
    required this.items,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? accentColor : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AiModelDef>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          icon: Icon(Icons.expand_more,
              color: isActive ? accentColor : AppColors.textMuted, size: 20),
          hint: const Text('Seleziona modello',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          onChanged: onChanged,
          selectedItemBuilder: value == null
              ? null
              : (context) => items.map((m) => Text(m.label,
                    style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis)).toList(),
          items: items.map((m) {
            final tagColor = m.tag.contains('Consigliato')
                ? AppColors.positive
                : m.tag == 'Pro'
                    ? accentColor
                    : m.tag == 'Economico'
                        ? AppColors.positive
                        : AppColors.textMuted;
            return DropdownMenuItem<AiModelDef>(
              value: m,
              child: Row(children: [
                Expanded(
                  child: Text(m.label,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(m.tag,
                      style: TextStyle(
                          color: tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1));
}

