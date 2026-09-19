import '../data/csv/csv_parser.dart';

enum ImportCardState {
  quizReady,
  missingDistractors,
  invalidDistractors,
  duplicateQuestion,
}

class ImportCardDraft {
  ImportCardDraft({
    required this.question,
    required this.answer,
    required this.wrongAnswers,
    required this.state,
    this.issue,
    this.aiSuggestion,
  });

  final String question;
  final String answer;
  List<String> wrongAnswers;
  ImportCardState state;
  String? issue;
  List<String>? aiSuggestion;

  bool get hasCompleteDistractors =>
      state == ImportCardState.quizReady ||
      (aiSuggestion != null && aiSuggestion!.length == 3);
}

class ImportAnalysis {
  const ImportAnalysis({
    required this.filename,
    required this.topicName,
    required this.cards,
    required this.skippedEmptyQuestion,
    required this.skippedEmptyAnswer,
    required this.delimiter,
  });

  final String filename;
  final String topicName;
  final List<ImportCardDraft> cards;
  final int skippedEmptyQuestion;
  final int skippedEmptyAnswer;
  final String delimiter;

  int get importedCandidates => cards.length;
  int get quizReadyCount =>
      cards.where((c) => c.state == ImportCardState.quizReady).length;
  int get missingCount =>
      cards.where((c) => c.state == ImportCardState.missingDistractors).length;
  int get invalidCount =>
      cards.where((c) => c.state == ImportCardState.invalidDistractors).length;
  int get duplicateCount =>
      cards.where((c) => c.state == ImportCardState.duplicateQuestion).length;
  int get faultyCount => skippedEmptyQuestion + skippedEmptyAnswer + invalidCount;
}

abstract final class ImportAnalyzer {
  static ImportAnalysis fromParse({
    required String filename,
    required CsvParseResult parsed,
  }) {
    final seenQuestions = <String, int>{};
    final drafts = <ImportCardDraft>[];
    for (final card in parsed.cards) {
      final qKey = CsvParser.normalizeKey(card.question);
      seenQuestions[qKey] = (seenQuestions[qKey] ?? 0) + 1;
    }

    for (final card in parsed.cards) {
      final qKey = CsvParser.normalizeKey(card.question);
      final wrongs = card.wrongAnswers.map((e) => e.trim()).toList();
      final filled = wrongs.where((e) => e.isNotEmpty).toList();
      ImportCardState state;
      String? issue;
      if ((seenQuestions[qKey] ?? 0) > 1) {
        state = ImportCardState.duplicateQuestion;
        issue = 'Diese Frage kommt in der Datei mehrfach vor.';
      } else if (filled.isEmpty) {
        state = ImportCardState.missingDistractors;
        issue = 'Keine falschen Antworten vorhanden.';
      } else {
        final problem = _distractorIssue(filled, card.answer);
        if (problem == null && filled.length == 3) {
          state = ImportCardState.quizReady;
        } else {
          state = ImportCardState.invalidDistractors;
          issue = problem ?? 'Falsche Antworten sind unvollständig.';
        }
      }
      drafts.add(
        ImportCardDraft(
          question: card.question,
          answer: card.answer,
          wrongAnswers: wrongs,
          state: state,
          issue: issue,
        ),
      );
    }

    return ImportAnalysis(
      filename: filename,
      topicName: CsvParser.topicNameFromFilename(filename),
      cards: drafts,
      skippedEmptyQuestion: parsed.skippedEmptyQuestion,
      skippedEmptyAnswer: parsed.skippedEmptyAnswer,
      delimiter: parsed.delimiter,
    );
  }

  static String? _distractorIssue(List<String> filled, String correct) {
    if (filled.length != 3) return 'Es fehlen drei falsche Antworten.';
    final seen = <String>{CsvParser.normalizeKey(correct)};
    for (final text in filled) {
      if (text.isEmpty) return 'Eine falsche Antwort ist leer.';
      if (!seen.add(CsvParser.normalizeKey(text))) {
        return 'Antworten dürfen nicht doppelt vorkommen.';
      }
    }
    return null;
  }
}
