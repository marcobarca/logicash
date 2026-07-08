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
  // Chiave Google caricata in stato per poterla mostrare nella lista.
  String _googleKey = '';

  @override
  void initState() {
    super.initState();
    _loadGoogleKey();
  }

  Future<void> _loadGoogleKey() async {
    final key = await context.read<AppProvider>().getGeminiApiKey();
    if (mounted) setState(() => _googleKey = key ?? '');
  }

  void _showForm(BuildContext context, {_KeyEntry? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ApiKeyForm(existing: existing),
    ).then((_) => _loadGoogleKey()); // ricarica per aggiornare Google se modificata
  }

  Future<void> _deleteGoogleKey() async {
    final ok = await _confirm(context, 'Eliminare la chiave Google?');
    if (!ok || !mounted) return;
    await context.read<AppProvider>().setGeminiApiKey('');
    _loadGoogleKey();
  }

  Future<void> _deleteCustomKey(String id) async {
    final ok = await _confirm(context, 'Eliminare la chiave?');
    if (!ok || !mounted) return;
    await context.read<AppProvider>().deleteCustomApiKey(id);
  }

  Future<bool> _confirm(BuildContext ctx, String message) async {
    return await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Conferma', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chiavi AI')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final hasGoogle = _googleKey.isNotEmpty;
          final customs = provider.customApiKeys;
          final isEmpty = !hasGoogle && customs.isEmpty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Nessuna chiave configurata. Aggiungine una per usare l\'AI.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),

                    // ── Google (se configurata) ────────────────────
                    if (hasGoogle) ...[
                      _KeyTile(
                        name: 'Google',
                        maskedKey: '••••${_googleKey.length > 4 ? _googleKey.substring(_googleKey.length - 4) : '••••'}',
                        onEdit: () => _showForm(context,
                            existing: _KeyEntry.google(key: _googleKey)),
                        onDelete: _deleteGoogleKey,
                      ),
                      if (customs.isNotEmpty) const Divider(height: 1),
                    ],

                    // ── Chiavi custom ──────────────────────────────
                    ...customs.asMap().entries.map((e) {
                      final entry = e.value;
                      final isFirst = e.key == 0;
                      return Column(
                        children: [
                          if (!isFirst || hasGoogle) const SizedBox.shrink(),
                          if (e.key > 0) const Divider(height: 1),
                          _KeyTile(
                            name: entry.name,
                            maskedKey: entry.description?.isNotEmpty == true
                                ? entry.description!
                                : '••••••••••••••••',
                            onEdit: () => _showForm(context,
                                existing: _KeyEntry.custom(apiKeyEntry: entry)),
                            onDelete: () => _deleteCustomKey(entry.id),
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
                        onPressed: () => _showForm(context),
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

// ── Tile chiave ───────────────────────────────────────────────

class _KeyTile extends StatelessWidget {
  final String name;
  final String maskedKey;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _KeyTile({
    required this.name,
    required this.maskedKey,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(maskedKey,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.negative, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Modello unificato per la form ─────────────────────────────

class _KeyEntry {
  final bool isGoogle;
  final String? key;
  final ApiKeyEntry? apiKeyEntry;

  const _KeyEntry.google({this.key}) : isGoogle = true, apiKeyEntry = null;
  const _KeyEntry.custom({this.apiKeyEntry}) : isGoogle = false, key = null;
}

// ── Form aggiunta / modifica chiave ───────────────────────────

class _ApiKeyForm extends StatefulWidget {
  final _KeyEntry? existing;
  const _ApiKeyForm({this.existing});
  @override
  State<_ApiKeyForm> createState() => _ApiKeyFormState();
}

class _ApiKeyFormState extends State<_ApiKeyForm> {
  static const _providers = [
    'Google', 'OpenAI', 'Anthropic', 'Groq', 'Mistral',
    'Hugging Face', 'ElevenLabs', 'Replicate', 'Custom',
  ];

  String? _selectedProvider;
  final _keyCtrl  = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      if (widget.existing!.isGoogle) {
        _selectedProvider = 'Google';
        _keyCtrl.text = widget.existing!.key ?? '';
      } else {
        final e = widget.existing!.apiKeyEntry!;
        _selectedProvider = e.name;
        _keyCtrl.text = e.key;
        _descCtrl.text = e.description ?? '';
      }
    }
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prov = _selectedProvider;
    final key  = _keyCtrl.text.trim();
    if (prov == null || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona un provider e inserisci la chiave')));
      return;
    }

    final provider = context.read<AppProvider>();

    if (prov == 'Google') {
      await provider.setGeminiApiKey(key);
    } else {
      final entry = ApiKeyEntry(
        id:          widget.existing?.apiKeyEntry?.id ??
                     DateTime.now().millisecondsSinceEpoch.toString(),
        name:        prov,
        key:         key,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        emoji:       '🔑',
      );
      await provider.saveCustomApiKey(entry);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _selectedProvider != null;

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
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.existing != null ? 'Modifica chiave' : 'Nuova chiave API',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 20),

            // ── Dropdown provider ──────────────────────────────
            const Text('Provider',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11,
                    fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProvider,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  hint: const Text('Seleziona provider',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  icon: Icon(Icons.expand_more,
                      color: isActive ? AppColors.primary : AppColors.textMuted, size: 20),
                  onChanged: (v) => setState(() => _selectedProvider = v),
                  selectedItemBuilder: (context) => _providers.map((p) =>
                      Text(p,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis)).toList(),
                  items: _providers.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14)),
                  )).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Chiave API ─────────────────────────────────────
            TextField(
              controller: _keyCtrl,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: 'Chiave API',
                hintText: _selectedProvider == 'Google' ? 'AIza...' : 'sk-…',
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
            ),

            // ── Nota (solo per provider non-Google) ───────────
            if (_selectedProvider != null && _selectedProvider != 'Google') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nota (opzionale)',
                    hintText: 'Es. Progetto lavoro, limite 20\$/mese…'),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],

            const SizedBox(height: 24),
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
