import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/topic_tile.dart';
import 'learn_screen.dart';
import 'quiz_setup_screen.dart';

enum TopicPickerMode { learn, quiz }

class TopicPickerScreen extends StatelessWidget {
  const TopicPickerScreen({super.key, required this.mode});

  static const routeName = 'topic-picker';

  final TopicPickerMode mode;

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    final title = mode == TopicPickerMode.learn ? 'LERNEN' : 'QUIZ';
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
                children: const [
                  Text(
                    'Keine Themen vorhanden.',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 18,
                      color: TdColors.text,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Importiere zuerst CSV-Dateien unter Einstellungen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TdColors.textMuted),
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
                            builder: (_) => mode == TopicPickerMode.learn
                                ? LearnScreen(topicId: topic.id)
                                : QuizSetupScreen(topicId: topic.id),
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
