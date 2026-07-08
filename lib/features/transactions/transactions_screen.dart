import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_provider.dart';
import '../../core/database/models/transaction_model.dart';
import '../../core/database/models/import_profile_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import '../import/profile_setup_screen.dart';
import '../../shared/widgets/lc_empty_state.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  String? _filterMonth;
  bool? _filterType; // true=entrate, false=uscite
  List<TransactionModel> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    final provider = context.read<AppProvider>();
    final results = await provider.searchTransactions(
      yearMonth: _filterMonth,
      onlyIncome: _filterType == true ? true : null,
      onlyExpenses: _filterType == false ? true : null,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  Future<void> _importFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (picked == null || picked.files.single.path == null) return;
    if (!mounted) return;

    final filePath = picked.files.single.path!;
    final provider = context.read<AppProvider>();
    final profiles = provider.importProfiles;

    // Mostra selezione profilo (bottom sheet)
    final chosenProfile = await _showProfilePicker(filePath, profiles);
    if (chosenProfile == null || !mounted) return;

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ImportLoadingDialog(),
    );

    try {
      final importResult = await provider.importFileWithProfile(filePath, chosenProfile);

      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (_) => _ImportResultDialog(
          added: importResult.added,
          duplicates: importResult.duplicates,
        ),
      );
      _search();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'import: $e'),
          backgroundColor: AppColors.negative,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<ImportProfile?> _showProfilePicker(String filePath, List<ImportProfile> profiles) async {
    if (profiles.isEmpty) {
      // Nessun profilo salvato → vai direttamente al setup AI
      return _goToProfileSetup(filePath);
    }

    // Mostra bottom sheet con profili esistenti + opzione "Rileva nuovo"
    return showModalBottomSheet<ImportProfile>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ProfilePickerSheet(
        filePath: filePath,
        profiles: profiles,
        onNewProfile: () async {
          Navigator.pop(ctx);
          final p = await _goToProfileSetup(filePath);
          return p;
        },
      ),
    );
  }

  Future<ImportProfile?> _goToProfileSetup(String filePath) {
    return Navigator.push<ImportProfile>(
      context,
      MaterialPageRoute(builder: (_) => ProfileSetupScreen(filePath: filePath)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimenti'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.upload_file, color: Colors.white, size: 18),
            ),
            onPressed: _importFile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Cerca transazioni...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                            onPressed: () { _searchController.clear(); _search(); },
                          )
                        : null,
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Tutte',
                            selected: _filterType == null,
                            onTap: () { setState(() => _filterType = null); _search(); },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Entrate',
                            selected: _filterType == true,
                            color: AppColors.positive,
                            onTap: () { setState(() => _filterType = true); _search(); },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Uscite',
                            selected: _filterType == false,
                            color: AppColors.negative,
                            onTap: () { setState(() => _filterType = false); _search(); },
                          ),
                          const SizedBox(width: 8),
                          ...provider.availableMonths.take(6).map((m) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: m,
                              selected: _filterMonth == m,
                              onTap: () { setState(() => _filterMonth = _filterMonth == m ? null : m); _search(); },
                            ),
                          )),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _results.isEmpty
                    ? Consumer<AppProvider>(
                        builder: (context, provider, _) {
                          final hasAnyData = provider.availableMonths.isNotEmpty;
                          final hasActiveFilters = _filterMonth != null ||
                              _filterType != null ||
                              _searchController.text.isNotEmpty;
                          if (!hasAnyData) {
                            return LcEmptyState(
                              emoji: '📂',
                              title: 'Nessun movimento',
                              body: 'Importa il tuo estratto conto in formato CSV o Excel per iniziare ad analizzare le tue finanze.',
                              actionLabel: 'Importa file',
                              onAction: _importFile,
                            );
                          }
                          return LcEmptyState(
                            emoji: '🔍',
                            title: 'Nessun risultato',
                            body: 'Nessun movimento corrisponde ai filtri selezionati.',
                            actionLabel: hasActiveFilters ? 'Rimuovi filtri' : null,
                            onAction: hasActiveFilters ? () {
                              setState(() {
                                _filterMonth = null;
                                _filterType = null;
                                _searchController.clear();
                              });
                              _search();
                            } : null,
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _TransactionTile(tx: _results[i])
                            .animate().fadeIn(duration: 200.ms, delay: (i * 20).ms),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.2) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? c : AppColors.textSecondary, fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final color = isIncome ? AppColors.positive : AppColors.negative;
    final sign = isIncome ? '+' : '-';

    return LcCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.operation ?? tx.details ?? 'N/D',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(tx.date, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                if (tx.category != null) ...[
                  const SizedBox(height: 2),
                  Text(tx.category!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('$sign€${tx.absAmount.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ProfilePickerSheet extends StatelessWidget {
  final String filePath;
  final List<ImportProfile> profiles;
  final Future<ImportProfile?> Function() onNewProfile;

  const _ProfilePickerSheet({required this.filePath, required this.profiles, required this.onNewProfile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seleziona formato', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 4),
                Text('Scegli il profilo per ${filePath.split(RegExp(r'[/\\]')).last}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          ...profiles.map((p) => ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.account_balance, color: AppColors.primary, size: 20),
            ),
            title: Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            subtitle: Text('${p.fileType.toUpperCase()} · avviato da riga ${p.dataStartRow}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            onTap: () => Navigator.pop(context, p),
          )),
          const Divider(color: AppColors.border, height: 1),
          ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            ),
            title: const Text('Rileva nuovo formato con AI', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            subtitle: const Text('Gemini analizzerà automaticamente il file', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            onTap: () async {
              final p = await onNewProfile();
              if (context.mounted && p != null) Navigator.pop(context, p);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ImportLoadingDialog extends StatelessWidget {
  const _ImportLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Importazione in corso',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sto leggendo i movimenti e rilevando i duplicati...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportResultDialog extends StatelessWidget {
  final int added;
  final int duplicates;

  const _ImportResultDialog({required this.added, required this.duplicates});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.positive.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.check_circle, color: AppColors.positive, size: 32),
            ),
            const SizedBox(height: 20),
            const Text('Import completato', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('$added', style: const TextStyle(color: AppColors.positive, fontSize: 28, fontWeight: FontWeight.w800)),
                      const Text('nuovi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Column(
                    children: [
                      Text('$duplicates', style: const TextStyle(color: AppColors.textMuted, fontSize: 28, fontWeight: FontWeight.w800)),
                      const Text('già presenti', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Perfetto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
