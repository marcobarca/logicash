import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
import 'settings_accounts_screen.dart';
import 'settings_preferences_screen.dart';
import 'settings_security_screen.dart';
import 'settings_ai_screen.dart';
import 'settings_import_screen.dart';
import 'settings_api_keys_screen.dart';
import 'settings_help_screen.dart';
import 'settings_import_history_screen.dart';

class SettingsMenuScreen extends StatefulWidget {
  const SettingsMenuScreen({super.key});
  @override
  State<SettingsMenuScreen> createState() => _SettingsMenuScreenState();
}

class _SettingsMenuScreenState extends State<SettingsMenuScreen> {
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final on = await context.read<AppProvider>().isPinEnabled;
    if (mounted) setState(() => _pinEnabled = on);
  }

  void _push(Widget screen, {bool reloadPin = false}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) { if (reloadPin) _loadPin(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            children: [
              // ── Generale ──────────────────────────────────────
              _SectionLabel('Generale'),
              _Item(
                icon: Icons.account_balance_outlined,
                color: AppColors.positive,
                title: 'I tuoi conti',
                subtitle: provider.accounts.isEmpty
                    ? 'Nessun conto aggiunto'
                    : '${provider.accounts.length} ${provider.accounts.length == 1 ? 'conto' : 'conti'} · €${provider.totalBalance.toStringAsFixed(0)}',
                onTap: () => _push(const SettingsAccountsScreen()),
              ),
              const _Divider(),
              _Item(
                icon: Icons.calendar_today_outlined,
                color: AppColors.warning,
                title: 'Mese fiscale & analisi',
                subtitle: provider.fiscalMonthStartDay == 1
                    ? 'Mese solare · ${provider.referencePeriod} mesi'
                    : 'Dal ${provider.fiscalMonthStartDay} · ${provider.referencePeriod} mesi',
                onTap: () => _push(const SettingsPreferencesScreen()),
              ),

              // ── Sicurezza ──────────────────────────────────────
              _SectionLabel('Sicurezza'),
              _Item(
                icon: Icons.shield_outlined,
                color: const Color(0xFFFFB74D),
                title: 'Sicurezza',
                subtitle: _pinEnabled ? 'PIN attivo' : 'PIN disattivato',
                onTap: () => _push(
                  SettingsSecurityScreen(pinEnabled: _pinEnabled),
                  reloadPin: true,
                ),
              ),

              // ── Intelligenza artificiale ───────────────────────
              _SectionLabel('Intelligenza artificiale'),
              _Item(
                icon: Icons.key_outlined,
                color: AppColors.primary,
                title: 'Chiavi AI',
                subtitle: provider.gemini.isConfigured
                    ? 'Google configurato${provider.customApiKeys.isNotEmpty ? ' · +${provider.customApiKeys.length} altri' : ''}'
                    : provider.customApiKeys.isNotEmpty
                        ? '${provider.customApiKeys.length} chiavi'
                        : 'Nessuna chiave configurata',
                badge: !provider.gemini.isConfigured && provider.customApiKeys.isEmpty,
                onTap: () => _push(const SettingsApiKeysScreen()),
              ),
              const _Divider(),
              _Item(
                icon: Icons.auto_awesome_outlined,
                color: const Color(0xFF9575CD),
                title: 'Modelli AI',
                subtitle: 'Scegli il modello per ogni funzione',
                onTap: () => _push(const SettingsAiScreen()),
              ),

              // ── Dati ──────────────────────────────────────────
              _SectionLabel('Dati'),
              _Item(
                icon: Icons.upload_file_outlined,
                color: AppColors.textMuted,
                title: 'Profili importazione',
                subtitle: provider.importProfiles.isEmpty
                    ? 'Nessun profilo salvato'
                    : '${provider.importProfiles.length} profili',
                onTap: () => _push(const SettingsImportScreen()),
              ),
              const _Divider(),
              _Item(
                icon: Icons.history_rounded,
                color: AppColors.textMuted,
                title: 'Storico importazioni',
                subtitle: provider.importBatches.isEmpty
                    ? 'Nessuna importazione'
                    : '${provider.importBatches.length} file importati',
                onTap: () => _push(const SettingsImportHistoryScreen()),
              ),

              // ── Supporto ──────────────────────────────────────
              _SectionLabel('Supporto'),
              _Item(
                icon: Icons.help_outline_rounded,
                color: const Color(0xFF29B6F6),
                title: 'Guida all\'app',
                subtitle: 'Scopri tutte le funzionalità',
                onTap: () => _push(const SettingsHelpScreen()),
              ),

              // ── Footer ────────────────────────────────────────
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    const Text('Logicash v1.0.0',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      '${provider.availableMonths.length} mesi importati · Database locale',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ── Componenti ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 0,
      color: AppColors.border,
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool badge;

  const _Item({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icona
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            // Testo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            // Badge + freccia
            if (badge)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                    color: AppColors.warning, shape: BoxShape.circle),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
