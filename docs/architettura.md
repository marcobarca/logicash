# Architettura Logicash

## Pattern architetturale

L'app segue un'architettura a feature-first con **Provider** come state management.

```
UI (Screens/Widgets)
      ↓
   AppProvider (stato + logica business)
      ↓
   Services (database, parser, AI, pin, usage)
      ↓
   Storage (SQLite in chiaro / SecureStorage per PIN / SharedPreferences)
```

## Layer

### UI Layer (`lib/features/*/`)
Ogni feature ha la propria cartella con:
- `*_screen.dart` — schermata principale
- `widgets/` — widget specifici della feature

Le schermate ascoltano `AppProvider` tramite `Consumer` o `context.watch`.

### State Layer (`lib/providers/app_provider.dart`)
Un unico **`AppProvider extends ChangeNotifier`** orchestra tutti i service e espone lo stato globale.

Stato esposto (getter principali):
- `isLoading`, `currentMonth`, `currentFiscalMonth`, `referencePeriod`, `fiscalMonthStartDay`
- `accounts`, `totalBalance`
- `monthlySummaries`, `currentMonthlySummary`, `categorySummaries`, `categoryAverages`, `weekdaySpending`
- `transactions` (ultime 50), `goals`, `fixedExpenses`, `totalMonthlyFixed`, `avgMonthlySavings`
- `importProfiles`, `availableMonths`, `gemini` (service diretto)
- `lastImportMessage`

Metodi pubblici principali:
- **Init/refresh:** `init()`, `refresh()`
- **Import:** `importFile(path)` (ExcelParser Intesa), `importFileWithProfile(path, profile)` (FlexibleParser), `saveImportProfile`, `deleteImportProfile`
- **Health/Proiezione:** `computeHealthScore()` (0-100), `projectEndOfMonth()` (con logica mese fiscale)
- **Goals:** `addGoal`, `updateGoal`, `deleteGoal`, `estimateGoalDuration(target)`
- **Fixed expenses:** `detectCandidates()`, `addFixedExpense`, `updateFixedExpense`, `confirmFixedExpense(id, bool)`, `deleteFixedExpense`
- **Settings/conti:** `setReferencePeriod(months)`, `setFiscalMonthStartDay(day)`, `addAccount`, `updateAccount`, `deleteAccount`, `setGeminiApiKey`, `setGeminiModel`
- **PIN:** `isPinEnabled`, `verifyPin`, `setPin`, `disablePin`
- **Query:** `searchTransactions(...)`, `getTop10Expenses(yearMonth?)`, `getCategoriesForMonth(yearMonth)`, `getAiSummary()` (JSON aggregato per AI)

Il rilevamento delle spese fisse ricorrenti (`_detectFixedExpenses`) e la classificazione della frequenza (`_classifyFrequency`) vivono qui, non in un service dedicato.

### Service Layer (`lib/core/`)
- **`database/db_helper.dart`** — `DbHelper` (singleton). Init SQLite v3, migrazioni, query. 7 tabelle.
- **`excel/excel_parser.dart`** — parser .xlsx Intesa Sanpaolo (ZIP via `archive` + XML manuale) → `List<TransactionModel>`
- **`import/flexible_parser.dart`** — parser generico multi-banca via `ImportProfile` (xlsx/csv, encoding utf-8/latin1)
- **`gemini/gemini_service.dart`** — chat, `agentChat` (tool calling con 10 `FunctionDeclaration`), insights, report, `detectImportProfile`, `suggestCategory`, `testConnection`, modelli/prezzi
- **`auth/pin_service.dart`** — PIN 4 cifre (`FlutterSecureStorage` + flag in `SharedPreferences`)
- **`charts/chart_spec.dart`** — `ChartSpec`/`ChartDataPoint`: descrittore grafici generato dall'AI
- **`ai_usage/usage_tracker.dart`** — tracker token/costi AI per modello (`SharedPreferences`)

> La cifratura AES-256-GCM del database **non è implementata**: il DB è aperto in chiaro con `openDatabase`. Non esiste `crypto_service.dart`.

## Flusso import

```
Utente seleziona .xlsx/.csv
      ↓
ExcelParser.parse()  oppure  FlexibleParser.parse(path, profile)
      ↓  → List<TransactionModel>
Per ogni transazione: id = SHA-256('$date|$details|${amount.toStringAsFixed(2)}')
      ↓
DbHelper.insertTransactions()  → transazione: SELECT id, insert solo se assente
      ↓  → ImportResult(added, duplicates)
AppProvider._detectFixedExpenses()  → upsert candidati ricorrenti
      ↓
notifyListeners() → UI mostra badge con risultato import
```

## Flusso AI

