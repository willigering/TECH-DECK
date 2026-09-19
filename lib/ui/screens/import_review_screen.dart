import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../logic/import_analyzer.dart';
import '../../state/deck_controller.dart';
import '../widgets/gold_button.dart';
import '../widgets/pcb_background.dart';
import 'ai_preview_screen.dart';

class ImportReviewScreen extends StatelessWidget {
  const ImportReviewScreen({super.key, required this.analyses});

  final List<ImportAnalysis> analyses;

  int _sum(int Function(ImportAnalysis a) pick) =>
      analyses.fold(0, (n, a) => n + pick(a));

  @override
  Widget build(BuildContext context) {
    final cards = _sum((a) => a.importedCandidates);
    final ready = _sum((a) => a.quizReadyCount);
    final missing = _sum((a) => a.missingCount);
    final invalid = _sum((a) => a.invalidCount);
    final dupes = _sum((a) => a.duplicateCount);
    final faulty = _sum((a) => a.faultyCount);

    return PcbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('CSV-Import')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                GoldPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IMPORTANALYSE',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          letterSpacing: 2,
                          color: TdColors.gold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _row('Karten mit Frage und Antwort', '$cards'),
                      _row('Vollständige Quizkarten', '$ready'),
                      _row('Ohne falsche Antworten', '$missing'),
                      _row('Ungültige Distraktoren', '$invalid'),
                      _row('Doppelte Fragen', '$dupes'),
                      _row('Fehlerhafte Zeilen', '$faulty'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (dupes + invalid + missing > 0)
                  Expanded(
                    child: ListView(
                      children: [
                        const Text(
                          'ZUR PRÜFUNG',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 11,
                            letterSpacing: 1.6,
                            color: TdColors.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final analysis in analyses)
                          for (final card in analysis.cards)
                            if (card.state != ImportCardState.quizReady)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GoldPanel(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.question,
                                        style: const TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: TdColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        card.issue ?? _stateLabel(card.state),
                                        style: const TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontSize: 14,
                                          color: TdColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(height: 10),
                GoldButton(
                  label: 'NUR ALS LERNKARTEN',
                  filled: false,
                  onTap: () => _commit(context, learnOnly: true),
                ),
                const SizedBox(height: 10),
                GoldButton(
                  label: 'FEHLENDE MIT KI ERSTELLEN',
                  enabled: missing + invalid > 0,
                  onTap: missing + invalid > 0
                      ? () => _openAi(context, AiPreviewMode.generateMissing)
                      : null,
                ),
                const SizedBox(height: 10),
                GoldButton(
                  label: 'VORHANDENE PRÜFEN LASSEN',
                  filled: false,
                  enabled: ready > 0,
                  onTap: ready > 0
                      ? () => _openAi(context, AiPreviewMode.reviewExisting)
                      : null,
                ),
                const SizedBox(height: 10),
                GoldButton(
                  label: 'WIE VORHANDEN IMPORTIEREN',
                  filled: false,
                  onTap: () => _commit(context, learnOnly: false),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ABBRECHEN',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      letterSpacing: 2,
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

  String _stateLabel(ImportCardState state) {
    return switch (state) {
      ImportCardState.missingDistractors => 'Keine falschen Antworten.',
      ImportCardState.invalidDistractors => 'Falschantworten ungeeignet.',
      ImportCardState.duplicateQuestion => 'Doppelte oder sehr ähnliche Frage.',
      ImportCardState.quizReady => 'Quizbereit.',
    };
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 16,
                color: TdColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 14,
              color: TdColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAi(BuildContext context, AiPreviewMode mode) async {
    final summary = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => AiPreviewScreen(analyses: analyses, mode: mode),
      ),
    );
    if (!context.mounted || summary == null) return;
    Navigator.of(context).pop(summary);
  }

  Future<void> _commit(BuildContext context, {required bool learnOnly}) async {
    final summary = await context.read<DeckController>().commitAnalyses(
      analyses,
      learnOnly: learnOnly,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop(summary);
  }
}
