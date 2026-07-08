import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class SettingsHelpScreen extends StatefulWidget {
  const SettingsHelpScreen({super.key});
  @override
  State<SettingsHelpScreen> createState() => _SettingsHelpScreenState();
}

class _SettingsHelpScreenState extends State<SettingsHelpScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _kSections.where((s) {
      if (_query.isEmpty) return true;
      final inTitle = s.title.toLowerCase().contains(_query);
      final inItems = s.items.any((i) =>
          i.title.toLowerCase().contains(_query) ||
          i.body.toLowerCase().contains(_query));
      return inTitle || inItems;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Guida all\'app')),
      body: Column(
        children: [
          // ── Barra di ricerca ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cerca nelle guide…',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),

          // ── Contenuto ────────────────────────────────────────
          Expanded(
            child: sections.isEmpty
                ? const Center(
                    child: Text('Nessun risultato',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: sections.length,
                    itemBuilder: (context, i) => _SectionCard(
                      section: sections[i],
                      query: _query,
                      initiallyExpanded: _query.isNotEmpty,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Section card espandibile ──────────────────────────────────

class _SectionCard extends StatefulWidget {
  final _HelpSection section;
  final String query;
  final bool initiallyExpanded;
  const _SectionCard({required this.section, required this.query, required this.initiallyExpanded});
  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(_SectionCard old) {
    super.didUpdateWidget(old);
    if (widget.initiallyExpanded != old.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final visibleItems = widget.query.isEmpty
        ? s.items
        : s.items.where((i) =>
            i.title.toLowerCase().contains(widget.query) ||
            i.body.toLowerCase().contains(widget.query)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header sezione
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s.icon, color: s.color, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        Text(s.subtitle,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Items
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...visibleItems.asMap().entries.map((e) {
              final item = e.value;
              return Column(
                children: [
                  if (e.key > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                  _ItemTile(item: item),
                ],
              );
            }),
            if (s.tip != null) _TipBox(tip: s.tip!),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final _HelpItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 3),
                Text(item.body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String tip;
  const _TipBox({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tip,
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── Modelli dati ──────────────────────────────────────────────

class _HelpSection {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<_HelpItem> items;
  final String? tip;

  const _HelpSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.items,
    this.tip,
  });
}

class _HelpItem {
  final String emoji;
  final String title;
  final String body;
  const _HelpItem(this.emoji, this.title, this.body);
}

// ── Contenuto guida ───────────────────────────────────────────

const _kSections = [
  _HelpSection(
    icon: Icons.home_outlined,
    color: Color(0xFF6C63FF),
    title: 'Dashboard',
    subtitle: 'La schermata principale',
    items: [
      _HelpItem('📊', 'Health Score',
          'Punteggio da 0 a 100 che misura la salute finanziaria del mese in corso. Considera entrate, uscite, spese fisse e obiettivi attivi.'),
      _HelpItem('📈', 'Proiezione fine mese',
          'Stima di quanto spenderai entro la fine del mese fiscale, calcolata in base al ritmo di spesa attuale dei giorni trascorsi.'),
      _HelpItem('💳', 'Riepilogo veloce',
          'Mostra entrate totali, uscite totali e saldo netto del mese fiscale corrente.'),
      _HelpItem('🔮', 'Consigli AI',
          'Tre insight generati da Logi ogni volta che apri la dashboard: un punto positivo, un segnale d\'attenzione e un consiglio pratico. Tappaci sopra per approfondire.'),
      _HelpItem('📅', 'Navigazione mesi',
          'Scorri a sinistra e destra nella barra in cima per cambiare mese e vedere i dati storici.'),
    ],
    tip: 'Tappa su un consiglio AI per vedere i dettagli e grafico. Dal pannello dettaglio puoi poi chiedere a Logi di approfondire direttamente in chat.',
  ),

  _HelpSection(
    icon: Icons.bar_chart_outlined,
    color: Color(0xFF4CAF50),
    title: 'Analisi spese',
    subtitle: 'Grafici e breakdown per categoria',
    items: [
      _HelpItem('🍕', 'Spese per categoria',
          'Grafico a barre con il totale speso in ogni categoria nel mese selezionato. Tappa su una barra per filtrare i movimenti.'),
      _HelpItem('📉', 'Trend mensile',
          'Confronto delle uscite totali negli ultimi mesi per individuare tendenze di aumento o risparmio.'),
      _HelpItem('⚠️', 'Anomalie',
          'Categorie in cui stai spendendo significativamente più della tua media storica vengono segnalate in arancione.'),
    ],
    tip: 'Il periodo di riferimento per calcolare le medie si configura in Impostazioni → Mese fiscale & analisi.',
  ),

  _HelpSection(
    icon: Icons.receipt_long_outlined,
    color: Color(0xFF29B6F6),
    title: 'Movimenti',
    subtitle: 'Importazione e gestione transazioni',
    items: [
      _HelpItem('📂', 'Importa file',
          'Importa estratti conto in formato CSV o Excel (.xlsx / .xls). Tocca il pulsante "Importa" in alto a destra nella schermata Movimenti.'),
      _HelpItem('🤖', 'Rilevamento automatico',
          'Tappa "Rileva nuovo con AI" e Logi analizzerà il file per identificare automaticamente le colonne di data, importo, descrizione e categoria.'),
      _HelpItem('💾', 'Profili di importazione',
          'Una volta configurato, salva il profilo con il nome della tua banca. Importazioni future dallo stesso formato saranno istantanee.'),
      _HelpItem('🔑', 'Deduplicazione',
          'Logicash usa un hash SHA-256 per ogni transazione: importare più volte lo stesso file non crea duplicati.'),
      _HelpItem('🔍', 'Filtri e ricerca',
          'Filtra i movimenti per mese, categoria o parola chiave. Usa la barra di ricerca in cima alla lista.'),
    ],
    tip: 'Se il tuo estratto conto ha una struttura insolita, usa "Rileva con AI" e controlla l\'anteprima prima di salvare il profilo.',
  ),

  _HelpSection(
    icon: Icons.flag_outlined,
    color: Color(0xFFFF7043),
    title: 'Obiettivi',
    subtitle: 'Risparmio e traguardi finanziari',
    items: [
      _HelpItem('🎯', 'Crea un obiettivo',
          'Definisci un nome, un importo target e un\'emoji. L\'app calcola quanto devi risparmiare ogni mese per raggiungerlo nei tempi previsti.'),
      _HelpItem('💰', 'Aggiungi versamenti',
          'Registra i progressi toccando "Aggiungi" sull\'obiettivo. Il grafico mostra la percentuale completata.'),
      _HelpItem('🤖', 'Gestione via Logi',
          'Puoi creare, modificare ed eliminare obiettivi direttamente in chat. Esempi: "Crea un obiettivo Vacanze da 2000€", "Quanto mi manca per l\'obiettivo Auto?".'),
    ],
    tip: 'Chiedi a Logi "Lista obiettivi" per avere un riepilogo istantaneo in chat con importi e progressi.',
  ),

  _HelpSection(
    icon: Icons.lock_clock_outlined,
    color: Color(0xFFAB47BC),
    title: 'Spese fisse',
    subtitle: 'Abbonamenti e uscite ricorrenti',
    items: [
      _HelpItem('📋', 'Aggiungi una spesa fissa',
          'Inserisci nome, importo e frequenza (mensile, settimanale o annuale). Logicash calcolerà automaticamente l\'impatto mensile sul tuo budget.'),
      _HelpItem('📊', 'Impatto sul budget',
          'Il totale delle spese fisse mensili viene visualizzato nella dashboard e sottratto dalle entrate per calcolare il margine disponibile.'),
      _HelpItem('🤖', 'Gestione via Logi',
          'Puoi aggiungere ed eliminare spese fisse in chat. Esempio: "Aggiungi Netflix 17€ al mese" oppure "Elimina la spesa Palestra".'),
    ],
  ),

  _HelpSection(
    icon: Icons.auto_awesome_outlined,
    color: Color(0xFF6C63FF),
    title: 'Logi — Assistente AI',
    subtitle: 'Chat intelligente con strumenti integrati',
    items: [
      _HelpItem('💬', 'Chat libera',
          'Fai qualsiasi domanda sui tuoi dati finanziari. Logi conosce le tue spese, entrate, obiettivi e spese fisse del mese corrente.'),
      _HelpItem('/', 'Comandi slash',
          'Digita / nella chat per vedere i comandi disponibili: riepilogo, analisi categorie, obiettivi, spese fisse, report mensile, consiglio risparmio, proiezione, health score, grafico spese.'),
      _HelpItem('📊', 'Grafici dinamici',
          'Chiedi a Logi di creare un grafico e lo visualizzerà direttamente nella chat. Esempio: "Fai un grafico a torta delle mie spese di giugno".'),
      _HelpItem('🛠️', 'Azioni dirette',
          'Logi può eseguire azioni reali: creare obiettivi, aggiungere spese fisse, eliminarle. Le azioni vengono confermate con un badge verde.'),
      _HelpItem('🔮', 'Approfondisci un consiglio',
          'Dalla dashboard, tappa un consiglio AI → "Chiedimi di più in chat": Logi risponderà automaticamente con un\'analisi dettagliata.'),
    ],
    tip: 'Prova "/ " (slash + spazio) per selezionare un comando dal menu. Prova "Crea un obiettivo Fondo emergenza da 3000€" per vedere Logi in azione.',
  ),

  _HelpSection(
    icon: Icons.calendar_today_outlined,
    color: Color(0xFFFFB74D),
    title: 'Mese fiscale',
    subtitle: 'Personalizza il tuo ciclo mensile',
    items: [
      _HelpItem('📅', 'Cos\'è il mese fiscale',
          'Per default, il mese parte il 1°. Se il tuo stipendio arriva il 27, imposta il giorno 27: i calcoli useranno il periodo 27 → 26 del mese successivo.'),
      _HelpItem('🔄', 'Effetto sul ricalcolo',
          'Cambiare il giorno di inizio aggiorna immediatamente dashboard, proiezione, health score e consigli AI usando il nuovo periodo.'),
      _HelpItem('📊', 'Periodo di riferimento',
          'Puoi scegliere 3, 6 o 12 mesi per calcolare le medie storiche. Un periodo più lungo è più stabile; uno più corto è più reattivo.'),
    ],
    tip: 'Se non sei sicuro del giorno, inizia con 1 (mese solare) e modificalo dopo aver importato qualche mese di dati.',
  ),

  _HelpSection(
    icon: Icons.settings_outlined,
    color: Color(0xFF78909C),
    title: 'Impostazioni',
    subtitle: 'Configurazione e personalizzazione',
    items: [
      _HelpItem('🏦', 'I tuoi conti',
          'Aggiungi i tuoi conti correnti, carte e fondi con il saldo attuale. Il totale patrimonio viene mostrato in dashboard.'),
      _HelpItem('🔒', 'PIN di accesso',
          'Attiva un PIN a 4 cifre per proteggere l\'accesso all\'app ad ogni apertura.'),
      _HelpItem('🤖', 'Modelli AI',
          'Nella sezione Assistente AI puoi scegliere modelli diversi per ogni funzione: Agente (chat), Analisi (insight) e Utilità (categorie). Usa modelli leggeri per risparmiare costi.'),
      _HelpItem('🔑', 'Chiavi API esterne',
          'Salva in modo sicuro le chiavi API di altri servizi (OpenAI, Anthropic, Groq…) che potresti usare in futuro.'),
      _HelpItem('📁', 'Profili importazione',
          'I profili salvati durante l\'importazione vengono elencati qui. Puoi eliminarli se non ti servono più.'),
    ],
    tip: 'La chiave API Gemini è conservata in modo sicuro con flutter_secure_storage (keychain su iOS, KeyStore su Android) — non viene mai trasmessa ad altri server.',
  ),
];
