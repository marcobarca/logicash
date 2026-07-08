import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../core/database/models/import_batch_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/lc_card.dart';
import '../../shared/widgets/lc_empty_state.dart';

class SettingsImportHistoryScreen extends StatelessWidget {
  const SettingsImportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storico importazioni')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final batches = provider.importBatches;

          if (batches.isEmpty) {
            return const LcEmptyState(
              emoji: '📂',
              title: 'Nessuna importazione',
              body: 'I file che importerai appariranno qui. Puoi eliminare un\'importazione per rimuovere tutti i movimenti associati.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: batches.length,
            separatorBuilder: (context2, i2) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _BatchTile(
              batch: batches[i],
              onDelete: () => _confirmDelete(context, provider, batches[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppProvider provider,
    ImportBatch batch,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Elimina importazione',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Verranno eliminati tutti i ${batch.recordCount} movimenti importati da "${batch.fileName}".\n\nQuesta operazione non può essere annullata.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina',
                style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await provider.deleteImportBatch(batch.id);
    }
  }
}

class _BatchTile extends StatelessWidget {
  final ImportBatch batch;
  final VoidCallback onDelete;
  const _BatchTile({required this.batch, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(batch.importedAt);
    final dateLabel = date != null
        ? DateFormat('d MMM yyyy, HH:mm', 'it').format(date.toLocal())
        : batch.importedAt;

    return LcCard(
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.upload_file_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.fileName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(dateLabel,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    if (batch.profileName != null) ...[
                      const Text('  ·  ',
                          style: TextStyle(color: AppColors.border, fontSize: 11)),
                      Flexible(
                        child: Text(batch.profileName!,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${batch.recordCount} movimenti',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.negative, size: 20),
            onPressed: onDelete,
            tooltip: 'Elimina importazione',
          ),
        ],
      ),
    );
  }
}
