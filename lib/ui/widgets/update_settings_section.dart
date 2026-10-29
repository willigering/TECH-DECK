import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_info.dart';
import '../../update/update_controller.dart';
import '../../update/update_models.dart';
import 'brand.dart';
import 'gold_button.dart';
import 'update_dialog.dart';

/// "SOFTWARE UPDATES" block of the existing settings screen.
class UpdateSettingsSection extends StatelessWidget {
  const UpdateSettingsSection({super.key});

  Future<void> _check(BuildContext context) async {
    final c = context.read<UpdateController>();
    final r = await c.checkNow();
    if (!context.mounted) return;
    if (r.outcome == CheckOutcome.updateAvailable) {
      await showUpdateDialog(context);
    } else if (r.message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(r.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<UpdateController?>();
    if (c == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final body = Theme.of(context).textTheme.bodyMedium;
    final installed = c.installed;
    final version = installed == null
        ? '${AppInfo.version} · Build ${AppInfo.buildNumber}'
        : '${installed.versionName} · Build ${installed.versionCode}';
    final last = c.lastSuccess == null
        ? 'Noch nie'
        : DateFormat('dd.MM.yyyy, HH:mm').format(c.lastSuccess!);
    final checking = c.phase == UpdatePhase.checking;
    Widget toggle(
      String title,
      String sub,
      bool value,
      ValueChanged<bool>? onChanged,
    ) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeThumbColor: cs.primary,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      subtitle: Text(sub, style: Theme.of(context).textTheme.bodySmall),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('SOFTWARE UPDATES'),
        const SizedBox(height: 12),
        GoldPanel(
          glow: false,
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                toggle(
                  'Automatisch nach Updates suchen',
                  'Höchstens einmal in 24 Stunden beim Start.',
                  c.autoCheck,
                  c.isSupported ? c.setAutoCheck : null,
                ),
                toggle(
                  'Nur über WLAN herunterladen',
                  'Deaktiviert: auch mobile Daten verwenden.',
                  c.wifiOnly,
                  c.isSupported ? c.setWifiOnly : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GoldButton(
          label: checking ? 'SUCHE …' : 'JETZT NACH UPDATES SUCHEN',
          icon: Icons.sync_rounded,
          filled: false,
          onTap: checking || !c.isSupported ? null : () => _check(context),
        ),
        const SizedBox(height: 10),
        Text('Installierte Version: $version', style: body),
        Text('Letzte Updateprüfung: $last', style: body),
        if (!c.isSupported)
          Text(
            'Updates sind nur unter Android verfügbar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
