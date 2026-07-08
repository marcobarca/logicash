import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../shared/theme/app_theme.dart';
import 'update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const UpdateDialog({super.key, required this.info});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double? _progress; // null = idle, 0-1 = downloading, -1 = errore
  bool _done = false;

  Future<void> _startDownload() async {
    setState(() => _progress = 0);
    try {
      final path = await UpdateService.downloadApk(
        widget.info.downloadUrl,
        (p) { if (mounted) setState(() => _progress = p); },
      );
      if (!mounted) return;
      setState(() => _done = true);
      await OpenFile.open(path, type: 'application/vnd.android.package-archive');
    } catch (_) {
      if (mounted) setState(() => _progress = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final isDownloading = _progress != null && _progress! >= 0 && !_done;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.system_update, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aggiornamento disponibile',
                      style: TextStyle(color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('Versione ${info.version}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                ],
              ),
            ],
          ),

          // Changelog
          if (info.changelog.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Novità',
                      style: TextStyle(color: AppColors.textSecondary,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    info.changelog.length > 400
                        ? '${info.changelog.substring(0, 400)}…'
                        : info.changelog,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Progress
          if (isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.surfaceElevated,
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${((_progress ?? 0) * 100).toStringAsFixed(0)}% — download in corso…',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],

          if (_progress == -1) ...[
            const Text('Download fallito. Riprova più tardi.',
                style: TextStyle(color: AppColors.negative, fontSize: 13)),
            const SizedBox(height: 12),
          ],

          if (_done) ...[
            const Text('Download completato. Segui le istruzioni per installare.',
                style: TextStyle(color: AppColors.positive, fontSize: 13)),
            const SizedBox(height: 12),
          ],

          // Bottoni
          if (!isDownloading && !_done) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startDownload,
                child: const Text('Aggiorna ora'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dopo',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ] else if (_done || _progress == -1) ...[
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Chiudi',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
