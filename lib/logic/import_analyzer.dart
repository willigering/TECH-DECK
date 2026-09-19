import '../data/csv/csv_parser.dart';
import 'distractor_validator.dart';
import 'question_normalizer.dart';

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
  int get faultyCount =>
      skippedEmptyQuestion + skippedEmptyAnswer + invalidCount;
}

abstract final class ImportAnalyzer {
  static ImportAnalysis fromParse({
    required String filename,
    required CsvParseResult parsed,
  }) {
    final drafts = <ImportCardDraft>[];
    final keptQuestions = <String>[];

    for (final card in parsed.cards) {
      final wrongs = card.wrongAnswers.map((e) => e.trim()).toList();
      final filled = wrongs.where((e) => e.isNotEmpty).toList();
      ImportCardState state;
      String? issue;

      final duplicateOf = _duplicateOf(card.question, keptQuestions);
      if (duplicateOf != null) {
        state = ImportCardState.duplicateQuestion;
        issue = 'Ähnliche Frage bereits in der Datei: „$duplicateOf“';
      } else if (filled.isEmpty) {
        state = ImportCardState.missingDistractors;
        issue = 'Keine falschen Antworten vorhanden.';
        keptQuestions.add(card.question);
      } else {
        final check = DistractorValidator.evaluate(
          question: card.question,
          correctAnswer: card.answer,
          wrongAnswers: filled,
        );
        if (check.ok && filled.length == 3) {
          state = ImportCardState.quizReady;
        } else {
          state = ImportCardState.invalidDistractors;
          issue = check.firstIssue ?? 'Falsche Antworten sind unvollständig.';
        }
        keptQuestions.add(card.question);
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

  static String? _duplicateOf(String question, List<String> kept) {
    for (final existing in kept) {
      if (QuestionNormalizer.areDuplicates(question, existing)) {
        return existing;
      }
    }
    return null;
  }
}
