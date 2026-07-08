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
                _StyledDropdown<AiProvider>(
                  value: _activeProvider,
                  hint: 'Seleziona provider',
                  activeColor: _activeProvider != null ? _colorOf(_activeProvider!) : null,
                  items: available,
                  labelOf: (p) => p.name,
                  leadingOf: (p) => _Avatar(provider: p, color: _colorOf(p), size: 26),
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
                final currentModel = _activeProvider != null
                    ? _activeProvider!.models.cast<AiModelDef?>().firstWhere(
                        (m) => m!.id == currentId, orElse: () => null)
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
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
                      _StyledDropdown<AiModelDef>(
                        value: currentModel,
                        hint: 'Seleziona modello',
                        enabled: _activeProvider != null,
                        activeColor: _activeProvider != null
                            ? _colorOf(_activeProvider!)
                            : null,
                        items: _activeProvider?.models ?? [],
                        labelOf: (m) => m.label,
                        trailingOf: (m) => Text(m.tag,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        onChanged: _activeProvider == null
                            ? null
                            : (m) {
                                if (m != null) provider.setGeminiModel(slot, m.id);
                              },
                      ),
                    ],
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

// ── Dropdown stilizzato ───────────────────────────────────────

class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final bool enabled;
  final Color? activeColor;
  final List<T> items;
  final String Function(T) labelOf;
  final Widget Function(T)? leadingOf;
  final Widget Function(T)? trailingOf;
  final ValueChanged<T?>? onChanged;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.enabled = true,
    this.activeColor,
    this.leadingOf,
    this.trailingOf,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.textMuted;
    final isActive = enabled && value != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
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
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            icon: Icon(Icons.expand_more,
                color: isActive ? color : AppColors.textMuted, size: 20),
            hint: Text(hint,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14)),
            onChanged: enabled ? onChanged : null,
            selectedItemBuilder: value == null
                ? null
                : (context) => items.map((item) {
                      return Row(children: [
                        if (leadingOf != null) ...[
                          leadingOf!(item),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(labelOf(item),
                              style: TextStyle(
                                  color: isActive ? color : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]);
                    }).toList(),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Row(children: [
                  if (leadingOf != null) ...[
                    leadingOf!(item),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(labelOf(item),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (trailingOf != null) trailingOf!(item),
                ]),
              );
            }).toList(),
          ),
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

class _Avatar extends StatelessWidget {
  final AiProvider provider;
  final Color color;
  final double size;
  const _Avatar({required this.provider, required this.color, required this.size});

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
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800)),
      ),
    );
  }
}
