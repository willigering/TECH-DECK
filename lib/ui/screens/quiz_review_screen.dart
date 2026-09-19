import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../data/models/quiz.dart';
import '../widgets/gold_button.dart';
import '../widgets/pcb_background.dart';

class QuizReviewScreen extends StatelessWidget {
  const QuizReviewScreen({super.key, required this.session});

  final QuizSession session;

  @override
  Widget build(BuildContext context) {
    return PcbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('ERGEBNISSE'),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          itemCount: session.records.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final rec = session.records[i];
            final verdict = switch (rec.verdict) {
              QuizVerdict.correct => 'RICHTIG',
              QuizVerdict.wrong => 'FALSCH',
              QuizVerdict.skipped => 'ÜBERSPRUNGEN',
              QuizVerdict.unanswered => 'OFFEN',
            };
            final color = switch (rec.verdict) {
              QuizVerdict.correct => TdColors.goldBright,
              QuizVerdict.wrong => TdColors.danger,
              QuizVerdict.skipped => TdColors.textMuted,
              QuizVerdict.unanswered => TdColors.textDim,
            };
            return GoldPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'FRAGE ${i + 1}',
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          letterSpacing: 2,
                          color: TdColors.gold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        verdict,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          letterSpacing: 1.6,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rec.question.prompt,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: TdColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Deine Antwort: ${rec.selectedAnswer ?? '—'}',
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      color: TdColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Korrekt: ${rec.question.correctAnswer}',
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: TdColors.goldBright,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
