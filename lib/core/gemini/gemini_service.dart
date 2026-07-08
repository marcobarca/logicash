import 'package:google_generative_ai/google_generative_ai.dart';
import '../ai_usage/usage_tracker.dart';

// ── Modelli disponibili ────────────────────────────────────────
// Prezzi USD per 1M token (testo)
const kGeminiModels = [
  GeminiModelOption(id: 'gemini-3.5-flash',      label: 'Gemini 3.5 Flash',      tag: '★ Consigliato', description: 'Il più recente stabile — veloce e intelligente',       inputPricePerM: 1.50,  outputPricePerM: 9.00),
  GeminiModelOption(id: 'gemini-3.1-flash-lite', label: 'Gemini 3.1 Flash-Lite', tag: 'Stabile',       description: 'Ultrarapido, consuma pochissima quota',                inputPricePerM: 0.25,  outputPricePerM: 1.50),
  GeminiModelOption(id: 'gemini-2.5-flash',      label: 'Gemini 2.5 Flash',      tag: 'Stabile',       description: 'Gen. precedente, stabile e affidabile',                inputPricePerM: 0.30,  outputPricePerM: 2.50),
  GeminiModelOption(id: 'gemini-2.5-pro',        label: 'Gemini 2.5 Pro',        tag: 'Stabile',       description: 'Pro gen. 2.5 — alta qualità',                          inputPricePerM: 1.25,  outputPricePerM: 10.00),
  GeminiModelOption(id: 'gemini-3.1-pro',        label: 'Gemini 3.1 Pro',        tag: 'Anteprima',     description: 'Pro più recente — massima intelligenza',               inputPricePerM: 2.00,  outputPricePerM: 12.00),
  GeminiModelOption(id: 'gemini-3-flash',        label: 'Gemini 3 Flash',        tag: 'Anteprima',     description: 'Gemini 3 Flash, potrebbe essere instabile',            inputPricePerM: 0.50,  outputPricePerM: 3.00),
  GeminiModelOption(id: 'gemini-2.5-flash-lite', label: 'Gemini 2.5 Flash-Lite', tag: 'Stabile',       description: 'Il più economico disponibile',                         inputPricePerM: 0.10,  outputPricePerM: 0.40),
];

class GeminiModelOption {
  final String id;
  final String label;
  final String tag;
  final String description;
  final double inputPricePerM;   // USD per 1M token input
  final double outputPricePerM;  // USD per 1M token output

  const GeminiModelOption({
    required this.id,
    required this.label,
    required this.tag,
    required this.description,
    required this.inputPricePerM,
    required this.outputPricePerM,
  });

  double costFor(int inputTokens, int outputTokens) =>
      (inputTokens  / 1_000_000) * inputPricePerM +
      (outputTokens / 1_000_000) * outputPricePerM;
}

// ── Risultato agente ───────────────────────────────────────────
class AgentResult {
  final String text;
  final List<AgentAction> actions;
  AgentResult({required this.text, this.actions = const []});
}

class AgentAction {
  final String emoji;
  final String description;
  final bool success;
  AgentAction({required this.emoji, required this.description, this.success = true});
}

