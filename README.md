# Logicash

App Android per la gestione delle finanze personali. Importa gli estratti conto direttamente dall'app di banking, analizza le spese, rileva spese fisse ricorrenti e ti aiuta a raggiungere i tuoi obiettivi di risparmio — con un assistente AI integrato (Gemini) dotato di tool calling.

## Funzionalità

### Dashboard
- **Health Score mensile** (0–100): punteggio calcolato su risparmio, anomalie, trend e copertura spese fisse
- Saldo del mese corrente (entrate / uscite / risparmiato)
- **Proiezione fine mese**: stima basata sul ritmo di spesa attuale (con logica mese fiscale)
- Alert intelligenti su anomalie e obiettivi
- AI insights strutturati (positivi / warning / consigli) con grafici inline

### Obiettivi & Simulatore
- Crea obiettivi con nome, importo target ed emoji
- Timeline automatica basata sulla media di risparmio storica
- Simulatore interattivo: modifica l'importo e vedi aggiornarsi la data di arrivo in tempo reale
- Più obiettivi in parallelo con progresso visivo

### Analisi Spese
- Breakdown per categoria con grafico a torta
- Trend mensile per categoria (barre entrate/uscite ultimi 6 mesi)
- **Rilevamento anomalie**: avviso quando una categoria supera del 30% la media
- Confronto mese corrente vs media storica
- **Heatmap comportamentale**: pattern di spesa per giorno della settimana
- Top 10 spese singole

### Spese Fisse & Ricorrenti
- Rilevamento automatico di pagamenti periodici (settimanali / mensili / annuali)
- Candidati da confermare, con selezione multipla
- Costo mensile e **costo annualizzato**
- Totale fisso mensile impegnato
- Sostituisce la vecchia sezione "Abbonamenti"

### Movimenti
- Lista completa con ricerca e filtri (mese, categoria, tipo)
- Import file `.xlsx`/`.csv` con deduplicazione automatica (SHA-256)

### Assistente AI (Gemini)
- Chat in linguaggio naturale sui propri dati
- **Tool calling**: l'agente può creare/eliminare obiettivi e spese fisse, fare previsioni, simulazioni e generare grafici inline
- Consigli personalizzati mensili e report narrativo
- Categorizzazione automatica di transazioni ambigue
- Auto-detect del profilo di import per file di banche diverse

### Sicurezza
- Blocco app con **PIN a 4 cifre** (keypad + flusso di setup)
- Tracciamento **token/costi AI** per modello

## Import dati

L'app accetta il file `.xlsx` esportato dall'app Intesa Sanpaolo (profilo predefinito) e, tramite profili configurabili, file `.xlsx`/`.csv` di altre banche. Il setup profilo supporta l'auto-detect AI. Ad ogni import:
- Le nuove transazioni vengono aggiunte allo storico
- I duplicati (periodi sovrapposti) vengono ignorati automaticamente
- Vengono rilevati i candidati di spesa fissa ricorrente
- Un badge mostra quanti record sono stati aggiunti

## Setup

### Requisiti
- Android 8.0+
- Flutter 3.44+ / Dart SDK 3.12+

### Installazione sviluppo
```bash
git clone <repo>
cd logicash
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## Sicurezza
- Il database SQLite locale è attualmente **in chiaro** (la cifratura AES-256-GCM è un obiettivo futuro, non ancora implementato)
- Il **PIN** di blocco app è salvato nel **Keystore Android** tramite `flutter_secure_storage` (con flag di abilitazione in `shared_preferences`)
- I dati inviati all'AI Gemini sono sempre **aggregati e anonimizzati** (nessuna transazione grezza)

## Tech Stack
- **Flutter** 3.44 / Dart
- **SQLite** (sqflite) — storage locale
- **Gemini Flash** (`google_generative_ai`) — AI insights, chat e tool calling
- **archive** — parsing .xlsx come ZIP (XML manuale)
- **fl_chart** — grafici (torta, barre, linee)
- **file_picker** — selezione file
- **provider** — state management
- **shared_preferences** — preferenze e tracking token AI
- **flutter_secure_storage** — PIN
- **google_fonts** (Inter), **flutter_animate**, **percent_indicator**

## Changelog

### v1.0.0 (in sviluppo)
- Struttura progetto feature-first con `AppProvider` (Provider)
- Setup tema premium dark (Material 3, Inter)
- Database SQLite v3 con 7 tabelle + indici (no cifratura)
- Parser .xlsx Intesa Sanpaolo (archive + XML manuale) + `FlexibleParser` multi-banca
- Import con deduplicazione SHA-256 (xlsx/csv)
- Profili import configurabili con auto-detect AI
- Dashboard con Health Score, proiezione e AI insights
- Analisi spese con anomalie e heatmap
- Rilevamento spese fisse ricorrenti (sostituisce Abbonamenti)
- Obiettivi con simulatore interattivo
- Chat AI con Gemini Flash + tool calling e grafici inline
- Blocco app con PIN (secure storage)
- Tracciamento token/costi AI per modello
