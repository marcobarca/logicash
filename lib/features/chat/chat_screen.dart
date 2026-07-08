import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_provider.dart';
import '../../core/gemini/gemini_service.dart';
import '../../core/database/models/goal_model.dart';
import '../../core/database/models/fixed_expense_model.dart';
import '../../core/charts/chart_spec.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/chart_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// ── Slash commands ────────────────────────────────────────────

class _SlashCommand {
  final String command;
  final String label;
  final String description;
  final IconData icon;
  final String template;
  final bool sendDirectly;
  final bool isReset;
  const _SlashCommand({
    required this.command, required this.label, required this.description,
    required this.icon, required this.template,
    this.sendDirectly = false, this.isReset = false,
  });
}

const _kSlashCommands = [
  _SlashCommand(command: '/obiettivo',  label: 'Crea obiettivo',   description: 'Nuovo obiettivo di risparmio',          icon: Icons.flag_outlined,        template: 'Crea un obiettivo di risparmio chiamato '),
  _SlashCommand(command: '/spesa',      label: 'Aggiungi spesa',   description: 'Aggiungi una spesa fissa',               icon: Icons.receipt_long_outlined, template: 'Aggiungi una spesa fissa: '),
  _SlashCommand(command: '/simula',     label: 'Simula obiettivo', description: 'Quanti mesi per raggiungere un target',  icon: Icons.calculate_outlined,    template: 'Quanti mesi per mettere da parte €'),
  _SlashCommand(command: '/previsione', label: 'Previsione mese',  description: 'Risparmio previsto a fine mese',         icon: Icons.trending_up,           template: 'Quanto risparmierò a fine mese?', sendDirectly: true),
  _SlashCommand(command: '/health',     label: 'Health score',     description: 'Punteggio di salute finanziaria',        icon: Icons.favorite_outline,      template: 'Qual è il mio health score?',     sendDirectly: true),
  _SlashCommand(command: '/obiettivi',  label: 'I miei obiettivi', description: 'Lista degli obiettivi di risparmio',    icon: Icons.savings_outlined,      template: 'Mostrami i miei obiettivi',        sendDirectly: true),
  _SlashCommand(command: '/spesefisse', label: 'Spese fisse',      description: 'Lista delle spese fisse attive',        icon: Icons.list_alt_outlined,     template: 'Mostrami le mie spese fisse',      sendDirectly: true),
  _SlashCommand(command: '/elimina',    label: 'Elimina',          description: 'Elimina un obiettivo o spesa fissa',    icon: Icons.delete_outline,        template: 'Elimina '),
  _SlashCommand(command: '/reset',      label: 'Nuova chat',       description: 'Ricomincia la conversazione',           icon: Icons.refresh,               template: '', isReset: true),
];

