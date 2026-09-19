import '../data/csv/csv_parser.dart';
import '../data/models/flashcard.dart';
import '../data/models/quiz.dart';

/// Strukturelle Prüfung der drei Falschantworten einer Karte.
/// Keine fachliche KI-Garantie — nur Duplikate, Leere und Format.
abstract final class DistractorValidator {
  static const maxLength = 400;

  static List<String>? normalizeThree(
    Iterable<String> raw,
    String correctAnswer,
  ) {
    final correct = correctAnswer.trim();
    if (correct.isEmpty) return null;
    final seen = <String>{CsvParser.normalizeKey(correct)};
    final out = <String>[];
    for (final item in raw) {
      final text = item.trim();
      if (text.isEmpty) return null;
      if (text.length > maxLength) return null;
      if (!seen.add(CsvParser.normalizeKey(text))) return null;
      out.add(text);
    }
    if (out.length != 3) return null;
    return out;
  }

  static bool isStructurallyValid(Iterable<String> raw, String correctAnswer) {
    return normalizeThree(raw, correctAnswer) != null;
  }

  static String? issueFor(Iterable<String> raw, String correctAnswer) {
    final correct = correctAnswer.trim();
    if (correct.isEmpty) return 'Richtige Antwort fehlt.';
    final items = raw.map((e) => e.trim()).toList();
    if (items.length < 3 || items.any((e) => e.isEmpty)) {
      return 'Es fehlen drei falsche Antworten.';
    }
    if (items.length > 3) return 'Es sind mehr als drei falsche Antworten vorhanden.';
    final seen = <String>{CsvParser.normalizeKey(correct)};
    for (final text in items) {
      if (text.length > maxLength) return 'Eine Antwort ist zu lang.';
      if (!seen.add(CsvParser.normalizeKey(text))) {
        return 'Antworten dürfen nicht doppelt vorkommen.';
      }
    }
    return null;
  }

  static List<QuizOption>? storedChoices(Flashcard card) {
    if (card.question.trim().isEmpty) return null;
    final correct = card.answer.trim();
    final wrongs = normalizeThree(card.wrongAnswers, correct);
    if (wrongs == null) return null;
    return [
      QuizOption(text: correct, isCorrect: true),
      for (final wrong in wrongs) QuizOption(text: wrong, isCorrect: false),
    ];
  }
}
