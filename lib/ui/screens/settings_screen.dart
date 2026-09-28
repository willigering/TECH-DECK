import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/topic_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _import(BuildContext context) async {
    final summary = await context.read<DeckController>().importCsv();
    if (!context.mounted || summary == null) return;
    final message = summary.outcomes.any((o) => !o.ok)
        ? 'Import mit Fehlern.'
        : '${summary.filesOk} Datei(en) · ${summary.cardsImported} Karten neu · '
            '${summary.duplicates} Duplikate übersprungen';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteTopic(BuildContext context, String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TdColors.bgPanel,
        title: const Text('Thema löschen?', style: TextStyle(fontFamily: 'Orbitron', color: TdColors.gold)),
        content: Text('"$name" und alle zugehörigen Karten werden entfernt.',
            style: const TextStyle(color: TdColors.text)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ABBRECHEN')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK', style: TextStyle(color: TdColors.gold))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<DeckController>().deleteTopic(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const SectionLabel('EINSTELLUNGEN'),
          const SizedBox(height: 16),
          GoldButton(
            label: 'LERNKARTEN IMPORTIEREN',
            icon: Icons.file_upload_outlined,
            onTap: () => _import(context),
          ),
          const SizedBox(height: 10),
          const Text(
            'Importiere eigene Lernkarten als .csv oder .md. Eine Datei entspricht einem Thema; '
            'der Dateiname wird zum Themennamen. Eine genaue Anleitung und einen KI-Prompt findest du im Tab „Anleitung“.',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 15, color: TdColors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 28),
          const SectionLabel('THEMEN VERWALTEN'),
          const SizedBox(height: 14),
          if (deck.topics.isEmpty)
            const GoldPanel(child: Text('Keine Themen vorhanden.', textAlign: TextAlign.center))
          else
            for (final t in deck.topics) ...[
              TopicTile(
                topic: t,
                onTap: () {},
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: TdColors.danger),
                  onPressed: () => _deleteTopic(context, t.id, t.name),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