// ── Tool definitions ───────────────────────────────────────────
final _tools = [
  Tool(functionDeclarations: [
    FunctionDeclaration('crea_obiettivo',
      'Crea un nuovo obiettivo di risparmio per l\'utente',
      Schema.object(properties: {
        'nome':           Schema.string(description: 'Nome dell\'obiettivo, es. Vacanze, Auto, Fondo emergenza'),
        'importo_target': Schema.number(description: 'Importo in euro da raggiungere'),
        'emoji':          Schema.string(description: 'Emoji opzionale che rappresenta l\'obiettivo, es. 🏖️ 🚗 🏠'),
      }, requiredProperties: ['nome', 'importo_target']),
    ),
    FunctionDeclaration('elimina_obiettivo',
      'Elimina un obiettivo di risparmio esistente tramite ID',
      Schema.object(properties: {
        'id':   Schema.integer(description: 'ID numerico dell\'obiettivo da eliminare'),
        'nome': Schema.string(description: 'Nome dell\'obiettivo (per conferma)'),
      }, requiredProperties: ['id', 'nome']),
    ),
    FunctionDeclaration('lista_obiettivi',
      'Restituisce la lista degli obiettivi di risparmio correnti con ID, nome, importo target',
      Schema.object(properties: {}),
    ),
    FunctionDeclaration('aggiungi_spesa_fissa',
      'Aggiunge una nuova spesa fissa (abbonamento, affitto, bolletta, ecc.)',
      Schema.object(properties: {
        'nome':      Schema.string(description: 'Nome della spesa, es. Netflix, Affitto, Palestra'),
        'importo':   Schema.number(description: 'Importo in euro'),
        'frequenza': Schema.string(description: 'Frequenza: "mensile", "settimanale" o "annuale"'),
        'categoria': Schema.string(description: 'Categoria opzionale, es. Abbonamenti, Casa, Sport'),
        'emoji':     Schema.string(description: 'Emoji opzionale, es. 📱 🏠 🏋️'),
      }, requiredProperties: ['nome', 'importo', 'frequenza']),
    ),
    FunctionDeclaration('elimina_spesa_fissa',
      'Elimina una spesa fissa esistente tramite ID',
      Schema.object(properties: {
        'id':   Schema.integer(description: 'ID numerico della spesa fissa da eliminare'),
        'nome': Schema.string(description: 'Nome della spesa (per conferma)'),
      }, requiredProperties: ['id', 'nome']),
    ),
    FunctionDeclaration('lista_spese_fisse',
      'Restituisce la lista delle spese fisse attive con ID, nome, importo e frequenza',
      Schema.object(properties: {}),
    ),
    FunctionDeclaration('previsione_fine_mese',
      'Calcola la previsione di risparmio a fine mese corrente considerando entrate, uscite e spese fisse',
      Schema.object(properties: {}),
    ),
    FunctionDeclaration('simula_obiettivo',
      'Simula quanti mesi servono per raggiungere un obiettivo dato il risparmio medio mensile',
      Schema.object(properties: {
        'importo_target':          Schema.number(description: 'Importo target in euro'),
        'risparmio_extra_mensile': Schema.number(description: 'Risparmio extra mensile aggiuntivo opzionale in euro'),
      }, requiredProperties: ['importo_target']),
    ),
    FunctionDeclaration('health_score',
      'Restituisce il punteggio di salute finanziaria attuale (0-100) con spiegazione',
      Schema.object(properties: {}),
    ),
    FunctionDeclaration('genera_grafico',
      'Genera un grafico da visualizzare in chat per rappresentare dati finanziari in modo visivo. Usalo quando è utile mostrare confronti, trend o distribuzioni.',
      Schema.object(properties: {
        'chart_type': Schema.string(description: '"bar" per confronti tra categorie, "line" per trend mensili, "pie" per distribuzioni percentuali'),
        'title':      Schema.string(description: 'Titolo descrittivo del grafico, es. "Spese per categoria" o "Trend risparmio"'),
        'unit':       Schema.string(description: 'Unità di misura: "€" oppure "%"'),
        'labels':     Schema.string(description: 'Etichette degli elementi separate da virgola, es: "Cibo,Trasporti,Casa,Intrattenimento"'),
        'values':     Schema.string(description: 'Valori numerici corrispondenti separati da virgola, es: "320.5,150.0,800.0,95.0"'),
      }, requiredProperties: ['chart_type', 'title', 'labels', 'values']),
    ),
  ]),
];

// ── Slot modello per funzione ──────────────────────────────────
enum GeminiModelSlot { agent, analysis, utility }

extension GeminiModelSlotLabel on GeminiModelSlot {
  String get label {
    switch (this) {
      case GeminiModelSlot.agent:    return 'Agente chat';
      case GeminiModelSlot.analysis: return 'Analisi mensile';
      case GeminiModelSlot.utility:  return 'Utilità';
    }
  }
  String get description {
    switch (this) {
      case GeminiModelSlot.agent:    return 'Tool calling, ragionamento, conversazione';
      case GeminiModelSlot.analysis: return 'Insight, report, grafici';
      case GeminiModelSlot.utility:  return 'Categorie, import, operazioni rapide';
    }
  }
  String get prefKey {
    switch (this) {
      case GeminiModelSlot.agent:    return 'gemini_model_agent';
      case GeminiModelSlot.analysis: return 'gemini_model_analysis';
      case GeminiModelSlot.utility:  return 'gemini_model_utility';
    }
  }
  String get defaultModel {
    switch (this) {
      case GeminiModelSlot.agent:    return 'gemini-3.5-flash';
      case GeminiModelSlot.analysis: return 'gemini-2.5-flash';
      case GeminiModelSlot.utility:  return 'gemini-2.5-flash-lite';
    }
  }
}

