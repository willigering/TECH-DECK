import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../state/deck_controller.dart';
import '../widgets/gold_button.dart';
import '../widgets/pcb_background.dart';
import 'learn_screen.dart';
import 'quiz_setup_screen.dart';

class TopicDetailScreen extends StatelessWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  static const routeName = 'topic-detail';

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    final topic = deck.topicById(topicId);

    if (topic == null) {
      return const PcbBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Thema nicht gefunden.')),
        ),
      );
    }

    final fileLabel = topic.sourceFilename.isNotEmpty
        ? topic.sourceFilename
        : topic.name;

    return PcbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Thema'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 64,
                  color: TdColors.gold,
                  shadows: [
                    Shadow(
                      color: TdColors.gold.withValues(alpha: 0.55),
                      blurRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  fileLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    letterSpacing: 1.2,
                    color: TdColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${topic.cardCount} ${topic.cardCount == 1 ? 'Karte' : 'Karten'}',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: TdColors.textMuted,
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Wähle einen Modus',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 16,
                    color: TdColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                _ModeButton(
                  title: 'LERNEN',
                  subtitle: 'Karteikarten lernen',
                  icon: Icons.menu_book_outlined,
                  onTap: topic.cardCount == 0
                      ? null
                      : () {
                          deck.selectTopic(topic.id);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LearnScreen(topicId: topic.id),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 12),
                _ModeButton(
                  title: 'QUIZ',
                  subtitle: 'Wissen testen',
                  icon: Icons.track_changes_outlined,
                  onTap: topic.cardCount == 0
                      ? null
                      : () {
                          deck.selectTopic(topic.id);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuizSetupScreen(topicId: topic.id),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GoldPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Icon(icon, size: 28, color: TdColors.gold),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 16,
                  letterSpacing: 2,
                  color: TdColors.gold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 14,
                  color: TdColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
