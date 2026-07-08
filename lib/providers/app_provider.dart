import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/db_helper.dart';
import '../core/database/models/transaction_model.dart';
import '../core/database/models/goal_model.dart';
import '../core/database/models/fixed_expense_model.dart';
import '../core/database/models/account_model.dart';
import '../core/excel/excel_parser.dart';
import '../core/gemini/gemini_service.dart';
import '../core/auth/pin_service.dart';
import '../core/database/models/import_profile_model.dart';
import '../core/import/flexible_parser.dart';
import '../core/api_keys/api_key_store.dart';
import '../core/api_keys/api_key_model.dart';
import '../core/database/models/import_batch_model.dart';
import 'package:path/path.dart' as p;

class AppProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();
  final GeminiService _gemini = GeminiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final PinService _pin = PinService();
  final ApiKeyStore _apiKeyStore = ApiKeyStore();

  // ── State ─────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _currentMonth;
  String get currentMonth {
    if (_currentMonth != null) return _currentMonth!;
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  int _referencePeriod = 6;
  int get referencePeriod => _referencePeriod;

  List<AccountModel> _accounts = [];
  List<AccountModel> get accounts => _accounts;
  double get totalBalance => _accounts.fold(0.0, (s, a) => s + a.balance);

  int _fiscalMonthStartDay = 1;
  int get fiscalMonthStartDay => _fiscalMonthStartDay;

  String get currentFiscalMonth {
    final now = DateTime.now();
    if (_fiscalMonthStartDay <= 1) {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
    // Se siamo prima del giorno di inizio, il mese fiscale è il precedente
    if (now.day < _fiscalMonthStartDay) {
      final prev = DateTime(now.year, now.month - 1);
      return '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
    }
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  List<MonthlySummary> _monthlySummaries = [];
  List<MonthlySummary> get monthlySummaries => _monthlySummaries;

  MonthlySummary? _currentMonthlySummary;
  MonthlySummary? get currentMonthlySummary => _currentMonthlySummary;

  List<CategorySummary> _categorySummaries = [];
  List<CategorySummary> get categorySummaries => _categorySummaries;

  Map<String, double> _categoryAverages = {};
  Map<String, double> get categoryAverages => _categoryAverages;

  Map<int, double> _weekdaySpending = {};
  Map<int, double> get weekdaySpending => _weekdaySpending;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  List<GoalModel> _goals = [];
  List<GoalModel> get goals => _goals;

  List<FixedExpenseModel> _fixedExpenses = [];
  List<FixedExpenseModel> get fixedExpenses => _fixedExpenses;

  double _totalMonthlyFixed = 0;
  double get totalMonthlyFixed => _totalMonthlyFixed;

  double _avgMonthlySavings = 0;
  double get avgMonthlySavings => _avgMonthlySavings;

  String? _lastImportMessage;
  String? get lastImportMessage => _lastImportMessage;

  List<ApiKeyEntry> _customApiKeys = [];
  List<ApiKeyEntry> get customApiKeys => _customApiKeys;

  List<ImportBatch> _importBatches = [];
  List<ImportBatch> get importBatches => _importBatches;

  List<ImportProfile> _importProfiles = [];
  List<ImportProfile> get importProfiles => _importProfiles;

  List<String> _availableMonths = [];
  List<String> get availableMonths => _availableMonths;

  GeminiService get gemini => _gemini;

  // ── Init ──────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _referencePeriod = prefs.getInt('reference_period') ?? 6;
    _fiscalMonthStartDay = prefs.getInt('fiscal_month_start_day') ?? 1;

    final apiKey = await _secureStorage.read(key: 'gemini_api_key');
    if (apiKey != null && apiKey.isNotEmpty) {
      _gemini.configure(
        apiKey,
        agentModelId:    prefs.getString(GeminiModelSlot.agent.prefKey),
        analysisModelId: prefs.getString(GeminiModelSlot.analysis.prefKey),
        utilityModelId:  prefs.getString(GeminiModelSlot.utility.prefKey),
      );
    }

    await _loadCustomApiKeys();
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadSummaries(),
      _loadCategories(),
      _loadTransactions(),
      _loadGoals(),
      _loadFixedExpenses(),
      _loadAccounts(),
      _loadImportProfiles(),
      _loadImportBatches(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSummaries() async {
    _monthlySummaries = await _db.getMonthlySummaries(months: 12);
    _currentMonthlySummary = await _db.getMonthlySummary(currentFiscalMonth);
    _avgMonthlySavings = await _db.getAverageMonthlySavings(months: _referencePeriod);
    _availableMonths = await _db.getAvailableMonths();
  }

  Future<void> _loadCategories() async {
    _categorySummaries = await _db.getCategorySummary(yearMonth: currentFiscalMonth);
    _categoryAverages = await _db.getCategoryAverages(months: _referencePeriod);
    _weekdaySpending = await _db.getSpendingByWeekday(months: _referencePeriod);
  }

  Future<void> _loadTransactions() async {
    _transactions = await _db.getTransactions(limit: 50);
  }

  Future<void> _loadGoals() async {
    _goals = await _db.getGoals();
  }

  Future<void> _loadFixedExpenses() async {
    _fixedExpenses = await _db.getFixedExpenses();
    _totalMonthlyFixed = await _db.getTotalMonthlyFixed();
  }

  Future<void> _loadAccounts() async {
    _accounts = await _db.getAccounts();
  }

  Future<void> _loadImportProfiles() async {
    _importProfiles = await _db.getImportProfiles();
  }

  Future<void> _loadImportBatches() async {
    _importBatches = await _db.getImportBatches();
  }

  // ── Import ────────────────────────────────────────────────────

  Future<ImportResult> importFile(String filePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final transactions = await Future(() => ExcelParser.parse(filePath));
      final batchId = await _db.createImportBatch(
        fileName: p.basename(filePath),
        profileName: 'Intesa Sanpaolo',
        recordCount: transactions.length,
      );
      final result = await _db.insertTransactions(transactions, batchId: batchId);

      _lastImportMessage = '${result.added} nuovi movimenti aggiunti, ${result.duplicates} già presenti';

      final detected = _detectFixedExpenses(transactions);
      for (final fe in detected) {
        await _db.upsertDetectedFixedExpense(fe);
      }

      await refresh();
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ImportResult> importFileWithProfile(String filePath, ImportProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final transactions = await Future(() => FlexibleParser.parse(filePath, profile));
      final batchId = await _db.createImportBatch(
        fileName: p.basename(filePath),
        profileName: profile.name,
        recordCount: transactions.length,
      );
      final result = await _db.insertTransactions(transactions, batchId: batchId);

      _lastImportMessage = '${result.added} nuovi movimenti aggiunti, ${result.duplicates} già presenti';

      final detected = _detectFixedExpenses(transactions);
      for (final fe in detected) {
        await _db.upsertDetectedFixedExpense(fe);
      }

      await refresh();
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveImportProfile(ImportProfile profile) async {
    if (profile.id != null) {
      await _db.updateImportProfile(profile);
    } else {
      await _db.insertImportProfile(profile);
    }
    await _loadImportProfiles();
    notifyListeners();
  }

  Future<void> deleteImportProfile(int id) async {
    await _db.deleteImportProfile(id);
    await _loadImportProfiles();
    notifyListeners();
  }

  List<FixedExpenseModel> _detectFixedExpenses(List<TransactionModel> newTransactions) {
    final allExpenses = newTransactions.where((t) => t.isExpense).toList();
    final grouped = <String, List<TransactionModel>>{};

    for (final tx in allExpenses) {
      final key = _normalizeDescription(tx.operation ?? tx.details ?? '');
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final detected = <FixedExpenseModel>[];

    for (final entry in grouped.entries) {
      final txs = entry.value;
      if (txs.length < 2) continue;

      txs.sort((a, b) => a.date.compareTo(b.date));

      final amounts = txs.map((t) => t.absAmount).toList();
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      final maxVariation = amounts.map((a) => (a - avgAmount).abs() / avgAmount).reduce((a, b) => a > b ? a : b);

      if (maxVariation > 0.05) continue; // importo stabile entro 5%

      final intervals = <int>[];
      for (int i = 1; i < txs.length; i++) {
        final d1 = DateTime.parse(txs[i - 1].date);
        final d2 = DateTime.parse(txs[i].date);
        intervals.add(d2.difference(d1).inDays);
      }

      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final frequency = _classifyFrequency(avgInterval);
      if (frequency == null) continue;

      detected.add(FixedExpenseModel(
        name: entry.key,
        amount: avgAmount,
        frequency: frequency,
        category: txs.first.category,
        confirmedByUser: false,
        isManual: false,
      ));
    }

    return detected;
  }

  String _normalizeDescription(String desc) {
    return desc
        .toLowerCase()
        .replaceAll(RegExp(r'\d{2}/\d{2}'), '')
        .replaceAll(RegExp(r'\d{4}'), '')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .take(3)
        .join(' ');
  }

  FixedExpenseFrequency? _classifyFrequency(double days) {
    if (days >= 6 && days <= 8) return FixedExpenseFrequency.weekly;
    if (days >= 25 && days <= 35) return FixedExpenseFrequency.monthly;
    if (days >= 350 && days <= 380) return FixedExpenseFrequency.yearly;
    return null;
  }

  // ── Health Score ──────────────────────────────────────────────

  int computeHealthScore() {
    if (_currentMonthlySummary == null || _currentMonthlySummary!.income == 0) return 50;

    double score = 0;

    // Tasso di risparmio (40 pt)
    final savingsRate = _currentMonthlySummary!.savings / _currentMonthlySummary!.income;
    score += (savingsRate.clamp(0, 0.5) / 0.5) * 40;

    // Anomalie spesa (30 pt)
    double anomalyPenalty = 0;
    for (final cat in _categorySummaries) {
      final avg = _categoryAverages[cat.category];
      if (avg != null && avg > 0) {
        final ratio = cat.total / avg;
        if (ratio > 1.3) anomalyPenalty += 5;
      }
    }
    score += (30 - anomalyPenalty).clamp(0, 30);

    // Trend risparmio (20 pt)
    if (_monthlySummaries.length >= 2) {
      final lastTwo = _monthlySummaries.reversed.take(2).toList();
      if (lastTwo[0].savings > lastTwo[1].savings) { score += 20; }
      else if (lastTwo[0].savings > 0) { score += 10; }
    } else {
      score += 10;
    }

    // Spese fisse confermate (10 pt)
    final confirmed = _fixedExpenses.where((s) => s.confirmedByUser).length;
    final total = _fixedExpenses.length;
    if (total == 0) {
      score += 10;
    } else {
      score += (confirmed / total) * 10;
    }

    return score.round().clamp(0, 100);
  }

  // ── Proiezione fine mese ──────────────────────────────────────

  double projectEndOfMonth() {
    if (_currentMonthlySummary == null) return 0;

    final now = DateTime.now();
    final startDay = _fiscalMonthStartDay <= 1 ? 1 : _fiscalMonthStartDay;

    // Calcola inizio e fine del periodo fiscale corrente
    final DateTime fiscalStart;
    final DateTime fiscalEnd;

    if (startDay <= 1) {
      // Mese solare normale
      fiscalStart = DateTime(now.year, now.month, 1);
      fiscalEnd   = DateTime(now.year, now.month + 1, 0); // ultimo giorno del mese
    } else if (now.day >= startDay) {
      // Siamo dopo il giorno di inizio → periodo iniziato questo mese
      fiscalStart = DateTime(now.year, now.month, startDay);
      fiscalEnd   = DateTime(now.year, now.month + 1, startDay - 1);
    } else {
      // Siamo prima del giorno di inizio → periodo iniziato il mese scorso
      fiscalStart = DateTime(now.year, now.month - 1, startDay);
      fiscalEnd   = DateTime(now.year, now.month, startDay - 1);
    }

    final daysInPeriod = fiscalEnd.difference(fiscalStart).inDays + 1;
    final daysPassed   = now.difference(fiscalStart).inDays + 1;
    final daysRemaining = (daysInPeriod - daysPassed).clamp(0, daysInPeriod);

    if (daysPassed <= 0) return 0;

    final dailyExpenses     = _currentMonthlySummary!.expenses / daysPassed;
    final projectedVariable = dailyExpenses * daysRemaining;

    final fixedAlreadyPaid = _totalMonthlyFixed * (daysPassed / daysInPeriod);
    final fixedRemaining   = _totalMonthlyFixed - fixedAlreadyPaid;

    return _currentMonthlySummary!.income
        - _currentMonthlySummary!.expenses
        - projectedVariable
        - fixedRemaining;
  }

  // ── Goals ─────────────────────────────────────────────────────

  Future<void> addGoal(GoalModel goal) async {
    await _db.insertGoal(goal);
    await _loadGoals();
    notifyListeners();
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _db.updateGoal(goal);
    await _loadGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(int id) async {
    await _db.deleteGoal(id);
    await _loadGoals();
    notifyListeners();
  }

  Duration estimateGoalDuration(double target) {
    if (_avgMonthlySavings <= 0) return const Duration(days: 365 * 99);
    final months = target / _avgMonthlySavings;
    return Duration(days: (months * 30.44).round());
  }

  // ── Fixed Expenses ────────────────────────────────────────────

  Future<List<FixedExpenseModel>> detectCandidates() async {
    final allTx = await _db.getTransactions(limit: 99999);
    final candidates = _detectFixedExpenses(allTx);
    // Escludi quelli già presenti nelle spese fisse (per nome normalizzato)
    final existingNames = _fixedExpenses.map((e) => e.name.toLowerCase()).toSet();
    return candidates.where((c) => !existingNames.contains(c.name.toLowerCase())).toList();
  }

  Future<void> addFixedExpense(FixedExpenseModel fe) async {
    await _db.insertFixedExpense(fe);
    await _loadFixedExpenses();
    notifyListeners();
  }

  Future<void> updateFixedExpense(FixedExpenseModel fe) async {
    await _db.updateFixedExpense(fe);
    await _loadFixedExpenses();
    notifyListeners();
  }

  Future<void> confirmFixedExpense(int id, bool confirmed) async {
    await _db.confirmFixedExpense(id, confirmed);
    await _loadFixedExpenses();
    notifyListeners();
  }

  Future<void> deleteFixedExpense(int id) async {
    await _db.deleteFixedExpense(id);
    await _loadFixedExpenses();
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────

  Future<void> setReferencePeriod(int months) async {
    _referencePeriod = months;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reference_period', months);
    await refresh();
  }

  Future<void> addAccount(AccountModel a) async {
    await _db.insertAccount(a);
    await _loadAccounts();
    notifyListeners();
  }

  Future<void> updateAccount(AccountModel a) async {
    await _db.updateAccount(a);
    await _loadAccounts();
    notifyListeners();
  }

  Future<void> deleteAccount(int id) async {
    await _db.deleteAccount(id);
    await _loadAccounts();
    notifyListeners();
  }

  Future<void> setFiscalMonthStartDay(int day) async {
    _fiscalMonthStartDay = day;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('fiscal_month_start_day', day);
    await refresh();
  }

  Future<void> setGeminiApiKey(String key) async {
    await _secureStorage.write(key: 'gemini_api_key', value: key);
    final prefs = await SharedPreferences.getInstance();
    _gemini.configure(
      key,
      agentModelId:    prefs.getString(GeminiModelSlot.agent.prefKey),
      analysisModelId: prefs.getString(GeminiModelSlot.analysis.prefKey),
      utilityModelId:  prefs.getString(GeminiModelSlot.utility.prefKey),
    );
    notifyListeners();
  }

  Future<void> setGeminiModel(GeminiModelSlot slot, String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(slot.prefKey, modelId);
    _gemini.setModel(slot, modelId);
    notifyListeners();
  }

  Future<String?> getGeminiApiKey() async {
    return _secureStorage.read(key: 'gemini_api_key');
  }

  // ── Custom API Keys ───────────────────────────────────────────

  Future<void> _loadCustomApiKeys() async {
    _customApiKeys = await _apiKeyStore.getAll();
  }

  Future<void> saveCustomApiKey(ApiKeyEntry entry) async {
    await _apiKeyStore.save(entry);
    await _loadCustomApiKeys();
    notifyListeners();
  }

  Future<void> deleteCustomApiKey(String id) async {
    await _apiKeyStore.delete(id);
    await _loadCustomApiKeys();
    notifyListeners();
  }

  Future<String?> getCustomApiKey(String name) => _apiKeyStore.getKey(name);

  // ── PIN ───────────────────────────────────────────────────────

  Future<bool> get isPinEnabled => _pin.isEnabled;
  Future<bool> verifyPin(String pin) => _pin.verify(pin);
  Future<void> setPin(String pin) => _pin.setPin(pin);
  Future<void> disablePin() => _pin.disable();

  // ── Filtered data ─────────────────────────────────────────────

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await refresh();
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _db.updateTransaction(tx);
    await refresh();
  }

  Future<void> deleteImportBatch(int id) async {
    await _db.deleteImportBatch(id);
    await refresh();
  }

  Future<List<TransactionModel>> searchTransactions({
    String? yearMonth,
    String? category,
    bool? onlyExpenses,
    bool? onlyIncome,
    String? search,
  }) async {
    return _db.getTransactions(
      yearMonth: yearMonth,
      category: category,
      onlyExpenses: onlyExpenses,
      onlyIncome: onlyIncome,
      search: search,
    );
  }

  Future<List<TransactionModel>> getTop10Expenses({String? yearMonth}) async {
    return _db.getTop10Expenses(yearMonth: yearMonth);
  }

  Future<List<CategorySummary>> getCategoriesForMonth(String yearMonth) async {
    return _db.getCategorySummary(yearMonth: yearMonth);
  }

  Future<String> getAiSummary() async {
    return _db.getAggregatedSummaryJson(months: _referencePeriod);
  }
}
