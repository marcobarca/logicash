import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';

class SettingsImportScreen extends StatelessWidget {
  const SettingsImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili importazione')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.importProfiles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Nessun profilo salvato. Importa un file dalla schermata Movimenti per crearne uno.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      )
                    else
                      ...provider.importProfiles.asMap().entries.map((e) {
                        final p = e.value;
                        return Column(
                          children: [
                            if (e.key > 0) const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.account_balance, color: AppColors.primary, size: 18),
                              ),
                              title: Text(p.name,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                '${p.fileType.toUpperCase()} · dati dalla riga ${p.dataStartRow}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.negative, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      title: const Text('Elimina profilo',
                                          style: TextStyle(color: AppColors.textPrimary)),
                                      content: Text('Eliminare il profilo "${p.name}"?',
                                          style: const TextStyle(color: AppColors.textSecondary)),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Annulla')),
                                        TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Elimina',
                                                style: TextStyle(color: AppColors.negative))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && p.id != null) {
                                    // ignore: use_build_context_synchronously
                                    await context.read<AppProvider>().deleteImportProfile(p.id!);
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }),
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
