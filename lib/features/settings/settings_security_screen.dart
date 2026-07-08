import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import '../auth/pin_setup_screen.dart';

class SettingsSecurityScreen extends StatefulWidget {
  final bool pinEnabled;
  const SettingsSecurityScreen({super.key, required this.pinEnabled});

  @override
  State<SettingsSecurityScreen> createState() => _SettingsSecurityScreenState();
}

class _SettingsSecurityScreenState extends State<SettingsSecurityScreen> {
  late bool _pinEnabled;

  @override
  void initState() {
    super.initState();
    _pinEnabled = widget.pinEnabled;
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
    final provider = context.read<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sicurezza')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                          Text('PIN di accesso',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                          Text('Richiesto ad ogni apertura dell\'app',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _pinEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) async {
                        if (val) {
                          await _showPinSetup(provider);
                        } else {
                          await provider.disablePin();
                          if (!mounted) return;
                          setState(() => _pinEnabled = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN disattivato')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                if (_pinEnabled) ...[
                  const Divider(height: 24),
                  TextButton.icon(
                    onPressed: () => _showPinSetup(provider, isChange: true),
                    icon: const Icon(Icons.lock_reset, color: AppColors.primary, size: 18),
                    label: const Text('Cambia PIN', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          LcCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _pinEnabled
                        ? 'Il PIN protegge l\'accesso all\'app. Verrà richiesto ad ogni apertura.'
                        : 'Attiva il PIN per proteggere l\'accesso ai tuoi dati finanziari.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
