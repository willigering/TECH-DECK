import 'dart:math';

import '../data/models/flashcard.dart';
import '../data/models/quiz.dart';
import 'distractor_validator.dart';
import 'question_normalizer.dart';

/// Quizfragen nur aus gespeicherten Distraktoren derselben Karte.
/// Keine Antworten anderer Karten, keine KI beim Quizstart.
class QuizGenerator {
  QuizGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<QuizQuestion> generate(List<Flashcard> cards, int count) {
    if (cards.isEmpty || count <= 0) return const [];

    final ready = cards.where(isQuizReady).toList()..shuffle(_random);
    final questions = <QuizQuestion>[];
    final usedIds = <String>{};
    final usedQuestions = <String>[];

    for (final card in ready) {
      if (questions.length >= count) break;
      if (!usedIds.add(card.id)) continue;
      if (_isDuplicatePrompt(card.question, usedQuestions)) continue;
      final question = questionFor(card);
      if (question == null) continue;
      if (question.choices.length != 4) continue;
      if (question.choices.where((c) => c.isCorrect).length != 1) continue;
      usedQuestions.add(card.question);
      questions.add(question);
    }
    return questions;
  }

  QuizQuestion? questionFor(Flashcard card) {
    final choices = validatedChoices(card);
    if (choices == null) return null;
    final shuffled = List<QuizOption>.from(choices)..shuffle(_random);
    if (shuffled.length != 4) return null;
    if (shuffled.where((c) => c.isCorrect).length != 1) return null;
    final correct = shuffled.singleWhere((c) => c.isCorrect);
    if (correct.text.trim() != card.answer.trim()) return null;
    return QuizQuestion(
      cardId: card.id,
      prompt: card.question.trim(),
      correctAnswer: card.answer.trim(),
      choices: shuffled,
    );
  }

  static bool isQuizReady(Flashcard card) =>
      DistractorValidator.isQuizReady(card);

  static List<QuizOption>? validatedChoices(Flashcard card) {
    return DistractorValidator.storedChoices(card);
  }

  static bool _isDuplicatePrompt(String question, List<String> used) {
    for (final existing in used) {
      if (QuestionNormalizer.areDuplicates(question, existing)) return true;
    }
    return false;
  }
}
