import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../data/csv/csv_importer.dart';
import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/topic_tile.dart';
import 'topic_detail_screen.dart';

class TopicsHomeScreen extends StatefulWidget {
  const TopicsHomeScreen({super.key});

  @override
  State<TopicsHomeScreen> createState() => _TopicsHomeScreenState();
}

class _TopicsHomeScreenState extends State<TopicsHomeScreen> {
  Future<void> _import() async {
    final controller = context.read<DeckController>();
    final summary = await controller.importCsv();
    if (!mounted || summary == null) return;
    _showImportResult(summary);
  }

  void _showImportResult(ImportSummary summary) {
    final errors = summary.outcomes.where((o) => !o.ok).toList();
    final msg = errors.isNotEmpty
        ? 'Import mit Fehlern: ${errors.first.error}'
        : '${summary.filesOk} Datei(en) · ${summary.cardsImported} Karten neu · '
            '${summary.duplicates} Duplikate übersprungen';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    final topics = deck.topics;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const BrandHeader(showLogo: true),
          const SizedBox(height: 8),
          if (deck.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: TdColors.gold),
              ),
            )
          else if (topics.isEmpty) ...[
            GoldButton(
              label: 'CSV IMPORTIEREN',
              onTap: _import,
            ),
            const SizedBox(height: 12),
            const Text(
              'Eine CSV-Datei entspricht genau einem Thema.\n'
              'Der Dateiname wird zum Themennamen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 15,
                color: TdColors.textMuted,
              ),
            ),
          ] else ...[
            SectionLabel(
              'MEINE THEMEN',
              trailing: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _import,
                icon: const Icon(Icons.add_circle_outline, color: TdColors.gold),
              ),
            ),
            const Text(
              'Importierte CSVs',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 14,
                color: TdColors.textDim,
              ),
            ),
            const SizedBox(height: 12),
            for (final topic in topics) ...[
                TopicTile(
                  topic: topic,
                  onTap: () {
                    deck.selectTopic(topic.id);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(
                          name: TopicDetailScreen.routeName,
                        ),
                        builder: (_) => TopicDetailScreen(topicId: topic.id),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        ],
      ),
    );
  }
}