// ── Servizio principale ────────────────────────────────────────
class GeminiService {
  GenerativeModel? _agentModel;
  ChatSession? _chat;
  String? _apiKey;

  // Modelli per slot
  String _agentModelId    = GeminiModelSlot.agent.defaultModel;
  String _analysisModelId = GeminiModelSlot.analysis.defaultModel;
  String _utilityModelId  = GeminiModelSlot.utility.defaultModel;

  final UsageTracker _tracker = UsageTracker();

  UsageTracker get tracker => _tracker;

  String getModelId(GeminiModelSlot slot) {
    switch (slot) {
      case GeminiModelSlot.agent:    return _agentModelId;
      case GeminiModelSlot.analysis: return _analysisModelId;
      case GeminiModelSlot.utility:  return _utilityModelId;
    }
  }

  void configure(String apiKey, {String? agentModelId, String? analysisModelId, String? utilityModelId}) {
    _apiKey = apiKey;
    if (agentModelId    != null) _agentModelId    = agentModelId;
    if (analysisModelId != null) _analysisModelId = analysisModelId;
    if (utilityModelId  != null) _utilityModelId  = utilityModelId;
    _rebuildAgent();
  }

  void setModel(GeminiModelSlot slot, String modelId) {
    switch (slot) {
      case GeminiModelSlot.agent:
        _agentModelId = modelId;
        if (_apiKey != null) _rebuildAgent();
      case GeminiModelSlot.analysis:
        _analysisModelId = modelId;
      case GeminiModelSlot.utility:
        _utilityModelId = modelId;
    }
  }

  void _rebuildAgent() {
    _agentModel = GenerativeModel(
      model: _agentModelId,
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(temperature: 0.7, maxOutputTokens: 2048),
      systemInstruction: Content.system(
        'Sei Logi, un consulente finanziario personale integrato nell\'app Logicash. '
        'Rispondi SEMPRE in italiano, in modo conciso e diretto. '
        'Hai accesso a strumenti per gestire obiettivi e spese fisse dell\'utente: usali proattivamente quando l\'utente lo chiede o quando è utile. '
        'Prima di eliminare qualcosa, descrivi cosa stai per fare. '
        'Dopo ogni azione completata, conferma brevemente il risultato. '
        'Non inventare mai dati non presenti nel contesto.',
      ),
      tools: _tools,
    );
    _chat = _agentModel!.startChat();
  }

