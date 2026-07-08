import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/transaction_model.dart';
import 'models/goal_model.dart';
import 'models/fixed_expense_model.dart';
import 'models/account_model.dart';
import 'models/import_profile_model.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'logicash.db');
    return openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts (
          id      INTEGER PRIMARY KEY AUTOINCREMENT,
          name    TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0,
          emoji   TEXT DEFAULT '🏦'
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute(_importProfilesSchema);
      // Inserisce il profilo Intesa Sanpaolo predefinito
      await db.insert('import_profiles', ImportProfile.intesaSanpaolo.toMap());
    }
  }

  static const _importProfilesSchema = '''
    CREATE TABLE IF NOT EXISTS import_profiles (
      id                INTEGER PRIMARY KEY AUTOINCREMENT,
      name              TEXT NOT NULL,
      file_type         TEXT NOT NULL DEFAULT 'xlsx',
      data_start_row    INTEGER NOT NULL DEFAULT 0,
      date_col          INTEGER NOT NULL DEFAULT 0,
      desc_col          INTEGER NOT NULL DEFAULT 1,
      amount_col        INTEGER NOT NULL DEFAULT 2,
      cat_col           INTEGER NOT NULL DEFAULT -1,
      date_type         TEXT NOT NULL DEFAULT 'string',
      date_format       TEXT NOT NULL DEFAULT 'dd/MM/yyyy',
      decimal_sep       TEXT NOT NULL DEFAULT '.',
      negative_is_expense INTEGER NOT NULL DEFAULT 1,
      csv_delimiter     TEXT NOT NULL DEFAULT ';',
      encoding          TEXT NOT NULL DEFAULT 'utf-8',
      created_at        TEXT NOT NULL
    )
  ''';

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id          TEXT PRIMARY KEY,
        date        TEXT NOT NULL,
        year_month  TEXT NOT NULL,
        operation   TEXT,
        details     TEXT,
        account     TEXT,
        category    TEXT,
        currency    TEXT DEFAULT 'EUR',
        amount      REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        target      REAL NOT NULL,
        created_at  TEXT NOT NULL,
        emoji       TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        name              TEXT NOT NULL,
        amount            REAL NOT NULL,
        frequency         INTEGER NOT NULL,
        confirmed_by_user INTEGER DEFAULT 0,
        category          TEXT,
        last_seen         TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fixed_expenses (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        name              TEXT NOT NULL,
        amount            REAL NOT NULL,
        frequency         INTEGER NOT NULL DEFAULT 1,
        category          TEXT,
        emoji             TEXT,
        confirmed_by_user INTEGER NOT NULL DEFAULT 0,
        is_manual         INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        name    TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        emoji   TEXT DEFAULT '🏦'
      )
    ''');

    await db.execute(_importProfilesSchema);
    await db.insert('import_profiles', ImportProfile.intesaSanpaolo.toMap());
    await db.execute('CREATE INDEX idx_tx_year_month ON transactions(year_month)');
    await db.execute('CREATE INDEX idx_tx_category ON transactions(category)');
    await db.execute('CREATE INDEX idx_tx_amount ON transactions(amount)');
  }

  // ── Transactions ──────────────────────────────────────────────

  Future<ImportResult> insertTransactions(List<TransactionModel> txs) async {
    final database = await db;
    int added = 0;
    int duplicates = 0;

    await database.transaction((txn) async {
      for (final tx in txs) {
        final existing = await txn.query('transactions', where: 'id = ?', whereArgs: [tx.id], limit: 1);
        if (existing.isEmpty) {
          await txn.insert('transactions', tx.toMap());
          added++;
        } else {
          duplicates++;
        }
      }
    });

    return ImportResult(added: added, duplicates: duplicates);
  }

  Future<void> deleteTransaction(String id) async {
    final database = await db;
    await database.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    final database = await db;
    await database.update('transactions', tx.toMap(), where: 'id = ?', whereArgs: [tx.id]);
  }

  Future<List<TransactionModel>> getTransactions({
    String? yearMonth,
    String? category,
    bool? onlyExpenses,
    bool? onlyIncome,
    String? search,
    int? limit,
  }) async {
    final database = await db;
    final where = <String>[];
    final args = <dynamic>[];

    if (yearMonth != null) { where.add('year_month = ?'); args.add(yearMonth); }
    if (category != null) { where.add('category = ?'); args.add(category); }
    if (onlyExpenses == true) { where.add('amount < 0'); }
    if (onlyIncome == true) { where.add('amount > 0'); }
    if (search != null && search.isNotEmpty) {
      where.add('(operation LIKE ? OR details LIKE ? OR category LIKE ?)');
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }

    final maps = await database.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<String>> getAvailableMonths() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT DISTINCT year_month FROM transactions ORDER BY year_month DESC',
    );
    return result.map((r) => r['year_month'] as String).toList();
  }

  Future<MonthlySummary> getMonthlySummary(String yearMonth) async {
    final database = await db;
    final result = await database.rawQuery('''
      SELECT
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as expenses
      FROM transactions WHERE year_month = ?
    ''', [yearMonth]);

    final income = (result.first['income'] as num?)?.toDouble() ?? 0;
    final expenses = (result.first['expenses'] as num?)?.toDouble() ?? 0;
    return MonthlySummary(yearMonth: yearMonth, income: income, expenses: expenses);
  }

  Future<List<MonthlySummary>> getMonthlySummaries({int months = 12}) async {
    final database = await db;
    final result = await database.rawQuery('''
      SELECT year_month,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as expenses
      FROM transactions
      GROUP BY year_month
      ORDER BY year_month DESC
      LIMIT ?
    ''', [months]);

    return result.map((r) => MonthlySummary(
      yearMonth: r['year_month'] as String,
      income: (r['income'] as num?)?.toDouble() ?? 0,
      expenses: (r['expenses'] as num?)?.toDouble() ?? 0,
    )).toList().reversed.toList();
  }

  Future<List<CategorySummary>> getCategorySummary({String? yearMonth, int? months}) async {
    final database = await db;
    String where = 'amount < 0';
    final args = <dynamic>[];

    if (yearMonth != null) {
      where += ' AND year_month = ?';
      args.add(yearMonth);
    } else if (months != null) {
      final allMonths = await getAvailableMonths();
      final recent = allMonths.take(months).toList();
      if (recent.isNotEmpty) {
        where += ' AND year_month IN (${recent.map((_) => '?').join(',')})';
        args.addAll(recent);
      }
    }

    final result = await database.rawQuery('''
      SELECT category, SUM(ABS(amount)) as total, COUNT(*) as count
      FROM transactions
      WHERE $where AND category IS NOT NULL
      GROUP BY category
      ORDER BY total DESC
    ''', args);

    return result.map((r) => CategorySummary(
      category: r['category'] as String,
      total: (r['total'] as num).toDouble(),
      count: (r['count'] as num).toInt(),
    )).toList();
  }

  Future<Map<int, double>> getSpendingByWeekday({int months = 3}) async {
    final database = await db;
    final allMonths = await getAvailableMonths();
    final recent = allMonths.take(months).toList();
    if (recent.isEmpty) return {};

    final placeholders = recent.map((_) => '?').join(',');
    final result = await database.rawQuery('''
      SELECT strftime('%w', date) as weekday, SUM(ABS(amount)) as total
      FROM transactions
      WHERE amount < 0 AND year_month IN ($placeholders)
      GROUP BY weekday
    ''', recent);

    return {for (final r in result) int.parse(r['weekday'] as String): (r['total'] as num).toDouble()};
  }

  Future<double> getAverageMonthlySavings({int months = 6}) async {
    final summaries = await getMonthlySummaries(months: months);
    if (summaries.isEmpty) return 0;
    final total = summaries.fold<double>(0, (sum, s) => sum + s.savings);
    return total / summaries.length;
  }

  Future<List<TransactionModel>> getTop10Expenses({String? yearMonth}) async {
    final database = await db;
    final where = yearMonth != null ? 'WHERE amount < 0 AND year_month = ?' : 'WHERE amount < 0';
    final args = yearMonth != null ? [yearMonth] : null;

    final maps = await database.rawQuery('''
      SELECT * FROM transactions $where ORDER BY amount ASC LIMIT 10
    ''', args);
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<Map<String, double>> getCategoryAverages({int months = 6}) async {
    final database = await db;
    final allMonths = await getAvailableMonths();
    final recent = allMonths.take(months).toList();
    if (recent.isEmpty) return {};

    final placeholders = recent.map((_) => '?').join(',');
    final result = await database.rawQuery('''
      SELECT category, AVG(monthly_total) as avg_total
      FROM (
        SELECT year_month, category, SUM(ABS(amount)) as monthly_total
        FROM transactions
        WHERE amount < 0 AND year_month IN ($placeholders) AND category IS NOT NULL
        GROUP BY year_month, category
      )
      GROUP BY category
    ''', recent);

    return {for (final r in result) r['category'] as String: (r['avg_total'] as num).toDouble()};
  }

  Future<String> getAggregatedSummaryJson({int months = 6}) async {
    final summaries = await getMonthlySummaries(months: months);
    final categories = await getCategorySummary(months: months);
    final avgSavings = await getAverageMonthlySavings(months: months);

    final buffer = StringBuffer();
    buffer.writeln('{"periodoMesi":$months,');
    buffer.writeln('"risparmioMedioMensile":${avgSavings.toStringAsFixed(2)},');
    buffer.writeln('"mesi":[');
    for (int i = 0; i < summaries.length; i++) {
      final s = summaries[i];
      buffer.write('{"mese":"${s.yearMonth}","entrate":${s.income.toStringAsFixed(2)},"uscite":${s.expenses.toStringAsFixed(2)},"risparmio":${s.savings.toStringAsFixed(2)}}');
      if (i < summaries.length - 1) buffer.write(',');
    }
    buffer.writeln('],');
    buffer.writeln('"categorie":[');
    for (int i = 0; i < categories.length; i++) {
      final c = categories[i];
      buffer.write('{"categoria":"${c.category}","totale":${c.total.toStringAsFixed(2)},"transazioni":${c.count}}');
      if (i < categories.length - 1) buffer.write(',');
    }
    buffer.writeln(']}');
    return buffer.toString();
  }

  // ── Goals ─────────────────────────────────────────────────────

  Future<int> insertGoal(GoalModel goal) async {
    final database = await db;
    return database.insert('goals', goal.toMap());
  }

  Future<List<GoalModel>> getGoals() async {
    final database = await db;
    final maps = await database.query('goals', orderBy: 'created_at DESC');
    return maps.map(GoalModel.fromMap).toList();
  }

  Future<void> updateGoal(GoalModel goal) async {
    final database = await db;
    await database.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteGoal(int id) async {
    final database = await db;
    await database.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // ── Fixed Expenses ────────────────────────────────────────────

  Future<int> insertFixedExpense(FixedExpenseModel fe) async {
    final database = await db;
    return database.insert('fixed_expenses', fe.toMap());
  }

  Future<List<FixedExpenseModel>> getFixedExpenses({bool? confirmedOnly}) async {
    final database = await db;
    final where = confirmedOnly == true ? 'confirmed_by_user = 1' : null;
    final maps = await database.query('fixed_expenses', where: where, orderBy: 'is_manual DESC, amount DESC');
    return maps.map(FixedExpenseModel.fromMap).toList();
  }

  Future<void> upsertDetectedFixedExpense(FixedExpenseModel fe) async {
    final database = await db;
    final existing = await database.query('fixed_expenses',
        where: 'name = ? AND is_manual = 0', whereArgs: [fe.name], limit: 1);
    if (existing.isEmpty) {
      await database.insert('fixed_expenses', fe.toMap());
    } else {
      await database.update('fixed_expenses', {'amount': fe.amount},
          where: 'name = ? AND is_manual = 0', whereArgs: [fe.name]);
    }
  }

  Future<void> updateFixedExpense(FixedExpenseModel fe) async {
    final database = await db;
    await database.update('fixed_expenses', fe.toMap(), where: 'id = ?', whereArgs: [fe.id]);
  }

  Future<void> confirmFixedExpense(int id, bool confirmed) async {
    final database = await db;
    await database.update('fixed_expenses', {'confirmed_by_user': confirmed ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteFixedExpense(int id) async {
    final database = await db;
    await database.delete('fixed_expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalMonthlyFixed() async {
    final list = await getFixedExpenses(confirmedOnly: true);
    return list.fold<double>(0.0, (sum, fe) => sum + fe.monthlyAmount);
  }

  // ── Settings ──────────────────────────────────────────────────

  Future<void> setSetting(String key, String value) async {
    final database = await db;
    await database.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final database = await db;
    final result = await database.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  // ── Accounts ──────────────────────────────────────────────────

  Future<List<AccountModel>> getAccounts() async {
    final database = await db;
    final rows = await database.query('accounts', orderBy: 'id ASC');
    return rows.map(AccountModel.fromMap).toList();
  }

  Future<int> insertAccount(AccountModel a) async {
    final database = await db;
    return database.insert('accounts', a.toMap());
  }

  Future<void> updateAccount(AccountModel a) async {
    final database = await db;
    await database.update('accounts', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> deleteAccount(int id) async {
    final database = await db;
    await database.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalBalance() async {
    final list = await getAccounts();
    return list.fold<double>(0.0, (s, a) => s + a.balance);
  }

  // ── Import Profiles ───────────────────────────────────────────

  Future<List<ImportProfile>> getImportProfiles() async {
    final database = await db;
    final rows = await database.query('import_profiles', orderBy: 'name ASC');
    return rows.map(ImportProfile.fromMap).toList();
  }

  Future<int> insertImportProfile(ImportProfile p) async {
    final database = await db;
    return database.insert('import_profiles', p.toMap());
  }

  Future<void> updateImportProfile(ImportProfile p) async {
    final database = await db;
    await database.update('import_profiles', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deleteImportProfile(int id) async {
    final database = await db;
    await database.delete('import_profiles', where: 'id = ?', whereArgs: [id]);
  }
}

class ImportResult {
  final int added;
  final int duplicates;
  const ImportResult({required this.added, required this.duplicates});
}

class MonthlySummary {
  final String yearMonth;
  final double income;
  final double expenses;
  const MonthlySummary({required this.yearMonth, required this.income, required this.expenses});
  double get savings => income - expenses;
}

class CategorySummary {
  final String category;
  final double total;
  final int count;
  const CategorySummary({required this.category, required this.total, required this.count});
}
