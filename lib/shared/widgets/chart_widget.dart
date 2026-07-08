import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/charts/chart_spec.dart';
import '../theme/app_theme.dart';

class ChartWidget extends StatelessWidget {
  final ChartSpec spec;
  final double height;

  const ChartWidget({super.key, required this.spec, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (spec.title.isNotEmpty) ...[
          Text(spec.title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: height,
          child: switch (spec.chartType) {
            'pie'  => _PieChart(spec: spec),
            'line' => _LineChart(spec: spec),
            _      => _BarChart(spec: spec),
          },
        ),
      ],
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final ChartSpec spec;
  const _BarChart({required this.spec});

  @override
  Widget build(BuildContext context) {
    final maxVal = spec.data.map((d) => d.value).reduce(max);
    final groups = spec.data.asMap().entries.map((e) {
      final color = ChartSpec.palette[e.key % ChartSpec.palette.length];
      return BarChartGroupData(x: e.key, barRods: [
        BarChartRodData(
          toY: e.value.value,
          color: color,
          width: _barWidth(spec.data.length),
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxVal * 1.1,
            color: color.withValues(alpha: 0.07),
          ),
        ),
      ]);
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.18,
        barGroups: groups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.6),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: maxVal / 4,
            getTitlesWidget: (v, _) => Text(
              '${spec.unit}${_compact(v)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= spec.data.length) return const SizedBox();
              final label = spec.data[i].label;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label.length > 8 ? '${label.substring(0, 7)}…' : label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              );
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevated,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${spec.data[group.x].label}\n${spec.unit}${rod.toY.toStringAsFixed(0)}',
              const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  double _barWidth(int count) => count <= 4 ? 22 : count <= 7 ? 16 : 11;
}

// ── Line Chart ────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final ChartSpec spec;
  const _LineChart({required this.spec});

  @override
  Widget build(BuildContext context) {
    final maxVal = spec.data.map((d) => d.value).reduce(max);
    final minVal = spec.data.map((d) => d.value).reduce(min);
    final color = AppColors.primary;

    final spots = spec.data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    return LineChart(
      LineChartData(
        minY: (minVal * 0.85).floorToDouble(),
        maxY: (maxVal * 1.15).ceilToDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4, color: color, strokeWidth: 2, strokeColor: AppColors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxVal - minVal) / 3,
          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.6),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: (maxVal - minVal) / 3,
            getTitlesWidget: (v, _) => Text(
              '${spec.unit}${_compact(v)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
            ),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= spec.data.length || v != v.roundToDouble()) return const SizedBox();
              final label = spec.data[i].label;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(label.length > 6 ? '${label.substring(0, 5)}…' : label,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
              );
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevated,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '${spec.data[s.x.toInt()].label}\n${spec.unit}${s.y.toStringAsFixed(0)}',
              const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            )).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Pie Chart ─────────────────────────────────────────────────

class _PieChart extends StatefulWidget {
  final ChartSpec spec;
  const _PieChart({required this.spec});
  @override
  State<_PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<_PieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.spec.data.map((d) => d.value).reduce((a, b) => a + b);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              pieTouchData: PieTouchData(
                touchCallback: (_, resp) {
                  setState(() {
                    _touched = resp?.touchedSection?.touchedSectionIndex ?? -1;
                  });
                },
              ),
              sections: widget.spec.data.asMap().entries.map((e) {
                final isTouched = e.key == _touched;
                final color = ChartSpec.palette[e.key % ChartSpec.palette.length];
                final pct = total > 0 ? (e.value.value / total * 100) : 0;
                return PieChartSectionData(
                  color: color,
                  value: e.value.value,
                  title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
                  radius: isTouched ? 58 : 50,
                  titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Legenda
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.spec.data.asMap().entries.map((e) {
              final color = ChartSpec.palette[e.key % ChartSpec.palette.length];
              final pct = total > 0 ? (e.value.value / total * 100) : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${widget.spec.unit}${e.value.value.toStringAsFixed(0)} · ${pct.toStringAsFixed(0)}%',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                      ],
                    )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Helper ────────────────────────────────────────────────────

String _compact(double v) {
  if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}
