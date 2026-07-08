import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_provider.dart';
import '../../core/database/db_helper.dart';
import '../../core/database/models/transaction_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import '../../shared/widgets/lc_empty_state.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/anomaly_card.dart';
import 'widgets/weekday_heatmap.dart';

// ── Utility: label periodo fiscale ────────────────────────────

const _kMonthShort = ['', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
const _kMonthFull  = ['', 'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];

String _periodLabel(String yearMonth, int startDay) {
  final y = int.parse(yearMonth.substring(0, 4));
  final m = int.parse(yearMonth.substring(5, 7));
  if (startDay <= 1) return '${_kMonthFull[m]} $y';
  final end = DateTime(y, m + 1, startDay - 1);
  return '$startDay ${_kMonthShort[m]} – ${startDay - 1} ${_kMonthShort[end.month]} ${end.year}';
}

// ── Schermata principale ──────────────────────────────────────

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _prevMonth(List<String> months) {
    final sorted = _sorted(months);
    final idx = sorted.indexOf(_selectedMonth ?? sorted.last);
    if (idx > 0) setState(() => _selectedMonth = sorted[idx - 1]);
  }

  void _nextMonth(List<String> months) {
    final sorted = _sorted(months);
    final idx = sorted.indexOf(_selectedMonth ?? sorted.last);
    if (idx < sorted.length - 1) setState(() => _selectedMonth = sorted[idx + 1]);
  }

  List<String> _sorted(List<String> months) =>
      [...months]..sort((a, b) => a.compareTo(b));

  void _showPicker(BuildContext context, List<String> months, int startDay) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MonthPickerSheet(
        months: months,
        selected: _selectedMonth ?? _sorted(months).last,
        startDay: startDay,
        onPick: (ym) { setState(() => _selectedMonth = ym); Navigator.pop(context); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final months = provider.availableMonths;
        final startDay = provider.fiscalMonthStartDay;
        final sorted = _sorted(months);
        final selected = _selectedMonth ?? (sorted.isNotEmpty ? sorted.last : '');

        if (months.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Spese')),
            body: LcEmptyState(
              emoji: '📊',
              title: 'Nessuna analisi disponibile',
              body: 'Importa i tuoi movimenti per vedere grafici, categorie e anomalie di spesa.',
              actionLabel: 'Importa movimenti',
              onAction: () => Navigator.of(context).pushNamed('/transactions'),
            ),
          );
        }

        final idx = sorted.indexOf(selected);
        final canPrev = idx > 0;
        final canNext = idx < sorted.length - 1;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Spese'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(88),
              child: Column(
                children: [
                  // ── Selettore periodo ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 26),
                          color: canPrev ? AppColors.textPrimary : AppColors.border,
                          onPressed: canPrev ? () => _prevMonth(months) : null,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showPicker(context, months, startDay),
                            child: Column(
                              children: [
                                Text(
                                  _periodLabel(selected, startDay),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text('Tocca per cambiare',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                    SizedBox(width: 3),
                                    Icon(Icons.keyboard_arrow_down,
                                        color: AppColors.textMuted, size: 14),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 26),
                          color: canNext ? AppColors.textPrimary : AppColors.border,
                          onPressed: canNext ? () => _nextMonth(months) : null,
                        ),
                      ],
                    ),
                  ),
                  // ── Tab bar ───────────────────────────────────
                  TabBar(
                    controller: _tabs,
                    tabs: const [
                      Tab(text: 'Analisi'),
                      Tab(text: 'Movimenti'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _AnalisiTab(
                key: ValueKey('analisi_$selected'),
                yearMonth: selected,
                provider: provider,
              ),
              _MovimentiTab(
                key: ValueKey('movimenti_$selected'),
                yearMonth: selected,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Picker mese ───────────────────────────────────────────────

class _MonthPickerSheet extends StatefulWidget {
  final List<String> months;
  final String selected;
  final int startDay;
  final ValueChanged<String> onPick;

  const _MonthPickerSheet({
    required this.months,
    required this.selected,
    required this.startDay,
    required this.onPick,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _selectedYear;
  late Map<int, Set<int>> _byYear;

  @override
  void initState() {
    super.initState();
    _byYear = {};
    for (final ym in widget.months) {
      final y = int.parse(ym.substring(0, 4));
      final m = int.parse(ym.substring(5, 7));
      _byYear.putIfAbsent(y, () => {}).add(m);
    }
    _selectedYear = int.parse(widget.selected.substring(0, 4));
  }

  @override
  Widget build(BuildContext context) {
    final years = _byYear.keys.toList()..sort();
    final availableMonths = _byYear[_selectedYear] ?? {};

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Seleziona periodo',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 16),

            // Anno
            if (years.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: years.map((y) {
                    final sel = y == _selectedYear;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedYear = y),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text('$y',
                            style: TextStyle(
                                color: sel ? Colors.white : AppColors.textSecondary,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                fontSize: 14)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Griglia mesi
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.0,
              children: List.generate(12, (i) {
                final month = i + 1;
                final hasData = availableMonths.contains(month);
                final ym = '$_selectedYear-${month.toString().padLeft(2, '0')}';
                final isSel = ym == widget.selected;
                return GestureDetector(
                  onTap: hasData ? () => widget.onPick(ym) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary
                          : hasData
                              ? AppColors.surfaceElevated
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel
                            ? AppColors.primary
                            : hasData
                                ? AppColors.border
                                : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _kMonthShort[month],
                        style: TextStyle(
                          color: isSel
                              ? Colors.white
                              : hasData
                                  ? AppColors.textPrimary
                                  : AppColors.border,
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Analisi ───────────────────────────────────────────────

class _AnalisiTab extends StatefulWidget {
  final String yearMonth;
  final AppProvider provider;
  const _AnalisiTab({super.key, required this.yearMonth, required this.provider});
  @override
  State<_AnalisiTab> createState() => _AnalisiTabState();
}

class _AnalisiTabState extends State<_AnalisiTab> {
  List<CategorySummary> _cats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await widget.provider.getCategoriesForMonth(widget.yearMonth);
    if (mounted) setState(() { _cats = cats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        AnomalyCard(current: _cats, averages: widget.provider.categoryAverages),
        const SizedBox(height: 16),
        LcSectionTitle(title: 'Per categoria'),
        const SizedBox(height: 12),
        CategoryPieChart(categories: _cats),
        const SizedBox(height: 20),
        LcSectionTitle(title: 'Andamento mensile'),
        const SizedBox(height: 12),
        MonthlyBarChart(summaries: widget.provider.monthlySummaries),
        const SizedBox(height: 20),
        LcSectionTitle(title: 'Quando spendi di più'),
        const SizedBox(height: 12),
        WeekdayHeatmap(weekdayData: widget.provider.weekdaySpending),
        const SizedBox(height: 20),
        LcSectionTitle(title: 'Top 10 spese'),
        const SizedBox(height: 12),
        _Top10Widget(yearMonth: widget.yearMonth),
      ],
    );
  }
}

// ── Tab Movimenti ─────────────────────────────────────────────

class _MovimentiTab extends StatefulWidget {
  final String yearMonth;
  const _MovimentiTab({super.key, required this.yearMonth});
  @override
  State<_MovimentiTab> createState() => _MovimentiTabState();
}

class _MovimentiTabState extends State<_MovimentiTab> {
  List<TransactionModel> _txs = [];
  bool _loading = true;
  bool? _filterType; // null=tutti, true=entrate, false=uscite
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await context.read<AppProvider>().searchTransactions(
      yearMonth: widget.yearMonth,
      onlyIncome: _filterType == true ? true : null,
      onlyExpenses: _filterType == false ? true : null,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
    if (mounted) setState(() { _txs = results; _loading = false; });
  }

  void _openDetail(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TxDetailSheet(
        tx: tx,
        onDeleted: () { Navigator.pop(context); _load(); },
        onUpdated: (_) { Navigator.pop(context); _load(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = _filterType != null || _searchCtrl.text.isNotEmpty;

    return Column(
      children: [
        // ── Filtri ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Column(
            children: [
              if (_showSearch) ...[
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _load(),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cerca movimento...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                      onPressed: () { _searchCtrl.clear(); setState(() => _showSearch = false); _load(); },
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  _TypeChip(label: 'Tutti', selected: _filterType == null,
                      onTap: () { setState(() => _filterType = null); _load(); }),
                  const SizedBox(width: 8),
                  _TypeChip(label: 'Entrate', selected: _filterType == true,
                      color: AppColors.positive,
                      onTap: () { setState(() => _filterType = true); _load(); }),
                  const SizedBox(width: 8),
                  _TypeChip(label: 'Uscite', selected: _filterType == false,
                      color: AppColors.negative,
                      onTap: () { setState(() => _filterType = false); _load(); }),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.search,
                        color: _showSearch ? AppColors.primary : AppColors.textMuted,
                        size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _showSearch = !_showSearch),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Lista ───────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _txs.isEmpty
                  ? LcEmptyState(
                      emoji: hasFilters ? '🔍' : '📭',
                      title: hasFilters ? 'Nessun risultato' : 'Nessun movimento',
                      body: hasFilters
                          ? 'Nessun movimento corrisponde ai filtri selezionati.'
                          : 'Non ci sono movimenti per questo periodo.',
                      actionLabel: hasFilters ? 'Rimuovi filtri' : null,
                      onAction: hasFilters ? () {
                        setState(() { _filterType = null; _searchCtrl.clear(); _showSearch = false; });
                        _load();
                      } : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _txs.length,
                      separatorBuilder: (context2, i2) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _TxTile(
                        tx: _txs[i],
                        onTap: () => _openDetail(_txs[i]),
                      ).animate().fadeIn(duration: 180.ms, delay: (i * 15).ms),
                    ),
        ),
      ],
    );
  }
}

// ── Tile movimento ────────────────────────────────────────────

class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onTap;
  const _TxTile({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final color = isIncome ? AppColors.positive : AppColors.negative;

    return GestureDetector(
      onTap: onTap,
      child: LcCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.operation ?? tx.details ?? 'N/D',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(tx.date,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    if (tx.category != null) ...[
                      const Text('  ·  ', style: TextStyle(color: AppColors.border, fontSize: 11)),
                      Flexible(child: Text(tx.category!,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${isIncome ? '+' : '-'}€${tx.absAmount.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.border, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Detail sheet ──────────────────────────────────────────────

class _TxDetailSheet extends StatefulWidget {
  final TransactionModel tx;
  final VoidCallback onDeleted;
  final ValueChanged<TransactionModel> onUpdated;
  const _TxDetailSheet({required this.tx, required this.onDeleted, required this.onUpdated});
  @override
  State<_TxDetailSheet> createState() => _TxDetailSheetState();
}

class _TxDetailSheetState extends State<_TxDetailSheet> {
  bool _editing = false;
  late TextEditingController _descCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _categoryCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl     = TextEditingController(text: widget.tx.operation ?? widget.tx.details ?? '');
    _amountCtrl   = TextEditingController(text: widget.tx.amount.toStringAsFixed(2));
    _categoryCtrl = TextEditingController(text: widget.tx.category ?? '');
  }

  @override
  void dispose() {
    _descCtrl.dispose(); _amountCtrl.dispose(); _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null) return;
    final updated = TransactionModel(
      id: widget.tx.id,
      date: widget.tx.date,
      yearMonth: widget.tx.yearMonth,
      operation: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      details: widget.tx.details,
      account: widget.tx.account,
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      currency: widget.tx.currency,
      amount: amount,
    );
    await context.read<AppProvider>().updateTransaction(updated);
    widget.onUpdated(updated);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Elimina movimento', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Questa operazione non può essere annullata.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Elimina', style: TextStyle(color: AppColors.negative))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().deleteTransaction(widget.tx.id);
      widget.onDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final isIncome = tx.isIncome;
    final color = isIncome ? AppColors.positive : AppColors.negative;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.operation ?? tx.details ?? 'N/D',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text('${isIncome ? '+' : '-'}€${tx.absAmount.toStringAsFixed(2)}',
                          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_editing ? Icons.close : Icons.edit_outlined,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => setState(() => _editing = !_editing),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_editing) ...[
              // ── Modalità modifica ────────────────────────
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descrizione'),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-\d.,]'))],
                decoration: const InputDecoration(
                  labelText: 'Importo (negativo = uscita)',
                  prefixIcon: Icon(Icons.euro, color: AppColors.textMuted, size: 18),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'Categoria'),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _save, child: const Text('Salva modifiche')),
              ),
            ] else ...[
              // ── Modalità dettaglio ───────────────────────
              _DetailRow(label: 'Data', value: tx.date),
              if (tx.category != null) _DetailRow(label: 'Categoria', value: tx.category!),
              if (tx.account != null) _DetailRow(label: 'Conto', value: tx.account!),
              if (tx.details != null && tx.details != tx.operation)
                _DetailRow(label: 'Dettagli', value: tx.details!),
              _DetailRow(label: 'Valuta', value: tx.currency),
              _DetailRow(label: 'ID', value: '${tx.id.substring(0, 16)}…', mono: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.negative)),
                  icon: const Icon(Icons.delete_outline, color: AppColors.negative, size: 18),
                  label: const Text('Elimina movimento', style: TextStyle(color: AppColors.negative)),
                  onPressed: _delete,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _DetailRow({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontFamily: mono ? 'monospace' : null,
                )),
          ),
        ],
      ),
    );
  }
}

// ── Type chip ─────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.18) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? c : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}

// ── Top 10 ───────────────────────────────────────────────────

class _Top10Widget extends StatelessWidget {
  final String yearMonth;
  const _Top10Widget({required this.yearMonth});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<AppProvider>().getTop10Expenses(yearMonth: yearMonth),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final txs = snapshot.data!;
        if (txs.isEmpty) return const SizedBox();

        return LcCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: txs.asMap().entries.map((entry) {
              final i = entry.key;
              final tx = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(6)),
                          child: Center(
                            child: Text('${i + 1}',
                                style: const TextStyle(color: AppColors.textSecondary,
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.operation ?? tx.details ?? 'N/D',
                                  style: const TextStyle(color: AppColors.textPrimary,
                                      fontSize: 13, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (tx.category != null)
                                Text(tx.category!,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text('-€${tx.absAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.negative,
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (i < txs.length - 1)
                    const Divider(height: 1, indent: 54),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
