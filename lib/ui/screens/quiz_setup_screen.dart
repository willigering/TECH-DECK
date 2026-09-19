import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../data/models/flashcard.dart';
import '../../logic/quiz_generator.dart';
import '../../state/deck_controller.dart';
import '../widgets/gold_button.dart';
import '../widgets/pcb_background.dart';
import 'quiz_play_screen.dart';

class QuizSetupScreen extends StatelessWidget {
  const QuizSetupScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    final topic = deck.topics.where((t) => t.id == topicId);
    if (topic.isEmpty) {
      return const PcbBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Thema nicht gefunden.')),
        ),
      );
    }
    final t = topic.first;

    return PcbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Quiz'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: FutureBuilder<List<Flashcard>>(
              future: deck.cardsFor(topicId),
              builder: (context, snapshot) {
                final cards = snapshot.data;
                final available = cards == null
                    ? t.cardCount
                    : cards.where(QuizGenerator.isQuizReady).length;

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Icon(
                      Icons.track_changes_outlined,
                      size: 72,
                      color: TdColors.gold,
                      shadows: [
                        Shadow(
                          color: TdColors.gold.withValues(alpha: 0.5),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Wähle die Anzahl\nder Fragen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: TdColors.text,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        cards == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: CircularProgressIndicator(color: TdColors.gold),
                      )
                    else if (available == 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Keine vollständigen Quizkarten in diesem Thema.\nJede Karte braucht eine richtige und drei falsche Antworten.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      )
                    else ...[
                      for (final n in [10, 15, 20]) ...[
                        GoldButton(
                          label: '$n FRAGEN',
                          filled: false,
                          enabled: n <= available,
                          onTap: n <= available
                              ? () => Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => QuizPlayScreen(
                                        topicId: topicId,
                                        questionCount: n,
                                      ),
                                    ),
                                  )
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (available < 10)
                        GoldButton(
                          label: 'ALLE $available FRAGEN',
                          filled: false,
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => QuizPlayScreen(
                                topicId: topicId,
                                questionCount: available,
                              ),
                            ),
                          ),
                        ),
                    ],
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'ABBRECHEN',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          letterSpacing: 2,
                          color: TdColors.gold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
