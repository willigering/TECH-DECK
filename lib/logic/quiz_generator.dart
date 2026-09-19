import 'dart:math';

import '../data/csv/csv_parser.dart';
import '../data/models/flashcard.dart';
import '../data/models/quiz.dart';
import 'distractor_validator.dart';

/// Quizfragen nur aus gespeicherten Distraktoren derselben Karte.
/// Keine Antworten anderer Karten, keine KI beim Quizstart.
class QuizGenerator {
  QuizGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<QuizQuestion> generate(List<Flashcard> cards, int count) {
    if (cards.isEmpty || count <= 0) return const [];

    final eligible = <Flashcard>[];
    final seenIds = <String>{};
    final seenPrompts = <String>{};
    for (final card in cards) {
      if (!seenIds.add(card.id)) continue;
      final promptKey = CsvParser.normalizeKey(card.question);
      if (!seenPrompts.add(promptKey)) continue;
      if (isQuizReady(card)) eligible.add(card);
    }
    eligible.shuffle(_random);
    final take = min(count, eligible.length);

    final questions = <QuizQuestion>[];
    final usedIds = <String>{};
    for (final card in eligible.take(take)) {
      if (!usedIds.add(card.id)) continue;
      final question = questionFor(card);
      if (question != null) questions.add(question);
    }
    return questions;
  }

  QuizQuestion? questionFor(Flashcard card) {
    final choices = validatedChoices(card);
    if (choices == null) return null;
    final shuffled = List<QuizOption>.from(choices)..shuffle(_random);
    if (shuffled.where((c) => c.isCorrect).length != 1) return null;
    return QuizQuestion(
      cardId: card.id,
      prompt: card.question.trim(),
      correctAnswer: card.answer.trim(),
      choices: shuffled,
    );
  }

  static bool isQuizReady(Flashcard card) =>
      DistractorValidator.storedChoices(card) != null;

  static List<QuizOption>? validatedChoices(Flashcard card) {
    return DistractorValidator.storedChoices(card);
  }
}
