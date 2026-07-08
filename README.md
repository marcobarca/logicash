<div align="center">

# Logicash

**Gestione finanze personali con AI integrata — per Android**

[![GitHub release](https://img.shields.io/github/v/release/marcobarca/logicash?style=flat-square&color=6C63FF)](https://github.com/marcobarca/logicash/releases/latest)
[![Platform](https://img.shields.io/badge/platform-Android%208%2B-3DDC84?style=flat-square&logo=android&logoColor=white)](https://github.com/marcobarca/logicash/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-54C5F8?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)

Importa i tuoi estratti conto, analizza le spese, tieni traccia degli obiettivi di risparmio e parla con un assistente AI che conosce i tuoi dati.

[**Scarica l'APK**](https://github.com/marcobarca/logicash/releases/latest) &nbsp;·&nbsp; [Segnala un bug](https://github.com/marcobarca/logicash/issues) &nbsp;·&nbsp; [Richiedi una funzione](https://github.com/marcobarca/logicash/issues)

</div>

---

## Funzionalità

### Dashboard
- **Health Score mensile** (0–100) basato su risparmio, anomalie, trend e copertura spese fisse
- Saldo del mese con entrate, uscite e risparmiato a colpo d'occhio
- **Proiezione fine mese** stimata in base al ritmo di spesa attuale e al mese fiscale configurato
- Alert intelligenti su anomalie di spesa e obiettivi vicini al traguardo
- AI Insights strutturati (punti positivi / warning / consigli) con grafici inline generati dall'assistente

### Analisi Spese
- Breakdown per categoria con grafico a torta interattivo
- Trend mensile per categoria (istogramma ultimi 6 mesi)
- **Rilevamento anomalie** — avviso quando una categoria supera del 30% la media storica
- **Heatmap comportamentale** — pattern di spesa per giorno della settimana
- Top 10 spese del mese, modificabili direttamente
- Navigazione per periodo con selettore mese/anno e frecce di navigazione rapida

### Movimenti
- Lista completa con ricerca testuale e filtri per tipo (entrate/uscite)
- Modifica e cancellazione di ogni transazione
- Integrata nella scheda Spese per una navigazione fluida tra analisi e lista

### Obiettivi & Simulatore
- Crea obiettivi con nome, importo target ed emoji personalizzata
- Timeline automatica calcolata sulla media di risparmio storica
- **Simulatore interattivo** — modifica l'importo mensile e vedi la data di arrivo aggiornarsi in tempo reale
- Più obiettivi in parallelo con barra di progresso visiva

### Spese Fisse
- **Rilevamento automatico** di pagamenti periodici (settimanali / mensili / annuali)
- Candidati da confermare o scartare con una sola azione
- Totale mensile impegnato e costo annualizzato
- Aggiunta manuale di abbonamenti e bollette

### Assistente AI (Gemini)
- Chat in linguaggio naturale sui propri dati finanziari
- **Tool calling** — l'agente può creare/eliminare obiettivi, fare previsioni, simulazioni e generare grafici inline
- Report narrativo mensile e consigli personalizzati
- Categorizzazione automatica di transazioni ambigue
- Rilevamento automatico del profilo di import per file di banche diverse
- Tracciamento token e costi per ogni modello utilizzato

### Sicurezza & Privacy
- Blocco app con **PIN a 4 cifre** — tutti i dati rimangono sul device
- Nessun dato finanziario grezzo inviato a server esterni (l'AI riceve solo aggregati anonimi)
- Chiavi API salvate nel **Keystore Android** tramite `flutter_secure_storage`

---

## Installazione

### Per gli utenti

1. Vai alla pagina [**Releases**](https://github.com/marcobarca/logicash/releases/latest)
2. Scarica il file `logicash-vX.X.X.apk`
3. Apri il file sul tuo Android — se richiesto, abilita **"Installa da fonti sconosciute"** per il browser o file manager che stai usando
4. Segui le istruzioni di installazione di Android

**L'app si aggiorna automaticamente** — a ogni avvio controlla se è disponibile una nuova versione e, se sì, mostra un dialog per scaricarla e installarla in-app.

> **Nota:** Su Android 8+ l'autorizzazione "Installa app sconosciute" si concede per singola app dal menu Impostazioni → App → *(browser usato per scaricare)* → Installa app sconosciute.

### Per gli sviluppatori

**Requisiti:** Flutter 3.x / Dart SDK 3.12+ · Android SDK API 26+

```bash
git clone https://github.com/marcobarca/logicash.git
cd logicash
flutter pub get
flutter run
```

**Build APK release:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Configurazione

### Chiave API Gemini

Le funzioni AI richiedono una chiave API Gemini (gratuita).

1. Vai su [Google AI Studio](https://aistudio.google.com/app/apikey) e crea una chiave
2. In Logicash: **Impostazioni → Intelligenza Artificiale**
3. Incolla la chiave e tocca **Salva**, poi **Testa connessione** per verificare

La chiave viene salvata localmente nel Keystore Android e non viene mai condivisa con terze parti.

### Importazione dati bancari

Logicash supporta nativamente i file `.xlsx` esportati da **Intesa Sanpaolo**. Per altre banche:

1. **Impostazioni → Profili importazione → Nuovo profilo**
2. Usa il rilevamento automatico AI oppure configura manualmente le colonne
3. Esporta il file dalla tua banca e importalo tramite il pulsante nella scheda Movimenti

**Formati supportati:** `.xlsx`, `.csv`

---

## Aggiornamenti automatici

I nuovi rilasci vengono compilati e pubblicati in automatico tramite **GitHub Actions** a ogni tag `vX.X.X`. L'app controlla la disponibilità di aggiornamenti all'avvio e guida l'utente attraverso il download e l'installazione senza uscire dall'app.

---

## Tech Stack

| Layer | Tecnologia |
|-------|-----------|
| Framework | Flutter 3.x / Dart |
| Storage locale | SQLite via `sqflite` |
| AI | `google_generative_ai` — Gemini Flash, chat + tool calling |
| Parsing file | `archive` — `.xlsx` come ZIP + XML manuale |
| Grafici | `fl_chart` |
| State management | `provider` |
| Sicurezza | `flutter_secure_storage` |
| Aggiornamenti | GitHub Releases API + `dio` + `open_file` |
| Animazioni | `flutter_animate` |
| Font | Inter via `google_fonts` |

---

## Roadmap

- [x] Dashboard con Health Score e proiezioni AI
- [x] Analisi spese con anomalie e heatmap comportamentale
- [x] Obiettivi con simulatore interattivo
- [x] Spese fisse con rilevamento automatico
- [x] Assistente AI con tool calling e grafici inline
- [x] Import xlsx/csv con supporto multi-banca
- [x] Blocco PIN
- [x] Aggiornamenti automatici via GitHub Releases
- [ ] Cifratura database con PIN (SQLCipher + PBKDF2)
- [ ] Storico importazioni
- [ ] Supporto multilingua (IT / EN)

---

<div align="center">
  <sub>Fatto con ❤️ da <a href="https://github.com/marcobarca">Marco Barca</a></sub>
</div>
