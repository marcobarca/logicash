import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/database/models/fixed_expense_model.dart';
import '../../../providers/app_provider.dart';
import '../../../shared/theme/app_theme.dart';

class FixedExpenseForm extends StatefulWidget {
  final FixedExpenseModel? existing;
  const FixedExpenseForm({super.key, this.existing});

  @override
  State<FixedExpenseForm> createState() => _FixedExpenseFormState();
}

class _FixedExpenseFormState extends State<FixedExpenseForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  FixedExpenseFrequency _frequency = FixedExpenseFrequency.monthly;
  String _selectedEmoji = '💳';
  String? _category;

  static const _emojis = ['💳', '🏠', '📱', '🎬', '🏋️', '🚗', '💡', '💧', '🌐', '🎵', '📦', '🏥'];
  static const _categories = [
    'Abbonamenti', 'Casa', 'Trasporti', 'Salute', 'Intrattenimento',
    'Bollette', 'Assicurazioni', 'Sport', 'Istruzione', 'Altro',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e.name;
      _amountController.text = e.amount.toStringAsFixed(2);
      _frequency = e.frequency;
      _selectedEmoji = e.emoji ?? '💳';
      _category = e.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? 'Modifica spesa fissa' : 'Nuova spesa fissa',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Emoji
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) => GestureDetector(
                onTap: () => setState(() => _selectedEmoji = e),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedEmoji == e ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _selectedEmoji == e ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 20)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome', hintText: 'Es. Netflix, Affitto, Palestra'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              decoration: const InputDecoration(labelText: 'Importo (€)', hintText: '0.00'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),

            // Frequenza
            const Text('Frequenza', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: FixedExpenseFrequency.values.map((f) {
                final labels = ['Sett.', 'Mensile', 'Annuale'];
                final selected = _frequency == f;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _frequency = f),
                    child: Container(
                      margin: EdgeInsets.only(right: f != FixedExpenseFrequency.yearly ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(labels[f.index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 13,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Categoria
            const Text('Categoria (opzionale)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) => GestureDetector(
                onTap: () => setState(() => _category = _category == c ? null : c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _category == c ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _category == c ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(c, style: TextStyle(
                    color: _category == c ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 12,
                  )),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Salva modifiche' : 'Aggiungi spesa fissa'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final amountStr = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountStr);

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila nome e importo correttamente')),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final fe = FixedExpenseModel(
      id: widget.existing?.id,
      name: name,
      amount: amount,
      frequency: _frequency,
      category: _category,
      emoji: _selectedEmoji,
      confirmedByUser: true,
      isManual: true,
    );

    if (widget.existing != null) {
      provider.updateFixedExpense(fe);
    } else {
      provider.addFixedExpense(fe);
    }

    Navigator.pop(context);
  }
}