// ─────────────────────────────────────────────────────────────

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatItem> _items = [];
  bool _loading = false;
  bool _showSlashMenu = false;
  String _slashQuery = '';
  bool _initialArgHandled = false;

  static const _suggestions = [
    'Crea un obiettivo vacanze da €2000 🏖️',
    'Aggiungi Netflix €15 al mese 📱',
    'Quanto risparmierò a fine mese?',
    'Mostrami le mie spese fisse',
    'Quanto tempo per mettere da parte €5000?',
    'Qual è il mio health score?',
  ];

  @override
  void initState() {
    super.initState();
    _items.add(_ChatMessage(
      text: 'Ciao! Sono Logi, il tuo assistente finanziario. Posso rispondere alle tue domande, creare obiettivi, gestire spese fisse e fare previsioni. Come posso aiutarti?',
      isUser: false,
    ));
    _controller.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialArgHandled) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Map) {
      _initialArgHandled = true;
      final message = arg['message'] as String? ?? '';
      final autoSend = arg['autoSend'] as bool? ?? false;
      if (message.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (autoSend) {
            _send(message, silent: true);
          } else {
            _controller.value = TextEditingValue(
              text: message,
              selection: TextSelection.collapsed(offset: message.length),
            );
          }
        });
      }
    } else if (arg is String && arg.isNotEmpty) {
      _initialArgHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.value = TextEditingValue(
          text: arg,
          selection: TextSelection.collapsed(offset: arg.length),
        );
      });
    }
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.startsWith('/')) {
      setState(() {
        _showSlashMenu = true;
        _slashQuery = text.toLowerCase();
      });
    } else if (_showSlashMenu) {
      setState(() => _showSlashMenu = false);
    }
  }

  void _onCommandSelect(_SlashCommand cmd) {
    if (cmd.isReset) {
      context.read<AppProvider>().gemini.resetChat();
      setState(() {
        _items.clear();
        _items.add(_ChatMessage(text: 'Chat resettata. Come posso aiutarti?', isUser: false));
        _controller.clear();
        _showSlashMenu = false;
      });
      return;
    }
    if (cmd.sendDirectly) {
      setState(() { _showSlashMenu = false; });
      _controller.clear();
      _send(cmd.template);
    } else {
      _controller.value = TextEditingValue(
        text: cmd.template,
        selection: TextSelection.collapsed(offset: cmd.template.length),
      );
      setState(() => _showSlashMenu = false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text, {bool silent = false}) async {
    if (text.trim().isEmpty || _loading) return;
    final provider = context.read<AppProvider>();

    if (!provider.gemini.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configura la chiave Gemini nelle impostazioni')),
      );
      return;
    }

    setState(() {
      if (!silent) _items.add(_ChatMessage(text: text.trim(), isUser: true));
      _loading = true;
      _controller.clear();
    });
    _scrollToBottom();

    final summary = await provider.getAiSummary();
    final result = await provider.gemini.agentChat(
      text.trim(),
      financialContext: summary,
      onToolCall: (name, args) => _handleToolCall(name, args, provider),
    );

    if (!mounted) return;
    setState(() {
      if (result.actions.isNotEmpty) {
        _items.add(_ActionCard(actions: result.actions));
      }
      _items.add(_ChatMessage(text: result.text, isUser: false));
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<ToolCallResult> _handleToolCall(
    String name,
    Map<String, Object?> args,
    AppProvider provider,
  ) async {
    switch (name) {

      case 'lista_obiettivi':
        final goals = provider.goals;
        if (goals.isEmpty) return const ToolCallResult(data: 'Nessun obiettivo presente');
        final list = goals.map((g) => 'ID:${g.id} "${g.name}" - target €${g.target.toStringAsFixed(2)}').join('\n');
        return ToolCallResult(data: list);

      case 'crea_obiettivo':
        final nome = args['nome'] as String? ?? 'Obiettivo';
        final target = (args['importo_target'] as num?)?.toDouble() ?? 0;
        final emoji = args['emoji'] as String?;
        await provider.addGoal(GoalModel(
          name: nome,
          target: target,
          createdAt: DateTime.now().toIso8601String(),
          emoji: emoji,
        ));
        return ToolCallResult(
          data: 'Obiettivo "$nome" (€${target.toStringAsFixed(2)}) creato con successo',
          action: AgentAction(emoji: emoji ?? '🎯', description: 'Obiettivo "$nome" creato — €${target.toStringAsFixed(2)}'),
        );

      case 'elimina_obiettivo':
        final id = (args['id'] as num?)?.toInt();
        final nome = args['nome'] as String? ?? 'questo obiettivo';
        if (id == null) return const ToolCallResult(data: 'ID obiettivo non valido');
        final confirmed = await _confirm('Elimina obiettivo', 'Eliminare "$nome"?');
        if (!confirmed) return const ToolCallResult(data: 'Eliminazione annullata dall\'utente');
        await provider.deleteGoal(id);
        return ToolCallResult(
          data: 'Obiettivo "$nome" eliminato',
          action: AgentAction(emoji: '🗑️', description: 'Obiettivo "$nome" eliminato'),
        );

      case 'lista_spese_fisse':
        final fisse = provider.fixedExpenses.where((f) => f.confirmedByUser).toList();
        if (fisse.isEmpty) return const ToolCallResult(data: 'Nessuna spesa fissa attiva');
        final list = fisse.map((f) => 'ID:${f.id} "${f.name}" ${f.frequencyLabel} €${f.amount.toStringAsFixed(2)} (€${f.monthlyAmount.toStringAsFixed(0)}/mese)').join('\n');
        return ToolCallResult(data: list);

      case 'aggiungi_spesa_fissa':
        final nome = args['nome'] as String? ?? 'Spesa';
        final importo = (args['importo'] as num?)?.toDouble() ?? 0;
        final freqStr = (args['frequenza'] as String? ?? 'mensile').toLowerCase();
        final categoria = args['categoria'] as String?;
        final emoji = args['emoji'] as String?;
        final freq = freqStr.contains('sett') ? FixedExpenseFrequency.weekly
            : freqStr.contains('ann') ? FixedExpenseFrequency.yearly
            : FixedExpenseFrequency.monthly;
        await provider.addFixedExpense(FixedExpenseModel(
          name: nome, amount: importo, frequency: freq,
          category: categoria, emoji: emoji ?? '💳',
          confirmedByUser: true, isManual: true,
        ));
        return ToolCallResult(
          data: 'Spesa fissa "$nome" €${importo.toStringAsFixed(2)} ${freq.name} aggiunta',
          action: AgentAction(emoji: emoji ?? '💳', description: '"$nome" aggiunto alle spese fisse — €${importo.toStringAsFixed(2)}/${freqStr}'),
        );

      case 'elimina_spesa_fissa':
        final id = (args['id'] as num?)?.toInt();
        final nome = args['nome'] as String? ?? 'questa spesa';
        if (id == null) return const ToolCallResult(data: 'ID spesa non valido');
        final confirmed = await _confirm('Elimina spesa fissa', 'Eliminare "$nome"?');
        if (!confirmed) return const ToolCallResult(data: 'Eliminazione annullata dall\'utente');
        await provider.deleteFixedExpense(id);
        return ToolCallResult(
          data: 'Spesa fissa "$nome" eliminata',
          action: AgentAction(emoji: '🗑️', description: 'Spesa fissa "$nome" eliminata'),
        );

      case 'previsione_fine_mese':
        final proj = provider.projectEndOfMonth();
        final summary = provider.currentMonthlySummary;
        if (summary == null) return const ToolCallResult(data: 'Dati insufficienti per la previsione');
        final segno = proj >= 0 ? '+' : '';
        return ToolCallResult(
          data: 'Entrate: €${summary.income.toStringAsFixed(2)}, Uscite finora: €${summary.expenses.toStringAsFixed(2)}, Previsione risparmio: $segno€${proj.toStringAsFixed(2)}',
          action: AgentAction(
            emoji: proj >= 0 ? '📈' : '📉',
            description: 'Previsione fine mese: ${segno}€${proj.toStringAsFixed(2)}',
            success: proj >= 0,
          ),
        );

      case 'simula_obiettivo':
        final target = (args['importo_target'] as num?)?.toDouble() ?? 0;
        final extra = (args['risparmio_extra_mensile'] as num?)?.toDouble() ?? 0;
        final base = provider.avgMonthlySavings;
        final total = base + extra;
        if (total <= 0) return const ToolCallResult(data: 'Risparmio medio mensile insufficiente per la simulazione');
        final mesi = (target / total).ceil();
        final anni = mesi ~/ 12;
        final mesiRimasti = mesi % 12;
        final durata = anni > 0 ? '$anni anni e $mesiRimasti mesi' : '$mesi mesi';
        return ToolCallResult(
          data: 'Con risparmio medio €${total.toStringAsFixed(0)}/mese, raggiungi €${target.toStringAsFixed(0)} in $durata',
          action: AgentAction(emoji: '🔮', description: '€${target.toStringAsFixed(0)} raggiungibili in $durata'),
        );

      case 'health_score':
        final score = provider.computeHealthScore();
        final label = score >= 80 ? 'Eccellente' : score >= 60 ? 'Buono' : score >= 40 ? 'Discreto' : 'Da migliorare';
        return ToolCallResult(
          data: 'Health Score: $score/100 ($label)',
          action: AgentAction(emoji: '💚', description: 'Health Score: $score/100 — $label', success: score >= 60),
        );

      case 'genera_grafico':
        final chartType = args['chart_type'] as String? ?? 'bar';
        final title     = args['title']      as String? ?? '';
        final unit      = args['unit']       as String? ?? '€';
        final labelsRaw = args['labels']     as String? ?? '';
        final valuesRaw = args['values']     as String? ?? '';
        final spec = ChartSpec.fromMap({
          'type': chartType, 'title': title, 'unit': unit,
          'labels': labelsRaw, 'values': valuesRaw,
        });
        if (spec == null) return const ToolCallResult(data: 'Dati grafico non validi');
        setState(() => _items.add(_ChartItem(spec: spec)));
        return ToolCallResult(
          data: 'Grafico "$title" generato',
          action: AgentAction(emoji: '📊', description: 'Grafico: $title'),
        );

      default:
        return ToolCallResult(data: 'Tool "$name" non riconosciuto');
    }
  }

  Future<bool> _confirm(String title, String message) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
            content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annulla', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Elimina'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Logi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Agente finanziario AI', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              context.read<AppProvider>().gemini.resetChat();
              setState(() {
                _items.clear();
                _controller.clear();
                _showSlashMenu = false;
                _items.add(_ChatMessage(text: 'Chat resettata. Come posso aiutarti?', isUser: false));
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _items.length + (_loading ? 1 : 0) + (_items.length == 1 ? 1 : 0),
              itemBuilder: (context, i) {
                // Suggerimenti dopo il primo messaggio
                if (_items.length == 1 && i == 1) {
                  return _SuggestionsWidget(suggestions: _suggestions, onTap: _send);
                }

                int idx = (_items.length == 1 && i > 1) ? i - 1 : i;

                if (_loading && idx == _items.length) return _TypingIndicator();
                if (idx >= _items.length) return const SizedBox();

                final item = _items[idx];
                if (item is _ChatMessage) {
                  return _MessageBubble(message: item).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08);
                } else if (item is _ActionCard) {
                  return _ActionCardWidget(card: item).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08);
                } else if (item is _ChartItem) {
                  return _ChartBubble(item: item).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08);
                }
                return const SizedBox();
              },
            ),
          ),
          if (_showSlashMenu) _SlashMenuWidget(query: _slashQuery, onSelect: _onCommandSelect),
          _InputBar(controller: _controller, onSend: _send, loading: _loading),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────

abstract class _ChatItem {}

class _ChatMessage extends _ChatItem {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _ActionCard extends _ChatItem {
  final List<AgentAction> actions;
  _ActionCard({required this.actions});
}

class _ChartItem extends _ChatItem {
  final ChartSpec spec;
  _ChartItem({required this.spec});
}

// ── Widgets ───────────────────────────────────────────────────

class _SuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _SuggestionsWidget({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cosa posso fare per te', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: suggestions.map((s) => GestureDetector(
              onTap: () => onTap(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(s, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionCardWidget extends StatelessWidget {
  final _ActionCard card;
  const _ActionCardWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        margin: const EdgeInsets.only(left: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Azioni eseguite', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...card.actions.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(a.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.description,
                      style: TextStyle(
                        color: a.success ? AppColors.positive : AppColors.negative,
                        fontSize: 13, fontWeight: FontWeight.w500,
                      ))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                border: message.isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(message.text,
                  style: TextStyle(
                    color: message.isUser ? Colors.white : AppColors.textPrimary,
                    fontSize: 14, height: 1.5,
                  )),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Container(
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3)),
              ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 400.ms, delay: (i * 150).ms).then().fadeOut(duration: 400.ms)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBubble extends StatelessWidget {
  final _ChartItem item;
  const _ChartBubble({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: ChartWidget(spec: item.spec, height: 200),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlashMenuWidget extends StatelessWidget {
  final String query;
  final void Function(_SlashCommand) onSelect;
  const _SlashMenuWidget({required this.query, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filtered = _kSlashCommands.where((c) => c.command.contains(query) || query == '/').toList();
    if (filtered.isEmpty) return const SizedBox();

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border, indent: 56),
        itemBuilder: (_, i) {
          final cmd = filtered[i];
          return InkWell(
            onTap: () => onSelect(cmd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: cmd.isReset
                          ? AppColors.textMuted.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cmd.icon,
                        color: cmd.isReset ? AppColors.textMuted : AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(cmd.command,
                                style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                            const SizedBox(width: 8),
                            Text(cmd.label,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(cmd.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  if (cmd.sendDirectly)
                    const Icon(Icons.send, color: AppColors.textMuted, size: 14)
                  else
                    const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 14),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 150.ms, delay: (i * 30).ms);
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool loading;
  const _InputBar({required this.controller, required this.onSend, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !loading,
              onSubmitted: onSend,
              decoration: const InputDecoration(hintText: 'Chiedimi qualcosa...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: loading ? null : () => onSend(controller.text),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: loading ? AppColors.textMuted : AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: loading
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
