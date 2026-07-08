import 'package:flutter/material.dart';

class ChartSpec {
  final String chartType; // "bar" | "line" | "pie"
  final String title;
  final String unit;      // "€" | "%"
  final List<ChartDataPoint> data;

  const ChartSpec({
    required this.chartType,
    required this.title,
    this.unit = '€',
    required this.data,
  });

  static ChartSpec? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    try {
      final rawLabels = m['labels'];
      final rawValues = m['values'];

      List<String> labels;
      List<double> values;

      if (rawLabels is List) {
        labels = rawLabels.map((e) => e.toString()).toList();
      } else if (rawLabels is String) {
        labels = rawLabels.split(',').map((s) => s.trim()).toList();
      } else {
        return null;
      }

      if (rawValues is List) {
        values = rawValues.map((e) => (e as num).toDouble()).toList();
      } else if (rawValues is String) {
        values = rawValues.split(',').map((s) => double.tryParse(s.trim()) ?? 0).toList();
      } else {
        return null;
      }

      if (labels.isEmpty || labels.length != values.length) return null;

      return ChartSpec(
        chartType: m['type'] as String? ?? m['chart_type'] as String? ?? 'bar',
        title:     m['title'] as String? ?? '',
        unit:      m['unit'] as String? ?? '€',
        data: List.generate(labels.length, (i) => ChartDataPoint(label: labels[i], value: values[i])),
      );
    } catch (_) {
      return null;
    }
  }

  // Colori di default per le serie
  static const List<Color> palette = [
    Color(0xFF6C63FF),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
  ];
}

class ChartDataPoint {
  final String label;
  final double value;
  const ChartDataPoint({required this.label, required this.value});
}
