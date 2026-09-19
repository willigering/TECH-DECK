import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<DeckController>().stats;
    if (stats == null) {
      return const Center(
        child: CircularProgressIndicator(color: TdColors.gold),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const BrandHeader(compact: true),
          const SizedBox(height: 22),
          const SectionLabel('STATISTIK'),
          const SizedBox(height: 14),
          GoldPanel(
            child: Column(
              children: [
                _row('GELERNTE KARTEN', '${stats.learnedCards} / ${stats.totalCards}'),
                const Divider(color: TdColors.goldLine),
                _row('ABSOLVIERTE QUIZZE', '${stats.quizzesCompleted}'),
                const Divider(color: TdColors.goldLine),
                _row('RICHTIGE ANTWORTEN', '${stats.correctAnswers}'),
                const Divider(color: TdColors.goldLine),
                _row('FALSCHE ANTWORTEN', '${stats.wrongAnswers}'),
                const Divider(color: TdColors.goldLine),
                _row('ÜBERSPRUNGEN', '${stats.skippedAnswers}'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GoldPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LERNFORTSCHRITT',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    letterSpacing: 2,
                    color: TdColors.gold,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: stats.learnProgress,
                    minHeight: 8,
                    backgroundColor: TdColors.goldDeep,
                    color: TdColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(stats.learnProgress * 100).round()} % der Karten gesehen',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 16,
                    color: TdColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionLabel('PRO THEMA'),
          const SizedBox(height: 14),
          if (stats.perTopic.isEmpty)
            const GoldPanel(
              child: Text(
                'Noch keine Themen importiert.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final t in stats.perTopic) ...[
              GoldPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        color: TdColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: t.learnProgress,
                        minHeight: 6,
                        backgroundColor: TdColors.goldDeep,
                        color: TdColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${t.seenCards} / ${t.totalCards} gesehen  ·  '
                      '${t.quizzesCompleted} Quizze  ·  '
                      '${(t.accuracy * 100).round()} % Quiz',
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 15,
                        color: TdColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                letterSpacing: 1.4,
                color: TdColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 16,
              color: TdColors.goldBright,
            ),
          ),
        ],
      ),
    );
  }
}
