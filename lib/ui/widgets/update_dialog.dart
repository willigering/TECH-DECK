import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_info.dart';
import '../../update/update_controller.dart';
import 'gold_button.dart';

/// Shows the TECH//DECK styled update dialog. Uses the existing theme,
/// GoldButton and panel language; no new design tokens.
Future<void> showUpdateDialog(BuildContext context) {
  final controller = context.read<UpdateController>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChangeNotifierProvider<UpdateController>.value(
      value: controller,
      child: const UpdateDialog(),
    ),
  );
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<UpdateController>();
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final u = c.update;
    final busy =
        c.phase == UpdatePhase.downloading || c.phase == UpdatePhase.verifying;
    final installedName = c.installed?.versionName ?? AppInfo.version;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withValues(alpha: .45),
            width: 1.05,
          ),
          boxShadow: [
            BoxShadow(color: cs.primary.withValues(alpha: .12), blurRadius: 22),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppInfo.name,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 1.6,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'SYSTEM UPDATE AVAILABLE',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  letterSpacing: 2.4,
                  color: cs.onSurface.withValues(alpha: .8),
                ),
              ),
              const SizedBox(height: 18),
              _row(context, 'Installiert', installedName),
              const SizedBox(height: 4),
              _row(context, 'Verfügbar', u?.versionName ?? '–'),
              if (u != null) ...[
                const SizedBox(height: 4),
                _row(context, 'Größe', formatBytes(u.apk.size)),
              ],
              if (u != null && u.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Was ist neu?',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    // Plain Text only: release notes are never interpreted.
                    child: Text(u.releaseNotes, style: text.bodyMedium),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (busy) ...[
                GoldProgressBar(value: c.progress),
                const SizedBox(height: 8),
                Text(
                  c.phase == UpdatePhase.verifying
                      ? 'Prüfe Signatur und Prüfsumme …'
                      : '${(c.progress * 100).toStringAsFixed(0)} % · ${formatBytes(c.received)} / ${formatBytes(c.total)}',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 14),
                GoldButton(
                  label: 'DOWNLOAD ABBRECHEN',
                  filled: false,
                  icon: Icons.close_rounded,
                  onTap: c.cancelDownload,
                ),
              ] else ...[
                if (c.phase == UpdatePhase.error && c.message != null) ...[
                  Text(
                    c.message!,
                    style: text.bodyMedium?.copyWith(color: cs.error),
                  ),
                  const SizedBox(height: 14),
                ],
                if (c.phase == UpdatePhase.installing) ...[
                  Text(
                    'Android-Installationsdialog geöffnet. Deine Lernkarten und Einstellungen bleiben erhalten.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                ],
                GoldButton(
                  label: 'JETZT AKTUALISIEREN',
                  icon: Icons.system_update_alt_rounded,
                  onTap: u == null ? null : c.downloadAndInstall,
                ),
                const SizedBox(height: 10),
                GoldButton(
                  label: 'SPÄTER ERINNERN',
                  filled: false,
                  onTap: () {
                    c.remindLater();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(width: 92, child: Text('$label:', style: text.bodyMedium)),
        Expanded(
          child: Text(
            value,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
