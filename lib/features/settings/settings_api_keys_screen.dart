import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/api_keys/api_key_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';

class SettingsApiKeysScreen extends StatefulWidget {
  const SettingsApiKeysScreen({super.key});
  @override
  State<SettingsApiKeysScreen> createState() => _SettingsApiKeysScreenState();
}

class _SettingsApiKeysScreenState extends State<SettingsApiKeysScreen> {
  final _googleKeyCtrl = TextEditingController();
  bool _showGoogleKey = false;

  @override
  void initState() {
    super.initState();
    _loadGoogleKey();
  }

  Future<void> _loadGoogleKey() async {
    final key = await context.read<AppProvider>().getGeminiApiKey();
    if (key != null && mounted) _googleKeyCtrl.text = key;
  }

  @override
  void dispose() {
    _googleKeyCtrl.dispose();
    super.dispose();
  }

  void _showForm(BuildContext context, ApiKeyEntry? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ApiKeyForm(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chiavi AI')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Google / Gemini ───────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('GOOGLE',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              ),
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ProviderDot(color: const Color(0xFF4285F4), label: 'G'),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gemini API Key',
                                  style: TextStyle(color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('google.ai.google.com/aistudio',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        _StatusDot(active: provider.gemini.isConfigured),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _googleKeyCtrl,
                      obscureText: !_showGoogleKey,
                      decoration: InputDecoration(
                        hintText: 'AIza...',
                        labelText: 'Chiave API',
                        suffixIcon: IconButton(
                          icon: Icon(_showGoogleKey ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textMuted, size: 18),
                          onPressed: () => setState(() => _showGoogleKey = !_showGoogleKey),
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
                              await provider.setGeminiApiKey(_googleKeyCtrl.text.trim());
                              if (!mounted) return;
                              ScaffoldMessenger.of(context) // ignore: use_build_context_synchronously
                                  .showSnackBar(const SnackBar(content: Text('Chiave salvata')));
                            },
                            child: const Text('Salva'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary)),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.showSnackBar(const SnackBar(
                                content: Row(children: [
                                  SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white)),
                                  SizedBox(width: 12),
                                  Text('Test in corso...'),
                                ]),
                                duration: Duration(seconds: 10),
                              ));
                              final error = await provider.gemini.testConnection();
                              if (!mounted) return;
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(SnackBar( // ignore: use_build_context_synchronously
                                content: Text(error == null ? 'Connessione OK' : error),
                                backgroundColor:
                                    error == null ? AppColors.positive : AppColors.negative,
                              ));
                            },
                            child: const Text('Testa',
                                style: TextStyle(color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Altri provider ────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('ALTRI PROVIDER',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'OpenAI, Anthropic e altri provider. Le chiavi vengono rilevate automaticamente nella selezione modelli.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.customApiKeys.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Nessuna chiave aggiunta.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      )
                    else
                      ...provider.customApiKeys.asMap().entries.map((e) {
                        final entry = e.value;
                        return Column(
                          children: [
                            if (e.key > 0) const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Text(entry.emoji,
                                  style: const TextStyle(fontSize: 22)),
                              title: Text(entry.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              subtitle: entry.description != null &&
                                      entry.description!.isNotEmpty
                                  ? Text(entry.description!,
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 11))
                                  : const Text('••••••••••••••••',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                          letterSpacing: 2)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: AppColors.textSecondary, size: 18),
                                    onPressed: () => _showForm(context, entry),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppColors.negative, size: 18),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: AppColors.surface,
                                          title: const Text('Elimina chiave',
                                              style: TextStyle(
                                                  color: AppColors.textPrimary)),
                                          content: Text(
                                              'Eliminare la chiave "${entry.name}"?',
                                              style: const TextStyle(
                                                  color: AppColors.textSecondary)),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: const Text('Annulla')),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                child: const Text('Elimina',
                                                    style: TextStyle(
                                                        color: AppColors.negative))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        // ignore: use_build_context_synchronously
                                        await context
                                            .read<AppProvider>()
                                            .deleteCustomApiKey(entry.id);
                                      }
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
                        label: const Text('Aggiungi chiave'),
                        onPressed: () => _showForm(context, null),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

// ── Dot indicatori ────────────────────────────────────────────

class _ProviderDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ProviderDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool active;
  const _StatusDot({required this.active});

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
        active ? 'Attiva' : 'Non configurata',
        style: TextStyle(
          color: active ? AppColors.positive : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Form chiave API ────────────────────────────────────────────

class _ApiKeyForm extends StatefulWidget {
  final ApiKeyEntry? existing;
  const _ApiKeyForm({this.existing});
  @override
  State<_ApiKeyForm> createState() => _ApiKeyFormState();
}

class _ApiKeyFormState extends State<_ApiKeyForm> {
  final _nameCtrl = TextEditingController();
  final _keyCtrl  = TextEditingController();
  final _descCtrl = TextEditingController();
  String _emoji = '🔑';
  bool _obscureKey = true;

  static const _services = [
    ('OpenAI', '🤖'), ('Anthropic', '🧠'), ('Groq', '⚡'),
    ('Mistral', '🌀'), ('Cohere', '🔮'), ('Hugging Face', '🤗'),
    ('ElevenLabs', '🎙️'), ('Replicate', '🖼️'), ('Custom', '🔑'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _keyCtrl.text  = widget.existing!.key;
      _descCtrl.text = widget.existing!.description ?? '';
      _emoji         = widget.existing!.emoji;
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
            Center(
              child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(widget.existing != null ? 'Modifica chiave' : 'Nuova chiave API',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17)),
            const SizedBox(height: 16),
            const Text('Provider',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _services.map((s) {
                final selected = _nameCtrl.text == s.$1;
                return GestureDetector(
                  onTap: () => setState(() { _nameCtrl.text = s.$1; _emoji = s.$2; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(s.$2, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(s.$1,
                          style: TextStyle(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome provider',
                  hintText: 'Es. OpenAI, Anthropic…'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyCtrl,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: 'Chiave API',
                hintText: 'sk-…',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureKey
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                      size: 18),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nota (opzionale)',
                  hintText: 'Es. Progetto lavoro, limite 20\$/mese…'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(
                    widget.existing != null ? 'Salva modifiche' : 'Aggiungi chiave'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
