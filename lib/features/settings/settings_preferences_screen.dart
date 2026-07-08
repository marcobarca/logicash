import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';

class SettingsPreferencesScreen extends StatelessWidget {
  const SettingsPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mese fiscale & analisi')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Giorno inizio mese ────────────────────────────
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giorno di inizio mese',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Se lo stipendio arriva il 27, imposta 27: i calcoli useranno il mese dal 27 al 26 del mese successivo.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    _DayPicker(
                      selectedDay: provider.fiscalMonthStartDay,
                      onChanged: (day) => provider.setFiscalMonthStartDay(day),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              provider.fiscalMonthStartDay == 1
                                  ? 'Mese solare (1° del mese)'
                                  : 'Mese fiscale: dal ${provider.fiscalMonthStartDay} di ogni mese',
                              style: const TextStyle(color: AppColors.warning, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Periodo di riferimento ─────────────────────────
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Periodo di riferimento per le medie',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Usato per Health Score, anomalie e risparmio medio',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [3, 6, 12].map((m) {
                        final selected = provider.referencePeriod == m;
                        return GestureDetector(
                          onTap: () => provider.setReferencePeriod(m),
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Text('$m',
                                    style: TextStyle(
                                        color: selected ? Colors.white : AppColors.textPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                                Text('mesi',
                                    style: TextStyle(
                                        color: selected ? Colors.white70 : AppColors.textSecondary,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Day picker ────────────────────────────────────────────────

class _DayPicker extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onChanged;

  const _DayPicker({required this.selectedDay, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [1, 5, 10, 15, 20, 25, 26, 27, 28, 29, 30].map((day) {
        final selected = selectedDay == day;
        return GestureDetector(
          onTap: () => onChanged(day),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? AppColors.warning : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppColors.warning : AppColors.border),
            ),
            child: Center(
              child: Text(
                day == 1 ? '1°' : '$day',
                style: TextStyle(
                  color: selected ? Colors.black : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
