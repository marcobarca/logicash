import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../database/models/transaction_model.dart';

class ExcelParser {
  static const int _dataStartRow = 18; // riga 1-based

  static List<TransactionModel> parse(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Leggi shared strings
    final sharedStrings = _parseSharedStrings(archive);

    // Leggi sheet1
    final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
    if (sheetFile == null) return [];

    final sheetXml = utf8.decode(sheetFile.content as List<int>);
    return _parseSheet(sheetXml, sharedStrings);
  }

  static List<String> _parseSharedStrings(Archive archive) {
    final file = archive.findFile('xl/sharedStrings.xml');
    if (file == null) return [];

    final xml = utf8.decode(file.content as List<int>);
    final strings = <String>[];

    // Estrae tutti i tag <t>...</t> e <t xml:space="preserve">...</t>
    final tPattern = RegExp(r'<t(?:\s[^>]*)?>([^<]*)<\/t>', dotAll: true);
    final siPattern = RegExp(r'<si>(.*?)<\/si>', dotAll: true);

    for (final si in siPattern.allMatches(xml)) {
      final siContent = si.group(1) ?? '';
      final parts = tPattern.allMatches(siContent).map((m) => _unescape(m.group(1) ?? '')).join();
      strings.add(parts);
    }

    return strings;
  }

  static List<TransactionModel> _parseSheet(String xml, List<String> sharedStrings) {
    final transactions = <TransactionModel>[];

    final rowPattern = RegExp(r'<row[^>]*\sr="(\d+)"[^>]*>(.*?)<\/row>', dotAll: true);
    final cellPattern = RegExp(r'<c\s[^>]*r="([A-Z]+)(\d+)"([^>]*)>(.*?)<\/c>', dotAll: true);
    final vPattern = RegExp(r'<v>([^<]*)<\/v>');

    for (final rowMatch in rowPattern.allMatches(xml)) {
      final rowNum = int.parse(rowMatch.group(1)!);
      if (rowNum < _dataStartRow) continue;

      final rowContent = rowMatch.group(2)!;
      final cells = <String, _Cell>{};

      for (final cellMatch in cellPattern.allMatches(rowContent)) {
        final col = cellMatch.group(1)!;
        final attrs = cellMatch.group(3) ?? '';
        final inner = cellMatch.group(4) ?? '';

        final isString = attrs.contains('t="s"');
        final isInline = attrs.contains('t="inlineStr"');
        final vMatch = vPattern.firstMatch(inner);

        String? value;
        if (isString && vMatch != null) {
          final idx = int.tryParse(vMatch.group(1) ?? '');
          if (idx != null && idx < sharedStrings.length) {
            value = sharedStrings[idx];
          }
        } else if (isInline) {
          final tMatch = RegExp(r'<t[^>]*>([^<]*)<\/t>').firstMatch(inner);
          value = tMatch?.group(1);
        } else if (vMatch != null) {
          value = vMatch.group(1);
        }

        if (value != null) {
          cells[col] = _Cell(value: value, isNumeric: !isString && !isInline);
        }
      }

      final dateSerial = double.tryParse(cells['A']?.value ?? '');
      if (dateSerial == null) continue;

      final amountStr = cells['H']?.value;
      final amount = double.tryParse(amountStr ?? '');
      if (amount == null || amount == 0) continue;

      final date = _excelSerialToDate(dateSerial);
      final dateIso = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      final operation = cells['B']?.value?.trim();
      final details = cells['C']?.value?.trim();
      final account = cells['D']?.value?.trim();
      final category = cells['F']?.value?.trim();
      final currency = cells['G']?.value?.trim() ?? 'EUR';

      final id = _generateId(dateIso, details ?? operation ?? '', amount);

      transactions.add(TransactionModel(
        id: id,
        date: dateIso,
        yearMonth: yearMonth,
        operation: operation?.isEmpty == true ? null : operation,
        details: details?.isEmpty == true ? null : details,
        account: account?.isEmpty == true ? null : account,
        category: category?.isEmpty == true ? null : category,
        currency: currency,
        amount: amount,
      ));
    }

    return transactions;
  }

  static String _generateId(String date, String details, double amount) {
    final raw = '$date|$details|${amount.toStringAsFixed(2)}';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static DateTime _excelSerialToDate(double serial) {
    return DateTime(1899, 12, 30).add(Duration(days: serial.toInt()));
  }

  static String _unescape(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#xD;', '')
        .replaceAll('&#xA;', '\n');
  }
}

class _Cell {
  final String value;
  final bool isNumeric;
  const _Cell({required this.value, required this.isNumeric});
}