```
Utente apre Chat o Dashboard
      ↓
DbHelper.getAggregatedSummaryJson(months:) → JSON con totali per categoria/mese
(MAI transazioni grezze con dati sensibili)
      ↓
GeminiService.query(summary, message)            → risposta testo (insight/report)
GeminiService.agentChat(message, summary)        → tool calling: FunctionDeclaration
      ↓                                            (crea/elimina obiettivi e spese fisse,
  AppProvider esegue l'azione                     previsione, simulazione, health_score,
      ↓                                            genera_grafico → ChartSpec)
UI aggiorna chat / insight card / grafici inline
```

## Database Schema

Versione DB: `3` (`_onUpgrade` crea `accounts` a v2 e `import_profiles` + profilo Intesa predefinito a v3).

```sql
CREATE TABLE transactions (
  id          TEXT PRIMARY KEY,   -- SHA-256
  date        TEXT NOT NULL,      -- ISO 8601 (YYYY-MM-DD)
  year_month  TEXT NOT NULL,      -- YYYY-MM (per query veloci)
  operation   TEXT,               -- descrizione breve
  details     TEXT,               -- descrizione completa
  account     TEXT,               -- conto o carta
  category    TEXT,               -- categoria banca
  currency    TEXT DEFAULT 'EUR',
  amount      REAL NOT NULL       -- negativo=uscita, positivo=entrata
);
CREATE INDEX idx_tx_year_month ON transactions(year_month);
CREATE INDEX idx_tx_category   ON transactions(category);
CREATE INDEX idx_tx_amount     ON transactions(amount);

CREATE TABLE goals (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT NOT NULL,
  target      REAL NOT NULL,
  created_at  TEXT NOT NULL,
  emoji       TEXT
);

CREATE TABLE fixed_expenses (          -- sostituisce subscriptions
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  name              TEXT NOT NULL,
  amount            REAL NOT NULL,
  frequency         INTEGER NOT NULL DEFAULT 1,  -- 0=settimanale, 1=mensile, 2=annuale
  category          TEXT,
  emoji             TEXT,
  confirmed_by_user INTEGER NOT NULL DEFAULT 0,
  is_manual         INTEGER NOT NULL DEFAULT 0   -- 0=rilevato, 1=inserito a mano
);

CREATE TABLE subscriptions (           -- [LEGACY] creata ma non letta/scritta
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  name              TEXT NOT NULL,
  amount            REAL NOT NULL,
  frequency         INTEGER NOT NULL,
  confirmed_by_user INTEGER DEFAULT 0,
  category          TEXT,
  last_seen         TEXT NOT NULL
);

CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE accounts (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  name    TEXT NOT NULL,
  balance REAL NOT NULL DEFAULT 0,
  emoji   TEXT DEFAULT '🏦'
);

CREATE TABLE import_profiles (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  name                TEXT NOT NULL,
  file_type           TEXT NOT NULL DEFAULT 'xlsx',   -- xlsx|csv
  data_start_row      INTEGER NOT NULL DEFAULT 0,     -- 0-based
  date_col            INTEGER NOT NULL DEFAULT 0,
  desc_col            INTEGER NOT NULL DEFAULT 1,
  amount_col          INTEGER NOT NULL DEFAULT 2,
  cat_col             INTEGER NOT NULL DEFAULT -1,    -- -1 = assente
  date_type           TEXT NOT NULL DEFAULT 'string', -- serial|string
  date_format         TEXT NOT NULL DEFAULT 'dd/MM/yyyy',
  decimal_sep         TEXT NOT NULL DEFAULT '.',
  negative_is_expense INTEGER NOT NULL DEFAULT 1,
  csv_delimiter       TEXT NOT NULL DEFAULT ';',
  encoding            TEXT NOT NULL DEFAULT 'utf-8',  -- utf-8|latin1
  created_at          TEXT NOT NULL
);
```

## Rilevamento spese fisse

L'algoritmo (`AppProvider._detectFixedExpenses`) scorre le transazioni raggruppate per descrizione normalizzata (prime 3 parole):
1. Filtra gruppi con almeno 2 occorrenze
2. Calcola intervallo medio tra date consecutive
3. Verifica che la variazione dell'importo sia < 5%
4. Classifica la frequenza (`_classifyFrequency`): settimanale (≈6-8 gg), mensile (≈25-35 gg), annuale (≈350-380 gg)
5. Upsert in `fixed_expenses` con `is_manual = 0`; l'utente conferma via `confirmFixedExpense(id, true)`
6. `FixedExpenseModel.monthlyAmount` / `yearlyAmount` derivano la frequenza

## Health Score

Il punteggio (0-100) è calcolato mensilmente in `AppProvider.computeHealthScore()`:

| Componente | Peso | Logica |
|---|---|---|
| Tasso di risparmio | 40% | risparmio/entrate → scala 0-40 |
| Anomalie spesa | 30% | -5 pt per ogni categoria >30% sopra la media |
| Trend risparmio | 20% | miglioramento vs mese precedente |
| Copertura spese fisse | 10% | spese fisse confermate / rilevate |
