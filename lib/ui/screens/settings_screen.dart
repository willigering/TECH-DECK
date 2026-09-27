import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../data/csv/csv_importer.dart';
import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/topic_tile.dart';
import 'import_review_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _import() async {
    final analyses = await context.read<DeckController>().pickAndAnalyzeCsv();
    if (!mounted || analyses == null) return;
    final summary = await Navigator.of(context).push<ImportSummary>(
      MaterialPageRoute(builder: (_) => ImportReviewScreen(analyses: analyses)),
    );
    if (!mounted || summary == null) return;
    _toast(
      '${summary.filesOk} Datei(en) · ${summary.cardsImported} Karten neu · '
      '${summary.duplicates} Duplikate',
    );
  }

  Future<void> _deleteTopic(String id, String name) async {
    final ok = await _confirm(
      'Thema löschen?',
      '"$name" und alle zugehörigen Karten werden entfernt.',
    );
    if (ok != true || !mounted) return;
    await context.read<DeckController>().deleteTopic(id);
  }

  Future<bool?> _confirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TdColors.bgPanel,
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Orbitron', color: TdColors.gold),
        ),
        content: Text(body, style: const TextStyle(color: TdColors.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK', style: TextStyle(color: TdColors.gold)),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            label: 'CSV IMPORTIEREN',
            icon: Icons.file_upload_outlined,
            onTap: _import,
          ),
          const SizedBox(height: 10),
          const Text(
            'Eine CSV-Datei entspricht genau einem Thema. '
            'Der Dateiname (ohne .csv) wird zum Themennamen. '
            'Die Reihenfolge bleibt die Importreihenfolge.',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 15,
              color: TdColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),
          const SectionLabel('THEMEN VERWALTEN'),
          const SizedBox(height: 14),
          if (deck.topics.isEmpty)
            const GoldPanel(
              child: Text(
                'Keine Themen vorhanden.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final t in deck.topics) ...[
              TopicTile(
                topic: t,
                onTap: () {},
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: TdColors.danger,
                  ),
                  onPressed: () => _deleteTopic(t.id, t.name),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
