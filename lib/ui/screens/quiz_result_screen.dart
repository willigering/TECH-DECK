import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../data/models/quiz.dart';
import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/pcb_background.dart';
import 'quiz_play_screen.dart';
import 'quiz_review_screen.dart';
import 'topic_picker_screen.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key, required this.session});

  final QuizSession session;

  @override
  Widget build(BuildContext context) {
    context.watch<DeckController>();

    return PcbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Quiz Auswertung'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                const Text(
                  'Quiz abgeschlossen!',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: TdColors.text,
                  ),
                ),
                const SizedBox(height: 22),
                PercentRing(
                  percent: session.percent,
                  caption:
                      '${session.correctCount} / ${session.questionCount} richtig',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'Richtig',
                        value: '${session.correctCount}',
                        color: TdColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        label: 'Falsch',
                        value: '${session.wrongCount}',
                        color: TdColors.danger,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        label: 'Übersprungen',
                        value: '${session.skippedCount}',
                        color: TdColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GoldButton(
                  label: 'ERGEBNISSE ANSEHEN',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizReviewScreen(session: session),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GoldButton(
                  label: 'ERNEUT VERSUCHEN',
                  filled: false,
                  icon: Icons.refresh,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => QuizPlayScreen(
                        topicId: session.topicId,
                        questionCount: session.questionCount,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) {
                      return route.settings.name ==
                              TopicPickerScreen.routeName ||
                          route.isFirst;
                    });
                  },
                  child: const Text(
                    'ZURÜCK ZUM THEMA',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      letterSpacing: 1.6,
                      color: TdColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GoldPanel(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 8,
              letterSpacing: 0.8,
              color: TdColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 22,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
