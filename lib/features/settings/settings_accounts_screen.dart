import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../core/database/models/account_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';

class SettingsAccountsScreen extends StatelessWidget {
  const SettingsAccountsScreen({super.key});

  void _showForm(BuildContext context, AppProvider provider, {AccountModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AccountForm(existing: existing, provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I tuoi conti'),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, _) => TextButton.icon(
              onPressed: () => _showForm(context, provider),
              icon: const Icon(Icons.add, color: AppColors.positive, size: 18),
              label: const Text('Aggiungi', style: TextStyle(color: AppColors.positive, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.accounts.isEmpty)
                LcCard(
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aggiungi i tuoi conti per vedere il patrimonio totale',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                ...provider.accounts.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LcCard(
                    child: Row(
                      children: [
                        Text(a.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name,
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('€${a.balance.toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppColors.positive, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 18),
                          onPressed: () => _showForm(context, provider, existing: a),
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
            ],
          );
        },
      ),
    );
  }
}

// ── Form conto ────────────────────────────────────────────────

class _AccountForm extends StatefulWidget {
  final AccountModel? existing;
  final AppProvider provider;
  const _AccountForm({this.existing, required this.provider});

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _nameCtrl    = TextEditingController();
  final _balanceCtrl = TextEditingController();
  String _emoji = '🏦';

  static const _emojis = ['🏦', '💳', '💰', '🏧', '📱', '💵', '🪙', '🏛️'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text    = widget.existing!.name;
      _balanceCtrl.text = widget.existing!.balance.toStringAsFixed(2);
      _emoji            = widget.existing!.emoji;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name    = _nameCtrl.text.trim();
    final balance = double.tryParse(_balanceCtrl.text.trim().replaceAll(',', '.'));
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
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome conto', hintText: 'Es. Intesa Sanpaolo, N26...'),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]'))],
            decoration: const InputDecoration(
              labelText: 'Saldo attuale (€)',
              hintText: '0.00',
              prefixIcon: Icon(Icons.euro, color: AppColors.textMuted, size: 18),
            ),
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
}
