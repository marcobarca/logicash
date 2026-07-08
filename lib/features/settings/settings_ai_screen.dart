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
          final availableProviders = _resolveAvailableProviders(provider);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Chiave API Google ─────────────────────────────────
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ProviderAvatar(provider: kAiProviders[0]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chiave API Google',
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('Ottieni la chiave su Google AI Studio',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        _StatusBadge(active: provider.gemini.isConfigured),
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

              // ── Altri provider ────────────────────────────────────
              if (provider.customApiKeys.isNotEmpty) ...[
                const SizedBox(height: 8),
                LcCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Le chiavi API per OpenAI e Anthropic si configurano in Dati → Chiavi API esterne.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Configura almeno una chiave API per selezionare i modelli.',
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

  /// Restituisce i provider per cui l'utente ha una API key configurata.
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
          // ── Header collassato ─────────────────────────────────
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

            // ── Selezione provider ────────────────────────────────
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
                          border: Border.all(
                            color: sel ? AppColors.primary : AppColors.border,
                          ),
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

            // ── Lista modelli del provider selezionato ─────────────
            ..._selectedProvider.models.map((m) {
              final selected = widget.currentModelId == m.id;
              final tagColor = m.tag.contains('★') ? AppColors.positive
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
                                    style: const TextStyle(
                                        color: AppColors.textMuted, fontSize: 10)),
                                const Spacer(),
                                Text(
                                  '\$${m.inputPricePerM}/M in · \$${m.outputPricePerM}/M out',
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 9),
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

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.positive.withValues(alpha: 0.15)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'Attivo' : 'Non configurato',
        style: TextStyle(
          color: active ? AppColors.positive : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
