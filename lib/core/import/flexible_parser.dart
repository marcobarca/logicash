import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import '../database/models/transaction_model.dart';
import '../database/models/import_profile_model.dart';

class FlexibleParser {
  /// Restituisce le prime [maxRows] righe come List<List<String>>
  /// per mostrare l'anteprima e mandare a Gemini.
  static List<List<String>> readPreview(String filePath, {int maxRows = 25}) {
    final ext = filePath.split('.').last.toLowerCase();
    if (ext == 'xlsx') return _previewXlsx(filePath, maxRows);
    return _previewCsv(filePath, maxRows, ';', 'utf-8');
  }

  /// Anteprima CSV con auto-detect delimiter e encoding
  static List<List<String>> readCsvPreview(String filePath, {int maxRows = 25, String delimiter = ';', String encoding = 'utf-8'}) {
    return _previewCsv(filePath, maxRows, delimiter, encoding);
  }

  /// Importazione completa con profilo
  static List<TransactionModel> parse(String filePath, ImportProfile profile) {
    final ext = filePath.split('.').last.toLowerCase();
    if (ext == 'xlsx') return _parseXlsx(filePath, profile);
    return _parseCsv(filePath, profile);
  }

  // ── XLSX ──────────────────────────────────────────────────────

  static List<List<String>> _previewXlsx(String path, int maxRows) {
    try {
      final bytes = File(path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final ss = _sharedStrings(archive);
      final sheet = archive.findFile('xl/worksheets/sheet1.xml');
      if (sheet == null) return [];
      final xml = utf8.decode(sheet.content as List<int>);
      return _parseSheetRaw(xml, ss, maxRows);
    } catch (_) { return []; }
  }

  static List<TransactionModel> _parseXlsx(String path, ImportProfile profile) {
    try {
      final bytes = File(path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final ss = _sharedStrings(archive);
      final sheet = archive.findFile('xl/worksheets/sheet1.xml');
      if (sheet == null) return [];
      final xml = utf8.decode(sheet.content as List<int>);
      return _buildTransactions(xml, ss, profile);
    } catch (_) { return []; }
  }

  static List<String> _sharedStrings(Archive archive) {
    final f = archive.findFile('xl/sharedStrings.xml');
    if (f == null) return [];
    final xml = utf8.decode(f.content as List<int>);
    final result = <String>[];
    final siRe = RegExp(r'<si>(.*?)</si>', dotAll: true);
    final tRe  = RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true);
    for (final si in siRe.allMatches(xml)) {
      final parts = tRe.allMatches(si.group(1)!).map((m) => _unescapeXml(m.group(1)!)).join();
      result.add(parts);
    }
    return result;
  }

  static List<List<String>> _parseSheetRaw(String xml, List<String> ss, int maxRows) {
    final rows = <List<String>>[];
    final rowRe  = RegExp(r'<row r="(\d+)"[^>]*>(.*?)</row>', dotAll: true);
    final cellRe = RegExp(r'<c r="([A-Z]+)\d+"([^>]*)>(?:<v>(.*?)</v>)?', dotAll: true);

    for (final rowMatch in rowRe.allMatches(xml)) {
      if (rows.length >= maxRows) break;
      final cells = <int, String>{};
      for (final c in cellRe.allMatches(rowMatch.group(2)!)) {
        final col = _colLetterToIndex(c.group(1)!);
        final attrs = c.group(2) ?? '';
        final val  = c.group(3) ?? '';
        cells[col] = attrs.contains('t="s"')
            ? (int.tryParse(val) != null ? ss[int.parse(val)] : val)
            : val;
      }
      if (cells.isEmpty) continue;
      final maxCol = cells.keys.reduce((a, b) => a > b ? a : b);
      final row = List.generate(maxCol + 1, (i) => cells[i] ?? '');
      rows.add(row);
    }
    return rows;
  }

  static List<TransactionModel> _buildTransactions(String xml, List<String> ss, ImportProfile p) {
    final result = <TransactionModel>[];
    final rowRe  = RegExp(r'<row r="(\d+)"[^>]*>(.*?)</row>', dotAll: true);
    final cellRe = RegExp(r'<c r="([A-Z]+)\d+"([^>]*)>(?:<v>(.*?)</v>)?', dotAll: true);

    for (final rowMatch in rowRe.allMatches(xml)) {
      final rowIdx = int.parse(rowMatch.group(1)!) - 1; // 0-indexed
      if (rowIdx < p.dataStartRow) continue;

      final cells = <int, String>{};
      for (final c in cellRe.allMatches(rowMatch.group(2)!)) {
        final col  = _colLetterToIndex(c.group(1)!);
        final attrs = c.group(2) ?? '';
        final val  = c.group(3) ?? '';
        cells[col] = attrs.contains('t="s"')
            ? (int.tryParse(val) != null ? ss[int.parse(val)] : val)
            : val;
      }
      if (cells.isEmpty) continue;

      final dateStr   = cells[p.dateColIndex] ?? '';
      final descStr   = p.descColIndex >= 0 ? (cells[p.descColIndex] ?? '') : 'Transazione';
      final amountStr = cells[p.amountColIndex] ?? '';

      if (dateStr.isEmpty || amountStr.isEmpty) continue;

      final date   = _parseDate(dateStr, p);
      final amount = _parseAmount(amountStr, p);
      if (date == null || amount == null) continue;

      final dateIso = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
      final category = p.catColIndex >= 0 ? (cells[p.catColIndex] ?? '') : null;
      final id = _hash('$dateIso|$descStr|${amount.toStringAsFixed(2)}');

      result.add(TransactionModel(
        id: id, date: dateIso,
        yearMonth: '${date.year}-${date.month.toString().padLeft(2,'0')}',
        operation: null, details: descStr,
        category: category?.isEmpty == true ? null : category,
        amount: amount,
      ));
    }
    return result;
  }

  // ── CSV ───────────────────────────────────────────────────────

  static List<List<String>> _previewCsv(String path, int maxRows, String delimiter, String encoding) {
    try {
      final bytes = File(path).readAsBytesSync();
      final text = _decodeBytes(bytes, encoding);
      final lines = text.split('\n').take(maxRows).toList();
      return lines.map((l) => _splitCsv(l.trim(), delimiter)).toList();
    } catch (_) { return []; }
  }

  static List<TransactionModel> _parseCsv(String path, ImportProfile p) {
    final result = <TransactionModel>[];
    try {
      final bytes = File(path).readAsBytesSync();
      final text  = _decodeBytes(bytes, p.encoding);
      final lines = text.split('\n');

      for (int i = p.dataStartRow; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final cols = _splitCsv(line, p.csvDelimiter);
        if (cols.length <= p.amountColIndex) continue;

        final dateStr   = _safeCol(cols, p.dateColIndex);
        final descStr   = p.descColIndex >= 0 ? _safeCol(cols, p.descColIndex) : 'Transazione';
        final amountStr = _safeCol(cols, p.amountColIndex);

        if (dateStr.isEmpty || amountStr.isEmpty) continue;

        final date   = _parseDate(dateStr, p);
        final amount = _parseAmount(amountStr, p);
        if (date == null || amount == null) continue;

        final dateIso = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
        final category = p.catColIndex >= 0 ? _safeCol(cols, p.catColIndex) : null;
        final id = _hash('$dateIso|$descStr|${amount.toStringAsFixed(2)}');

        result.add(TransactionModel(
          id: id, date: dateIso,
          yearMonth: '${date.year}-${date.month.toString().padLeft(2,'0')}',
          operation: null, details: descStr,
          category: category?.isEmpty == true ? null : category,
          amount: amount,
        ));
      }
    } catch (_) {}
    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────

  static String _decodeBytes(List<int> bytes, String encoding) {
    try {
      if (encoding == 'latin1' || encoding == 'windows-1252') return latin1.decode(bytes);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  static DateTime? _parseDate(String raw, ImportProfile p) {
    if (raw.isEmpty) return null;
    if (p.dateType == 'serial') {
      final n = double.tryParse(raw);
      if (n == null) return null;
      return DateTime(1899, 12, 30).add(Duration(days: n.toInt()));
    }
    try {
      return DateFormat(p.dateFormat).parse(raw.trim());
    } catch (_) {
      // fallback: prova formati comuni
      for (final fmt in ['dd/MM/yyyy','yyyy-MM-dd','MM/dd/yyyy','dd-MM-yyyy','d/M/yyyy']) {
        try { return DateFormat(fmt).parse(raw.trim()); } catch (_) {}
      }
      return null;
    }
  }

  static double? _parseAmount(String raw, ImportProfile p) {
    if (raw.isEmpty) return null;
    var s = raw.trim().replaceAll(RegExp(r'[€\$£\s]'), '');
    if (p.decimalSep == ',') {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
    final val = double.tryParse(s);
    if (val == null) return null;
    return p.negativeIsExpense ? val : val.abs() * (val < 0 ? -1 : 1);
  }

  static List<String> _splitCsv(String line, String delimiter) {
    // Gestisce campi tra virgolette
    final result = <String>[];
    var inQuote = false;
    var current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') { inQuote = !inQuote; continue; }
      if (!inQuote && line.substring(i).startsWith(delimiter)) {
        result.add(current.toString().trim());
        current = StringBuffer();
        i += delimiter.length - 1;
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  static String _safeCol(List<String> cols, int i) => (i >= 0 && i < cols.length) ? cols[i] : '';

  static int _colLetterToIndex(String letters) {
    int result = 0;
    for (final c in letters.codeUnits) { result = result * 26 + (c - 64); }
    return result - 1;
  }

  static String _unescapeXml(String s) => s
      .replaceAll('&amp;', '&').replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>').replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");

  static String _hash(String raw) =>
      sha256.convert(utf8.encode(raw)).toString();
}
