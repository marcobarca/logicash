# CLAUDE.md — Logicash

## Progetto
App Flutter per la gestione delle finanze personali. Importa estratti conto da file `.xlsx`/`.csv` (formato Intesa Sanpaolo e altri bancari configurabili), li archivia in SQLite e offre analisi, previsioni e un assistente AI (Gemini) con tool calling.

## Comandi utili
```bash
flutter run                        # avvia su dispositivo connesso
flutter run -d <device-id>         # specifica dispositivo
flutter build apk --release        # build APK release
flutter pub get                    # installa dipendenze
flutter pub upgrade                # aggiorna dipendenze
flutter analyze                    # analisi statica
flutter test                       # esegue i test
```

## Struttura
```
lib/
  main.dart                        # entry point, binding, overlay UI, portrait lock
  app.dart                         # root widget, AppProvider, MaterialApp, MainShell
                                   #   (bottom nav 4 tab + FAB chat), route nominali
  providers/
    app_provider.dart              # AppProvider (ChangeNotifier): stato globale,
                                   #   orchestra i service, logica business
  core/
    database/
      db_helper.dart               # SQLite v3, 7 tabelle, query
      models/
        transaction_model.dart     # id SHA-256, isExpense/isIncome/absAmount
        goal_model.dart            # emoji, copyWith
        fixed_expense_model.dart   # enum FixedExpenseFrequency, monthlyAmount/yearlyAmount
        account_model.dart         # balance, emoji
        import_profile_model.dart  # profilo import bancario (xlsx/csv),
                                   #   factory statico intesaSanpaolo
        subscription_model.dart    # [LEGACY] tabella inesistente nel flusso, inutilizzato
    excel/
      excel_parser.dart            # parser .xlsx Intesa (archive + XML manuale)
    import/
      flexible_parser.dart         # parser generico multi-banca via ImportProfile (xlsx/csv)
    gemini/
      gemini_service.dart          # Gemini: chat, agentChat (tool calling), insights,
                                   #   report, detectImportProfile, suggestCategory, costi
    auth/
      pin_service.dart             # PIN 4 cifre (secure storage + shared_prefs)
    charts/
      chart_spec.dart              # ChartSpec/ChartDataPoint: descrittore grafici per AI
    ai_usage/
      usage_tracker.dart           # tracker token/costi AI per modello
  features/
    dashboard/                     # Home: health score, proiezione, summary, AI insights
    goals/                         # Obiettivi + simulatore interattivo
    expenses/                      # Analisi spese + anomalie + heatmap
    fixed_expenses/                # Spese fisse + candidati ricorrenti (sostituisce subscriptions)
    transactions/                  # Lista movimenti + ricerca/filtri + import
    chat/                          # Chat AI con tool calling + grafici inline
    settings/                      # API key, modello, PIN, conti, periodo, mese fiscale, costi AI
    auth/                          # PinScreen (keypad) + PinSetupScreen
    import/                        # ProfileSetupScreen (auto-detect AI profilo import)
    subscriptions/                 # [DEPRECATO] re-export di fixed_expenses
  shared/
    theme/
      app_theme.dart               # AppColors + AppTheme.dark (Material3, Inter)
    widgets/
      lc_card.dart                 # Card riutilizzabile
      chart_widget.dart            # renderizza ChartSpec (bar/line/pie)
```

## Navigazione
- **Bottom nav (MainShell):** Home, Spese, Obiettivi, Spese Fisse + FAB Chat
- **Route nominali:** `/home`, `/transactions`, `/settings`, `/chat`
- Le altre schermate (CandidatesScreen, ProfileSetup, Pin*) sono navigate via `MaterialPageRoute`

## Formato Excel banca (Intesa Sanpaolo)
- Il parser ignora tutte le righe con numero < 18 (metadata/intestazioni banca)
- I dati transazioni iniziano dalla riga 18 (1-based); le righe senza data o importo validi vengono saltate
- Colonne: A=Data (seriale Excel), B=Operazione, C=Dettagli, D=Conto, F=Categoria, G=Valuta, H=Importo
- La data seriale Excel si converte con: `DateTime(1899, 12, 30).add(Duration(days: serial))`
- Importo negativo = uscita, positivo = entrata
- Il `.xlsx` è letto come ZIP via `archive` (parsing manuale di `sharedStrings.xml` + `sheet1.xml`), più robusto dei file con immagini