  GenerativeModel _makeModel(GeminiModelSlot slot, {double temperature = 0.6, int maxTokens = 512}) {
    return GenerativeModel(
      model: getModelId(slot),
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(temperature: temperature, maxOutputTokens: maxTokens),
    );
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  void resetChat() => _chat = _agentModel?.startChat();

  void _track(GenerateContentResponse r, GeminiModelSlot slot) {
    final meta = r.usageMetadata;
    if (meta == null) return;
    _tracker.addUsage(
      getModelId(slot),
      meta.promptTokenCount ?? 0,
      meta.candidatesTokenCount ?? 0,
    );
  }

  // ── Chat agente (con tool calling) — slot: agent ─────────
  Future<AgentResult> agentChat(
    String message, {
    required String financialContext,
    required Future<ToolCallResult> Function(String name, Map<String, Object?> args) onToolCall,
    int maxRounds = 8,
  }) async {
    if (!isConfigured) {
      return AgentResult(text: 'Configura la chiave API Gemini nelle impostazioni.');
    }
    _chat ??= _agentModel!.startChat();

    final prompt = 'Dati finanziari aggiornati:\n$financialContext\n\nRichiesta utente: $message';
    final actions = <AgentAction>[];

    try {
      var response = await _chat!.sendMessage(Content.text(prompt));
      _track(response, GeminiModelSlot.agent);

      for (int round = 0; round < maxRounds; round++) {
        final calls = response.functionCalls.toList();
        if (calls.isEmpty) break;

        final results = <FunctionResponse>[];
        for (final fc in calls) {
          final result = await onToolCall(fc.name, fc.args);
          if (result.action != null) actions.add(result.action!);
          results.add(FunctionResponse(fc.name, {'result': result.data}));
        }

        response = await _chat!.sendMessage(Content.functionResponses(results));
        _track(response, GeminiModelSlot.agent);
      }

      return AgentResult(text: response.text ?? 'Operazione completata.', actions: actions);
    } on InvalidApiKey {
      return AgentResult(text: 'Chiave API non valida. Verifica nelle impostazioni.');
    } on ServerException catch (e) {
      return AgentResult(text: 'Errore server: ${e.message}');
    } catch (e) {
      return AgentResult(text: 'Errore: $e');
    }
  }

  // ── Test connessione — slot: utility ───────────────────────
  Future<String?> testConnection() async {
    if (!isConfigured) return 'Chiave API non configurata';
    try {
      final m = _makeModel(GeminiModelSlot.utility, maxTokens: 16);
      final r = await m.generateContent([Content.text('Rispondi solo: OK')]);
      final text = r.text ?? '';
      return text.isEmpty ? 'Risposta vuota dal server' : null;
    } on InvalidApiKey {
      return 'Chiave API non valida';
    } on ServerException catch (e) {
      return 'Errore server: ${e.message}';
    } catch (e) {
      return 'Errore: $e';
    }
  }

  /// Restituisce una lista JSON di 3 insight finanziari strutturati con approfondimento.
  /// Formato: [{"type":"positive"|"warning"|"tip", "emoji":"…", "title":"…", "body":"…", "detail":"…"}]
  Future<String> getMonthlyInsights(String financialSummaryJson) async {
    if (!isConfigured) return '';
    const prompt = r'''
Sei Logi, l'assistente finanziario dell'app Logicash per Android.
Il tuo output viene mostrato in schede grafiche nell'app — NON usare markdown, asterischi, grassetto o simboli speciali nel testo.
Scrivi SEMPRE in italiano, in modo diretto (dai del "tu"). Usa dati numerici reali dai dati forniti: nomi di categorie, importi precisi, percentuali.

Genera esattamente 3 insight. Rispondi SOLO con un array JSON valido, nessun testo fuori dal JSON.

Per ogni insight puoi includere un campo "chart" opzionale con un grafico pertinente basato sui dati reali.
Il grafico va incluso SOLO se aggiunge valore (es. confronto categorie per il warning, trend per il positive, distribuzione per il tip).
Se non c'è un grafico utile, ometti il campo "chart" oppure metti null.

[
  {
    "type": "positive",
    "emoji": "<emoji pertinente>",
    "title": "<titolo max 4 parole, cita la categoria o il dato>",
    "body": "<1 frase, max 18 parole, con importo o percentuale reale dai dati>",
    "detail": "<2-3 frasi di approfondimento: cita spese esatte, confronta con mesi precedenti, spiega perché è positivo>",
    "chart": {
      "type": "bar|line|pie",
      "title": "<titolo del grafico>",
      "unit": "€",
      "labels": ["label1", "label2", "..."],
      "values": [123.0, 456.0, "..."]
    }
  },
  {
    "type": "warning",
    "emoji": "<emoji pertinente>",
    "title": "<titolo max 4 parole, cita la categoria problematica>",
    "body": "<1 frase, max 18 parole, con importo o % di scostamento reale>",
    "detail": "<2-3 frasi: cita le spese che pesano di più, confronta con la media, suggerisci azione concreta con obiettivo numerico>",
    "chart": null
  },
  {
    "type": "tip",
    "emoji": "<emoji pertinente>",
    "title": "<titolo max 4 parole>",
    "body": "<1 frase, max 18 parole, consiglio concreto e attuabile>",
    "detail": "<2-3 frasi: ragionamento con i dati dell'utente, quantifica beneficio in euro o mesi>",
    "chart": null
  }
]

Dati finanziari reali dell'utente:
{DATA}
''';
    final model = _makeModel(GeminiModelSlot.analysis, temperature: 0.65, maxTokens: 900);
    try {
      final r = await model.generateContent([
        Content.text(prompt.replaceAll('{DATA}', financialSummaryJson)),
      ]);
      _track(r, GeminiModelSlot.analysis);
      var text = r.text?.trim() ?? '';
      text = text.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
      text = text.replaceAll(RegExp(r'^```\s*', multiLine: true), '');
      return text;
    } catch (_) { return ''; }
  }

  Future<String> getMonthlyReport(String financialSummaryJson) async {
    if (!isConfigured) return '';
    final model = _makeModel(GeminiModelSlot.analysis, temperature: 0.7, maxTokens: 300);
    try {
      final r = await model.generateContent([Content.text(
        'Scrivi un report mensile breve (3-4 frasi) in italiano.\nEvidenzia il punto più positivo e quello da migliorare.\n\nDati: $financialSummaryJson'
      )]);
      _track(r, GeminiModelSlot.analysis);
      return r.text ?? '';
    } catch (_) { return ''; }
  }

  /// Rileva il formato di un file bancario dall'anteprima delle prime righe.
  /// Restituisce un JSON con il profilo, o null in caso di errore.
  Future<String?> detectImportProfile(List<List<String>> preview) async {
    if (!isConfigured) return null;
    // slot: utility — task strutturato ma non serve capacità elevata
    final model = _makeModel(GeminiModelSlot.utility, temperature: 0.1, maxTokens: 512);

    final previewText = preview.asMap().entries.map((e) =>
        'Riga ${e.key}: ${e.value.asMap().entries.map((c) => '[${c.key}]="${c.value}"').join('  ')}')
        .join('\n');

    const prompt = '''
Sei un esperto nell\'analisi di file bancari. Analizza queste righe di anteprima e identifica la struttura.

ANTEPRIMA FILE:
{PREVIEW}

Rispondi SOLO con un JSON valido, senza markdown, senza spiegazioni:
{
  "bankName": "nome banca rilevato o Unknown",
  "fileType": "xlsx" oppure "csv",
  "dataStartRow": <numero riga 0-indexed da cui iniziano i dati veri (salta intestazioni)>,
  "dateColIndex": <indice colonna 0-indexed della data>,
  "descColIndex": <indice colonna 0-indexed della descrizione/causale>,
  "amountColIndex": <indice colonna 0-indexed dell\'importo>,
  "catColIndex": <indice colonna categoria o -1 se assente>,
  "dateType": "serial" se è numero seriale Excel, altrimenti "string",
  "dateFormat": "dd/MM/yyyy" o altro formato se dateType=string,
  "decimalSep": "." oppure ",",
  "negativeIsExpense": true se importi negativi = uscite, false altrimenti,
  "csvDelimiter": ";" oppure "," oppure "\\t",
  "encoding": "utf-8" oppure "latin1"
}
''';

    try {
      final r = await model.generateContent([
        Content.text(prompt.replaceAll('{PREVIEW}', previewText)),
      ]);
      _track(r, GeminiModelSlot.utility);
      var text = r.text?.trim() ?? '';
      text = text.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
      text = text.replaceAll(RegExp(r'^```\s*', multiLine: true), '');
      return text.isEmpty ? null : text;
    } catch (_) { return null; }
  }

  // slot: utility — chiamato per ogni transazione importata
  Future<String?> suggestCategory(String desc) async {
    if (!isConfigured) return null;
    final model = _makeModel(GeminiModelSlot.utility, temperature: 0.3, maxTokens: 50);
    try {
      final r = await model.generateContent([Content.text(
        'Categoria per questa transazione bancaria italiana. Rispondi con SOLO la categoria (max 4 parole).\n\nTransazione: "$desc"'
      )]);
      _track(r, GeminiModelSlot.utility);
      return r.text?.trim();
    } catch (_) { return null; }
  }
}

class ToolCallResult {
  final String data;
  final AgentAction? action;
  const ToolCallResult({required this.data, this.action});
}
