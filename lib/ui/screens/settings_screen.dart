import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_info.dart';
import '../../state/deck_controller.dart';
import '../../state/theme_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/topic_mark_sheet.dart';
import '../widgets/topic_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _import(BuildContext context) async {
    final summary = await context.read<DeckController>().importCsv();
    if (!context.mounted || summary == null) return;
    final message = summary.outcomes.any((o) => !o.ok)
        ? 'Import mit Fehlern.'
        : '${summary.filesOk} Datei(en) · ${summary.cardsImported} Karten neu · ${summary.duplicates} Duplikate übersprungen';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteTopic(BuildContext context, String id, String name) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thema löschen?'),
        content: Text('"$name" und alle zugehörigen Karten werden entfernt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ABBRECHEN')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('OK', style: TextStyle(color: cs.primary))),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<DeckController>().deleteTopic(id);
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    final themes = context.watch<ThemeController>();
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const SectionLabel('EINSTELLUNGEN'),
          const SizedBox(height: 20),
          const SectionLabel('ERSCHEINUNGSBILD'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              _ThemeChip(choice: TdThemeChoice.darkGold, label: 'Dark / Gold', icon: Icons.dark_mode_outlined, selected: themes.choice == TdThemeChoice.darkGold),
              _ThemeChip(choice: TdThemeChoice.lightGold, label: 'Light / Gold', icon: Icons.light_mode_outlined, selected: themes.choice == TdThemeChoice.lightGold),
              _ThemeChip(choice: TdThemeChoice.oledBlack, label: 'OLED Black', icon: Icons.phone_android, selected: themes.choice == TdThemeChoice.oledBlack),
              _ThemeChip(choice: TdThemeChoice.cyberBlue, label: 'Cyber Blue', icon: Icons.memory_outlined, selected: themes.choice == TdThemeChoice.cyberBlue),
              _ThemeChip(choice: TdThemeChoice.terminalGreen, label: 'Terminal Green', icon: Icons.terminal_rounded, selected: themes.choice == TdThemeChoice.terminalGreen),
              _ThemeChip(choice: TdThemeChoice.violetNeon, label: 'Violet / Neon', icon: Icons.auto_awesome_outlined, selected: themes.choice == TdThemeChoice.violetNeon),
            ],
          ),
          const SizedBox(height: 8),
          Text('Dark / Gold ist beim ersten Start der Standard. Deine Auswahl wird danach gespeichert.',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          GoldButton(label: 'LERNKARTEN IMPORTIEREN', icon: Icons.file_upload_outlined, onTap: () => _import(context)),
          const SizedBox(height: 10),
          Text('Importiere eigene Lernkarten als .csv oder .md. Eine Datei entspricht einem Thema. Die Anleitung findest du im Tab „Anleitung“.',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          const SectionLabel('THEMEN VERWALTEN'),
          const SizedBox(height: 8),
          Text(
            'Tippen: Farbe und Wichtig. Lange drücken geht auch in der Themenliste.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          if (deck.topics.isEmpty)
            const GoldPanel(child: Text('Keine Themen vorhanden.', textAlign: TextAlign.center))
          else
            for (final t in deck.topics) ...[
              TopicTile(
                topic: t,
                onTap: () => showTopicMarkSheet(context, t),
                onLongPress: () => showTopicMarkSheet(context, t),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  onPressed: () => _deleteTopic(context, t.id, t.name),
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 22),
          GoldPanel(
            glow: false,
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: cs.primary),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppInfo.name, style: TextStyle(fontFamily:'Orbitron',fontWeight:FontWeight.w700,color:cs.primary)),
                const SizedBox(height: 4),
                Text('Version ${AppInfo.version} · Build ${AppInfo.buildNumber}', style: Theme.of(context).textTheme.bodyMedium),
                Text('Entwickelt von ${AppInfo.developer}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 3),
                Text(AppInfo.description, style: Theme.of(context).textTheme.bodySmall),
              ])),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.choice, required this.label, required this.icon, required this.selected});
  final TdThemeChoice choice;
  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.read<ThemeController>().setTheme(choice),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 104, height: 86,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha:.13) : cs.surface.withValues(alpha:.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha:.45), width: selected ? 1.7 : 1),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(selected ? Icons.check_circle_rounded : icon, color: cs.primary, size: 23),
          const SizedBox(height: 7),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontFamily:'Rajdhani',fontWeight:FontWeight.w700,fontSize:13,color:cs.onSurface)),
        ]),
      ),
    );
  }
}
