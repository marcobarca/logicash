import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/lc_card.dart';

class WeekdayHeatmap extends StatelessWidget {
  final Map<int, double> weekdayData;

  const WeekdayHeatmap({super.key, required this.weekdayData});

  static const _days = ['Dom', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'];

  @override
  Widget build(BuildContext context) {
    if (weekdayData.isEmpty) return const SizedBox();

    final maxVal = weekdayData.values.isEmpty ? 1.0 : weekdayData.values.reduce((a, b) => a > b ? a : b);
    final total = weekdayData.values.fold<double>(0, (s, v) => s + v);
    final avgDay = total / 7;

    return LcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Text('Media giornaliera: €${avgDay.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final val = weekdayData[i] ?? 0;
              final ratio = maxVal > 0 ? val / maxVal : 0.0;
              final isMax = val == maxVal && val > 0;

              return Expanded(
                child: Column(
                  children: [
                    Text(_days[i], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 6),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 60,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: (ratio * 56).clamp(4, 56),
                          decoration: BoxDecoration(
                            color: isMax
                                ? AppColors.negative
                                : Color.lerp(AppColors.surfaceElevated, AppColors.primary, ratio.toDouble())!,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('€${val.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isMax ? AppColors.negative : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: isMax ? FontWeight.w700 : FontWeight.w400,
                        )),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
