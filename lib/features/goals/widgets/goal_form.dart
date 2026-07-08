import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/database/models/goal_model.dart';
import '../../../providers/app_provider.dart';
import '../../../shared/theme/app_theme.dart';

class GoalForm extends StatefulWidget {
  final GoalModel? existing;
  const GoalForm({super.key, this.existing});

  @override
  State<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<GoalForm> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String _selectedEmoji = '🎯';
  final _emojis = ['🎯', '🏠', '✈️', '🚗', '💻', '🎓', '💍', '🏖️', '🏋️', '📱'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _targetController.text = widget.existing!.target.toStringAsFixed(0);
      _selectedEmoji = widget.existing!.emoji ?? '🎯';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
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
              Text(isEdit ? 'Modifica obiettivo' : 'Nuovo obiettivo',
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Emoji picker
          Wrap(
            spacing: 8,
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
            decoration: const InputDecoration(labelText: 'Nome obiettivo', hintText: 'Es. Vacanza estiva'),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Importo target (€)', hintText: 'Es. 2000'),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: Text(isEdit ? 'Salva modifiche' : 'Crea obiettivo'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim());

    if (name.isEmpty || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi correttamente')),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final goal = GoalModel(
      id: widget.existing?.id,
      name: name,
      target: target,
      createdAt: DateTime.now().toIso8601String(),
      emoji: _selectedEmoji,
    );

    if (widget.existing != null) {
      provider.updateGoal(goal);
    } else {
      provider.addGoal(goal);
    }

    Navigator.pop(context);
  }
}
