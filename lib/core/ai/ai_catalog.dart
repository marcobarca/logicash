class AiProvider {
  final String id;
  final String name;
  final String initial; // lettera/simbolo per l'avatar
  final List<AiModelDef> models;

  const AiProvider({
    required this.id,
    required this.name,
    required this.initial,
    required this.models,
  });
}

class AiModelDef {
  final String id;
  final String label;
  final String tag;
  final String description;
  final double inputPricePerM;
  final double outputPricePerM;

  const AiModelDef({
    required this.id,
    required this.label,
    required this.tag,
    required this.description,
    required this.inputPricePerM,
    required this.outputPricePerM,
  });
}

const kAiProviders = [
  AiProvider(
    id: 'google',
    name: 'Google',
    initial: 'G',
    models: [
      AiModelDef(id: 'gemini-2.5-flash',      label: 'Gemini 2.5 Flash',      tag: '★ Consigliato', description: 'Veloce e intelligente, ottimo bilanciamento',      inputPricePerM: 0.30,  outputPricePerM: 2.50),
      AiModelDef(id: 'gemini-2.5-pro',         label: 'Gemini 2.5 Pro',        tag: 'Pro',           description: 'Massima qualità per analisi complesse',            inputPricePerM: 1.25,  outputPricePerM: 10.00),
      AiModelDef(id: 'gemini-2.5-flash-lite',  label: 'Gemini 2.5 Flash-Lite', tag: 'Economico',     description: 'Il più economico — per task semplici',             inputPricePerM: 0.10,  outputPricePerM: 0.40),
      AiModelDef(id: 'gemini-2.0-flash',       label: 'Gemini 2.0 Flash',      tag: 'Stabile',       description: 'Generazione precedente, stabile e testata',        inputPricePerM: 0.10,  outputPricePerM: 0.40),
      AiModelDef(id: 'gemini-1.5-flash',       label: 'Gemini 1.5 Flash',      tag: 'Legacy',        description: 'Modello più vecchio, massima compatibilità',       inputPricePerM: 0.075, outputPricePerM: 0.30),
    ],
  ),
  AiProvider(
    id: 'openai',
    name: 'OpenAI',
    initial: 'O',
    models: [
      AiModelDef(id: 'gpt-4o',          label: 'GPT-4o',       tag: '★ Consigliato', description: 'Multimodale, veloce e molto capace',                inputPricePerM: 2.50,  outputPricePerM: 10.00),
      AiModelDef(id: 'gpt-4o-mini',     label: 'GPT-4o mini',  tag: 'Economico',     description: 'Piccolo e veloce, ideale per task leggeri',         inputPricePerM: 0.15,  outputPricePerM: 0.60),
      AiModelDef(id: 'gpt-4.1',         label: 'GPT-4.1',      tag: 'Pro',           description: 'Alta intelligenza per task complessi',              inputPricePerM: 2.00,  outputPricePerM: 8.00),
      AiModelDef(id: 'gpt-4.1-mini',    label: 'GPT-4.1 mini', tag: 'Stabile',       description: 'Bilanciato tra qualità e costo',                    inputPricePerM: 0.40,  outputPricePerM: 1.60),
      AiModelDef(id: 'o3-mini',         label: 'o3-mini',       tag: 'Reasoning',     description: 'Modello di ragionamento passo-passo',               inputPricePerM: 1.10,  outputPricePerM: 4.40),
    ],
  ),
  AiProvider(
    id: 'anthropic',
    name: 'Anthropic',
    initial: 'A',
    models: [
      AiModelDef(id: 'claude-sonnet-4-6',          label: 'Claude Sonnet 4.6',  tag: '★ Consigliato', description: 'Intelligente e veloce, ottimo per tutto',           inputPricePerM: 3.00,  outputPricePerM: 15.00),
      AiModelDef(id: 'claude-opus-4-8',             label: 'Claude Opus 4.8',    tag: 'Pro',           description: 'Massima capacità, per analisi profonde',           inputPricePerM: 15.00, outputPricePerM: 75.00),
      AiModelDef(id: 'claude-haiku-4-5-20251001',   label: 'Claude Haiku 4.5',   tag: 'Economico',     description: 'Ultrarapido e leggero, ideale per utility',        inputPricePerM: 0.80,  outputPricePerM: 4.00),
    ],
  ),
];

AiProvider? providerById(String id) {
  try {
    return kAiProviders.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}

AiModelDef? modelById(String modelId) {
  for (final p in kAiProviders) {
    for (final m in p.models) {
      if (m.id == modelId) return m;
    }
  }
  return null;
}

AiProvider? providerOfModel(String modelId) {
  for (final p in kAiProviders) {
    if (p.models.any((m) => m.id == modelId)) return p;
  }
  return null;
}
