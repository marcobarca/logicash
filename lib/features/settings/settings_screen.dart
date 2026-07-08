import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/database/models/account_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import '../auth/pin_setup_screen.dart';
import '../../core/gemini/gemini_service.dart';
import '../../core/api_keys/api_key_model.dart';
import 'ai_cost_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _showApiKey = false;
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  Future<void> _loadValues() async {
    final provider = context.read<AppProvider>();
    final key = await provider.getGeminiApiKey();
    if (key != null) _apiKeyController.text = key;
    final pinOn = await provider.isPinEnabled;
    if (mounted) setState(() => _pinEnabled = pinOn);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _showApiKeyForm(BuildContext context, ApiKeyEntry? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ApiKeyForm(existing: existing),
    );
  }

  void _showAccountForm(BuildContext context, AppProvider provider, {AccountModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AccountForm(existing: existing, provider: provider),
    );
  }

  Future<void> _showPinSetup(AppProvider provider, {bool isChange = false}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PinSetupScreen(
        isChange: isChange,
        onConfirmed: (pin) async {
          await provider.setPin(pin);
          if (mounted) setState(() => _pinEnabled = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isChange ? 'PIN cambiato' : 'PIN attivato')),
            );
          }
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Conti bancari ────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.account_balance_outlined, color: AppColors.positive, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('I TUOI CONTI',
                        style: TextStyle(color: AppColors.positive, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAccountForm(context, provider),
                    icon: const Icon(Icons.add, color: AppColors.positive, size: 16),
                    label: const Text('Aggiungi', style: TextStyle(color: AppColors.positive, fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (provider.accounts.isEmpty)
                LcCard(
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                      SizedBox(width: 12),
                      Expanded(child: Text('Aggiungi i tuoi conti per vedere il patrimonio totale',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                    ],
                  ),
                )
              else ...[
                ...provider.accounts.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LcCard(
                    child: Row(
                      children: [
                        Text(a.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('€${a.balance.toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppColors.positive, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 18),
                          onPressed: () => _showAccountForm(context, provider, existing: a),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.negative, size: 18),
                          onPressed: () => provider.deleteAccount(a.id!),
                        ),
                      ],
                    ),
                  ),
                )),
                LcCard(
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: AppColors.positive, size: 18),
                      const SizedBox(width: 12),
                      const Text('Totale patrimonio', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      const Spacer(),
                      Text('€${provider.totalBalance.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.positive, fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── Mese fiscale ─────────────────────────────────
              _SectionHeader(title: 'Mese fiscale', icon: Icons.calendar_today_outlined, color: AppColors.warning),
              const SizedBox(height: 10),
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giorno di inizio mese',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Se lo stipendio arriva il 27, imposta 27: i calcoli useranno il mese dal 27 al 26 del mese successivo',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    _DayPicker(
                      selectedDay: provider.fiscalMonthStartDay,
                      onChanged: (day) => provider.setFiscalMonthStartDay(day),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              provider.fiscalMonthStartDay == 1
                                  ? 'Mese solare (1° del mese)'
                                  : 'Mese fiscale: dal ${provider.fiscalMonthStartDay} di ogni mese',
                              style: const TextStyle(color: AppColors.warning, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Periodo riferimento ──────────────────────────
              _SectionHeader(title: 'Analisi', icon: Icons.bar_chart_outlined, color: AppColors.primary),
              const SizedBox(height: 10),
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Periodo di riferimento per le medie',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Usato per Health Score, anomalie e risparmio medio',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [3, 6, 12].map((m) {
                        final selected = provider.referencePeriod == m;
                        return GestureDetector(
                          onTap: () => provider.setReferencePeriod(m),
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Text('$m', style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                                Text('mesi', style: TextStyle(color: selected ? Colors.white70 : AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Sicurezza PIN ────────────────────────────────
              _SectionHeader(title: 'Sicurezza', icon: Icons.shield_outlined, color: AppColors.warning),
              const SizedBox(height: 10),
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
                              Text('PIN di accesso', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('Richiesto ad ogni apertura dell\'app', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _pinEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) async {
                            if (val) {
                              await _showPinSetup(provider);
                            } else {
                              await provider.disablePin();
                              setState(() => _pinEnabled = false);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PIN disattivato')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    if (_pinEnabled) ...[
                      const Divider(height: 20),
                      TextButton.icon(
                        onPressed: () => _showPinSetup(provider, isChange: true),
                        icon: const Icon(Icons.lock_reset, color: AppColors.primary, size: 18),
                        label: const Text('Cambia PIN', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Gemini API ───────────────────────────────────
              _SectionHeader(title: 'Assistente AI', icon: Icons.auto_awesome_outlined, color: AppColors.primary),
              const SizedBox(height: 10),
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
                              Text('Chiave API Gemini', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('Ottieni la chiave su Google AI Studio', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: provider.gemini.isConfigured ? AppColors.positive.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            provider.gemini.isConfigured ? 'Attivo' : 'Non configurato',
                            style: TextStyle(
                              color: provider.gemini.isConfigured ? AppColors.positive : AppColors.textMuted,
                              fontSize: 11, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: !_showApiKey,
                      decoration: InputDecoration(
                        hintText: 'AIza...',
                        labelText: 'Chiave API',
                        suffixIcon: IconButton(
                          icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 18),
                          onPressed: () => setState(() => _showApiKey = !_showApiKey),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 24),
                    const Text('Modelli per funzione',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text(
                      'Assegna modelli diversi in base al tipo di elaborazione per ottimizzare qualità e costo.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    ...GeminiModelSlot.values.map((slot) => _GeminiSlotSelector(
                      slot: slot,
                      currentModelId: provider.gemini.getModelId(slot),
                      onChanged: (id) => provider.setGeminiModel(slot, id),
                    )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await provider.setGeminiApiKey(_apiKeyController.text.trim());
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
                                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
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

              // ── Costo AI ─────────────────────────────────────
              AiCostWidget(gemini: provider.gemini),
              const SizedBox(height: 20),

              // ── Altre chiavi API ─────────────────────────────
              _SectionHeader(title: 'Altre chiavi API', icon: Icons.key_outlined, color: AppColors.textMuted),
              const SizedBox(height: 8),
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.customApiKeys.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Nessuna chiave aggiunta. Puoi memorizzare chiavi per OpenAI, Anthropic, o qualsiasi altro servizio.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      )
                    else
                      ...provider.customApiKeys.asMap().entries.map((e) {
                        final entry = e.value;
                        return Column(
                          children: [
                            if (e.key > 0) const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Text(entry.emoji, style: const TextStyle(fontSize: 22)),
                              title: Text(entry.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                              subtitle: entry.description != null && entry.description!.isNotEmpty
                                  ? Text(entry.description!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))
                                  : const Text('••••••••••••••••', style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 2)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                                    onPressed: () => _showApiKeyForm(context, entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.negative, size: 18),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: AppColors.surface,
                                          title: const Text('Elimina chiave', style: TextStyle(color: AppColors.textPrimary)),
                                          content: Text('Eliminare la chiave "${entry.name}"?', style: const TextStyle(color: AppColors.textSecondary)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina', style: TextStyle(color: AppColors.negative))),
                                          ],
                                        ),
                                      );
                                      // ignore: use_build_context_synchronously
                                      if (confirm == true) await context.read<AppProvider>().deleteCustomApiKey(entry.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Aggiungi chiave API'),
                        onPressed: () => _showApiKeyForm(context, null),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Profili import ───────────────────────────────
              _SectionHeader(title: 'Profili di importazione', icon: Icons.upload_file_outlined, color: AppColors.textMuted),
              const SizedBox(height: 8),
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.importProfiles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Nessun profilo salvato. Importa un file per crearne uno.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      )
                    else
                      ...provider.importProfiles.asMap().entries.map((e) {
                        final p = e.value;
                        return Column(
                          children: [
                            if (e.key > 0) const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.account_balance, color: AppColors.primary, size: 20),
                              title: Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                              subtitle: Text('${p.fileType.toUpperCase()} · riga ${p.dataStartRow}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.negative, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      title: const Text('Elimina profilo', style: TextStyle(color: AppColors.textPrimary)),
                                      content: Text('Eliminare il profilo "${p.name}"?', style: const TextStyle(color: AppColors.textSecondary)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina', style: TextStyle(color: AppColors.negative))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && p.id != null) {
                                    // ignore: use_build_context_synchronously
                                    await context.read<AppProvider>().deleteImportProfile(p.id!);
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Info ─────────────────────────────────────────
              LcCard(
                child: Column(
                  children: [
                    _InfoRow(icon: Icons.info_outline, label: 'Versione', value: '1.0.0'),
                    const Divider(height: 20),
                    _InfoRow(icon: Icons.storage_outlined, label: 'Mesi importati', value: '${provider.availableMonths.length} mesi'),
                    const Divider(height: 20),
                    _InfoRow(icon: Icons.lock_outline, label: 'Database', value: 'SQLite locale'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Form chiave API ───────────────────────────────────────────

class _ApiKeyForm extends StatefulWidget {
  final ApiKeyEntry? existing;
  const _ApiKeyForm({this.existing});
  @override
  State<_ApiKeyForm> createState() => _ApiKeyFormState();
}

class _ApiKeyFormState extends State<_ApiKeyForm> {
  final _nameCtrl  = TextEditingController();
  final _keyCtrl   = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _emoji = '🔑';
  bool _obscureKey = true;

  static const _suggestedServices = [
    ('OpenAI',     '🤖'), ('Anthropic',  '🧠'), ('Groq',      '⚡'),
    ('Mistral',    '🌀'), ('Cohere',     '🔮'), ('Hugging Face', '🤗'),
    ('ElevenLabs', '🎙️'), ('Replicate',  '🖼️'), ('Custom',    '🔑'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _keyCtrl.text  = widget.existing!.key;
      _descCtrl.text = widget.existing!.description ?? '';
      _emoji = widget.existing!.emoji;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _keyCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final key  = _keyCtrl.text.trim();
    if (name.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e chiave sono obbligatori')));
      return;
    }
    final entry = ApiKeyEntry(
      id:          widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name:        name,
      key:         key,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      emoji:       _emoji,
    );
    await context.read<AppProvider>().saveCustomApiKey(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(widget.existing != null ? 'Modifica chiave API' : 'Nuova chiave API',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 16),

            // Servizi suggeriti
            const Text('Servizio', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _suggestedServices.map((s) {
                final selected = _nameCtrl.text == s.$1;
                return GestureDetector(
                  onTap: () => setState(() { _nameCtrl.text = s.$1; _emoji = s.$2; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(s.$2, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(s.$1, style: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Nome personalizzato
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome servizio', hintText: 'Es. OpenAI, My Custom API…'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            // Chiave
            TextField(
              controller: _keyCtrl,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: 'Chiave API',
                hintText: 'sk-…',
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted, size: 18),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Nota opzionale
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Nota (opzionale)', hintText: 'Es. Progetto lavoro, limite 20\$/mese…'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(widget.existing != null ? 'Salva modifiche' : 'Aggiungi chiave'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selettore slot Gemini ─────────────────────────────────────

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
          // Header row
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
                              child: const Text('default', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
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
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),

          // Model list (expanded)
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
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(m.label, style: TextStyle(
                                  color: selected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500, fontSize: 12)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tagColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(m.tag, style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.w700)),
                              ),
                            ]),
                            Text(m.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                          ],
                        ),
                      ),
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

// ─────────────────────────────────────────────────────────────

class _DayPicker extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onChanged;

  const _DayPicker({required this.selectedDay, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [1, 5, 10, 15, 20, 25, 26, 27, 28, 29, 30].map((day) {
        final selected = selectedDay == day;
        return GestureDetector(
          onTap: () => onChanged(day),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? AppColors.warning : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppColors.warning : AppColors.border),
            ),
            child: Center(
              child: Text(
                day == 1 ? '1°' : '$day',
                style: TextStyle(
                  color: selected ? Colors.black : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AccountForm extends StatefulWidget {
  final AccountModel? existing;
  final AppProvider provider;
  const _AccountForm({this.existing, required this.provider});

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _emoji = '🏦';

  static const _emojis = ['🏦', '💳', '💰', '🏧', '📱', '💵', '🪙', '🏛️'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _balanceController.text = widget.existing!.balance.toStringAsFixed(2);
      _emoji = widget.existing!.emoji;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEdit ? 'Modifica conto' : 'Nuovo conto',
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _emojis.map((e) => GestureDetector(
              onTap: () => setState(() => _emoji = e),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _emoji == e ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _emoji == e ? AppColors.primary : AppColors.border),
                ),
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome conto', hintText: 'Es. Intesa Sanpaolo, N26...'),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]'))],
            decoration: const InputDecoration(labelText: 'Saldo attuale (€)', hintText: '0.00',
                prefixIcon: Icon(Icons.euro, color: AppColors.textMuted, size: 18)),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: Text(isEdit ? 'Salva modifiche' : 'Aggiungi conto'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim().replaceAll(',', '.'));
    if (name.isEmpty || balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi')),
      );
      return;
    }
    final account = AccountModel(id: widget.existing?.id, name: name, balance: balance, emoji: _emoji);
    if (widget.existing != null) {
      widget.provider.updateAccount(account);
    } else {
      widget.provider.addAccount(account);
    }
    Navigator.pop(context);
  }
}
