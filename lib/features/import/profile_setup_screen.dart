import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/models/import_profile_model.dart';
import '../../core/import/flexible_parser.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String filePath;
  final ImportProfile? existing; // se editing profilo esistente

  const ProfileSetupScreen({super.key, required this.filePath, this.existing});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  List<List<String>> _preview = [];
  ImportProfile? _profile;
  bool _analyzing = false;
  bool _analyzed = false;
  String? _aiError;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    try {
      _preview = FlexibleParser.readPreview(widget.filePath);
    } catch (_) {
      _preview = [];
    }
    if (widget.existing != null) {
      _profile = widget.existing;
      _nameController.text = widget.existing!.name;
      _analyzed = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _analyzeWithAi() async {
    setState(() { _analyzing = true; _aiError = null; });
    final provider = context.read<AppProvider>();
    final json = await provider.gemini.detectImportProfile(_preview);
    if (!mounted) return;
    if (json == null) {
      setState(() { _analyzing = false; _aiError = 'Gemini non ha potuto rilevare il formato. Configura manualmente.'; });
      return;
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final fileExt = widget.filePath.split('.').last.toLowerCase();
      final detected = ImportProfile(
        name: map['bankName'] as String? ?? 'Nuovo profilo',
        fileType: (map['fileType'] as String?) ?? fileExt,
        dataStartRow: (map['dataStartRow'] as num?)?.toInt() ?? 0,
        dateColIndex: (map['dateColIndex'] as num?)?.toInt() ?? 0,
        descColIndex: (map['descColIndex'] as num?)?.toInt() ?? 1,
        amountColIndex: (map['amountColIndex'] as num?)?.toInt() ?? 2,
        catColIndex: (map['catColIndex'] as num?)?.toInt() ?? -1,
        dateType: map['dateType'] as String? ?? 'string',
        dateFormat: map['dateFormat'] as String? ?? 'dd/MM/yyyy',
        decimalSep: map['decimalSep'] as String? ?? '.',
        negativeIsExpense: map['negativeIsExpense'] as bool? ?? true,
        csvDelimiter: map['csvDelimiter'] as String? ?? ';',
        encoding: map['encoding'] as String? ?? 'utf-8',
        createdAt: DateTime.now().toIso8601String(),
      );
      _nameController.text = detected.name;
      setState(() { _profile = detected; _analyzing = false; _analyzed = true; });
    } catch (e) {
      setState(() { _analyzing = false; _aiError = 'Errore nel parsing della risposta AI: $e'; });
    }
  }

  Future<void> _save() async {
    if (_profile == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inserisci un nome per il profilo')));
      return;
    }
    final provider = context.read<AppProvider>();
    final finalProfile = _profile!.copyWith(name: name);
    await provider.saveImportProfile(finalProfile);
    if (!mounted) return;
    Navigator.pop(context, finalProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Modifica profilo' : 'Nuovo formato rilevato')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Anteprima file
          LcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_chart_outlined, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    const Text('Anteprima file', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Text('${_preview.length} righe lette', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_preview.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Impossibile leggere il file. Prova a spostarlo in una cartella accessibile.',
                      style: TextStyle(color: AppColors.negative, fontSize: 12),
                    ),
                  )
                else
                  _PreviewTable(preview: _preview, profile: _profile),
                if (_profile != null) ...[
                  const SizedBox(height: 8),
                  _legendRow(AppColors.positive, 'Riga ${_profile!.dataStartRow} = inizio dati'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Analisi AI
          if (!_analyzed) ...[
            LcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rileva formato con AI', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Gemini analizzerà le righe di anteprima e rileverà automaticamente colonne, formato data e separatori.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 14),
                  if (_aiError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_aiError!, style: const TextStyle(color: AppColors.negative, fontSize: 12)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _analyzing ? null : _analyzeWithAi,
                      icon: _analyzing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(_analyzing ? 'Analisi in corso…' : 'Analizza con AI'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Profilo rilevato / editor
          if (_profile != null) ...[
            LcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profilo rilevato', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome profilo', hintText: 'Es. Intesa Sanpaolo, N26, Revolut…'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(label: 'Tipo file', value: _profile!.fileType),
                  _ProfileField(label: 'Prima riga dati (0-indexed)', value: '${_profile!.dataStartRow}'),
                  _ProfileField(label: 'Colonna data', value: '${_profile!.dateColIndex}'),
                  _ProfileField(label: 'Colonna descrizione', value: '${_profile!.descColIndex}'),
                  _ProfileField(label: 'Colonna importo', value: '${_profile!.amountColIndex}'),
                  _ProfileField(label: 'Colonna categoria', value: _profile!.catColIndex >= 0 ? '${_profile!.catColIndex}' : 'Non presente'),
                  _ProfileField(label: 'Tipo data', value: _profile!.dateType == 'serial' ? 'Seriale Excel' : 'Testo (${_profile!.dateFormat})'),
                  _ProfileField(label: 'Separatore decimali', value: _profile!.decimalSep),
                  _ProfileField(label: 'Negativi = uscite', value: _profile!.negativeIsExpense ? 'Sì' : 'No'),
                  if (_profile!.fileType == 'csv') ...[
                    _ProfileField(label: 'Delimitatore CSV', value: _profile!.csvDelimiter == '\t' ? 'TAB' : '"${_profile!.csvDelimiter}"'),
                    _ProfileField(label: 'Encoding', value: _profile!.encoding),
                  ],
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _analyzeWithAi,
                    icon: const Icon(Icons.refresh, size: 14, color: AppColors.primary),
                    label: const Text('Ri-analizza con AI', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Salva profilo e importa'),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) => Row(
    children: [
      Container(width: 10, height: 10, color: color.withValues(alpha: 0.3)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: color, fontSize: 10)),
    ],
  );
}

// Tabella con righe normalizzate alla stessa larghezza per evitare crash in Table.
class _PreviewTable extends StatelessWidget {
  final List<List<String>> preview;
  final ImportProfile? profile;
  const _PreviewTable({required this.preview, required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = preview.take(8).toList();
    // Calcola il numero di colonne massimo (cap a 8) — tutte le righe devono avere lo stesso count.
    final maxDataCols = rows.isEmpty ? 0 : rows.map((r) => min(r.length, 8)).reduce(max);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: AppColors.border, width: 0.5),
        children: rows.asMap().entries.map((e) {
          final rowIdx = e.key;
          final cells = e.value;
          final isDataStart = profile != null && rowIdx == profile!.dataStartRow;
          return TableRow(
            decoration: BoxDecoration(
              color: isDataStart
                  ? AppColors.positive.withValues(alpha: 0.08)
                  : (rowIdx % 2 == 0 ? AppColors.surfaceElevated : Colors.transparent),
            ),
            children: [
              // Numero riga
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text('$rowIdx',
                      style: TextStyle(
                          color: isDataStart ? AppColors.positive : AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              // Celle dati — padded alla stessa larghezza per tutte le righe
              ...List.generate(maxDataCols, (col) {
                final cell = col < cells.length ? cells[col] : '';
                final display = cell.length > 14 ? '${cell.substring(0, 14)}…' : cell;
                return TableCell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(display,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
