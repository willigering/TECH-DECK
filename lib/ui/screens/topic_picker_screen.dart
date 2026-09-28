import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/topic_tile.dart';
import 'learn_screen.dart';

class TopicPickerScreen extends StatelessWidget {
  const TopicPickerScreen({super.key});

  static const routeName = 'topic-picker';

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    const title = 'LERNEN';
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const BrandHeader(compact: true),
          const SizedBox(height: 22),
          SectionLabel('THEMA FÜR $title'),
          const SizedBox(height: 14),
          if (deck.topics.isEmpty)
            GoldPanel(
              child: Column(
                children: [
                  Text(
                    'Keine Themen vorhanden.',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Importiere zuerst CSV-Dateien unter Einstellungen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65)),
                  ),
                ],
              ),
            )
          else
            for (final topic in deck.topics) ...[
              TopicTile(
                topic: topic,
                onTap: topic.cardCount == 0
                    ? () {}
                    : () {
                        deck.selectTopic(topic.id);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LearnScreen(topicId: topic.id),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