## Import multi-banca
- `ExcelParser` è hardcoded sul formato Intesa Sanpaolo
- `FlexibleParser` + `ImportProfile` supportano formati generici (xlsx/csv): colonne, `dateType` (serial/string), `date_format`, `decimal_sep`, `csv_delimiter`, `encoding` (utf-8/latin1)
- `GeminiService.detectImportProfile` analizza un'anteprima del file e propone un profilo
- I profili sono salvati nella tabella `import_profiles`; il profilo `Intesa Sanpaolo` è predefinito

## Deduplicazione import
Ogni transazione ha un `id = SHA-256('$dateIso|$details|${amount.toStringAsFixed(2)}')`.
L'insert NON usa `INSERT OR IGNORE`: dentro una transazione verifica `SELECT ... WHERE id = ?` e inserisce solo se assente. Restituisce `ImportResult(added, duplicates)`.

## Design system
- Tema: dark premium (stile Revolut/N26), Material 3
- Background: `#0A0E1A`
- Card: `#141828`
- Primary accent: `#6C63FF`
- Positivo (entrate/risparmio): `#00D4AA`
- Negativo (uscite/alert): `#FF6B6B`
- Warning: `#FFB347`
- Font: Inter (Google Fonts)

## Dipendenze principali
| Package | Uso |
|---|---|
| `sqflite` | Database SQLite locale |
| `path` / `path_provider` | Path del database |
| `archive` | Lettura .xlsx come ZIP (parser XML manuale) — sostituisce `excel` |
| `flutter_secure_storage` | Salvataggio sicuro del PIN |
| `crypto` | SHA-256 per deduplicazione |
| `file_picker` | Selezione file dal telefono |
| `fl_chart` | Grafici (torta, barre, linee) |
| `google_generative_ai` | Gemini Flash API |
| `google_fonts` | Font Inter |
| `provider` | State management |
| `intl` | Formattazione date e valute |
| `shared_preferences` | Preferenze (periodo, mese fiscale, modello AI, flag PIN, token AI) |
| `flutter_animate` | Animazioni UI |
| `percent_indicator` | Anello health score |

> Note: `excel` NON è più una dipendenza (rimpiazzato da `archive`). `encrypt`, `shimmer` e `uuid` sono presenti in `pubspec.yaml` ma non risultano utilizzati nel codice.

## Funzionalità
1. **Dashboard** — Health Score (0-100), saldo mese, proiezione fine mese, AI insights, alert anomalie
2. **Obiettivi** — Crea obiettivi con timeline automatica, simulatore interattivo, emoji
3. **Analisi Spese** — Categorie, trend, anomalie, heatmap giorno settimana, top 10
4. **Spese Fisse** — Rilevamento automatico ricorrenti, candidati, costo mensile/annualizzato, conferma utente (sostituisce le vecchie "Abbonamenti")
5. **Movimenti** — Lista completa, ricerca, filtri, import xlsx/csv
6. **Chat AI** — Chat in linguaggio naturale con tool calling (crea/elimina obiettivi e spese fisse, previsioni, simulazioni, grafici inline via ChartSpec)
7. **Import profili** — Setup profilo import multi-banca con auto-detect AI
8. **Settings** — API key Gemini, selezione modello, PIN, conti, periodo riferimento (3/6/12 mesi), mese fiscale, costi AI
9. **Sicurezza PIN** — Blocco app con PIN 4 cifre (keypad + setup)

> Le entrate non hanno schermata dedicata: sono mostrate nei riepiloghi mensili (Dashboard, bar chart entrate/uscite).

## Note importanti
- Il database SQLite è aperto **in chiaro**: la cifratura AES-256-GCM NON è implementata (la dipendenza `encrypt` è dichiarata ma inutilizzata). Obiettivo futuro.
- Il **PIN** (4 cifre) è salvato in `flutter_secure_storage` (Keystore Android) con flag di abilitazione in `shared_preferences`
- I dati inviati a Gemini sono sempre aggregati/riassunti (`getAggregatedSummaryJson`), mai transazioni grezze
- Il tracciamento token/costi AI è in `shared_preferences` (`UsageTracker`)
- La cartella `assets/` contiene eventuali font e lottie animations
- `subscription_model.dart` e la tabella `subscriptions` sono legacy/inutilizzati: la logica è migrata in `fixed_expenses`
