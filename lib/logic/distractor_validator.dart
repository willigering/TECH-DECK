import '../data/csv/csv_parser.dart';
import '../data/models/flashcard.dart';
import '../data/models/quiz.dart';
import 'question_normalizer.dart';

class DistractorCheck {
  const DistractorCheck({this.structuralIssue, this.semanticIssues = const []});

  final String? structuralIssue;
  final List<String> semanticIssues;

  bool get ok => structuralIssue == null && semanticIssues.isEmpty;

  String? get firstIssue =>
      structuralIssue ?? (semanticIssues.isEmpty ? null : semanticIssues.first);
}

/// Strukturelle und lokale semantische Prüfung der drei Falschantworten.
///
/// Keine KI-Wahrheitsgarantie. Wenn der Bezug zur Frage nicht erkennbar ist,
/// gilt die Karte als nicht quizbereit.
abstract final class DistractorValidator {
  static const maxLength = 400;

  static final _junk = [
    RegExp(r'speichert ausschlie(ss|\u00df|ß)lich passw', caseSensitive: false),
    RegExp(
      r'vollst(ae|\u00e4|ä)ndiges backup aller dateien',
      caseSensitive: false,
    ),
    RegExp(r'm(ue|\u00fc|ü)ndliche absprache', caseSensitive: false),
    RegExp(r'stromversorgung eines rechners', caseSensitive: false),
    RegExp(
      r'l(oe|\u00f6|ö)scht dateien und einstellungen ohne nachfrage',
      caseSensitive: false,
    ),
    RegExp(r'startet alle systemdienste neu', caseSensitive: false),
    RegExp(r'(ä|ae|\u00e4)ndert den rechnernamen', caseSensitive: false),
    RegExp(r'blockiert jede anmeldung am system', caseSensitive: false),
    RegExp(
      r'bezeichnet ausschlie(ss|\u00df|ß)lich die stromversorgung',
      caseSensitive: false,
    ),
    RegExp(r'nur eine m(ue|\u00fc|ü)ndliche absprache', caseSensitive: false),
  ];

  static final _definitionStart = RegExp(
    r'^(?:Ein |Eine |Der |Die |Das )?'
    r'([A-Za-zÄÖÜäöü0-9][A-Za-zÄÖÜäöü0-9./+-]{1,40})'
    r'\s+(ist|sind|bedeutet|bezeichnet|umfasst|beschreibt|regelt|enthält)\b',
    caseSensitive: false,
  );

  static List<String>? normalizeThree(
    Iterable<String> raw,
    String correctAnswer,
  ) {
    return evaluate(
          question: '',
          correctAnswer: correctAnswer,
          wrongAnswers: raw,
          semantic: false,
        ).ok
        ? raw.map((e) => e.trim()).toList()
        : null;
  }

  static bool isStructurallyValid(Iterable<String> raw, String correctAnswer) {
    return evaluate(
      question: '',
      correctAnswer: correctAnswer,
      wrongAnswers: raw,
      semantic: false,
    ).ok;
  }

  static String? issueFor(Iterable<String> raw, String correctAnswer) {
    return evaluate(
      question: '',
      correctAnswer: correctAnswer,
      wrongAnswers: raw,
      semantic: false,
    ).firstIssue;
  }

  static bool isQuizReady(Flashcard card) => storedChoices(card) != null;

  static List<QuizOption>? storedChoices(Flashcard card) {
    if (card.question.trim().isEmpty) return null;
    final check = evaluate(
      question: card.question,
      correctAnswer: card.answer,
      wrongAnswers: card.wrongAnswers,
    );
    if (!check.ok) return null;
    final correct = card.answer.trim();
    final wrongs = card.wrongAnswers.map((e) => e.trim()).toList();
    return [
      QuizOption(text: correct, isCorrect: true),
      for (final wrong in wrongs) QuizOption(text: wrong, isCorrect: false),
    ];
  }

  static DistractorCheck evaluate({
    required String question,
    required String correctAnswer,
    required Iterable<String> wrongAnswers,
    bool semantic = true,
  }) {
    final correct = correctAnswer.trim();
    if (correct.isEmpty) {
      return const DistractorCheck(structuralIssue: 'Richtige Antwort fehlt.');
    }
    final items = wrongAnswers.map((e) => e.trim()).toList();
    if (items.length < 3 || items.any((e) => e.isEmpty)) {
      return const DistractorCheck(
        structuralIssue: 'Es fehlen drei falsche Antworten.',
      );
    }
    if (items.length > 3) {
      return const DistractorCheck(
        structuralIssue: 'Es sind mehr als drei falsche Antworten vorhanden.',
      );
    }
    final seen = <String>{CsvParser.normalizeKey(correct)};
    for (final text in items) {
      if (text.length > maxLength) {
        return const DistractorCheck(
          structuralIssue: 'Eine Antwort ist zu lang.',
        );
      }
      if (!seen.add(CsvParser.normalizeKey(text))) {
        return const DistractorCheck(
          structuralIssue: 'Antworten dürfen nicht doppelt vorkommen.',
        );
      }
    }
    if (!semantic || question.trim().isEmpty) {
      return const DistractorCheck();
    }

    final issues = <String>[];
    final kind = QuestionNormalizer.kindOf(question);
    final subject = QuestionNormalizer.subjectOf(question, correct);
    final correctHasNumber = _hasNumber(correct);
    final quantity =
        kind == QuestionKind.quantity ||
        (correctHasNumber && _looksLikeQuantityQuestion(question));

    for (var i = 0; i < items.length; i++) {
      final text = items[i];
      if (_isJunk(text)) {
        issues.add(
          'Falschantwort ${i + 1} ist eine fachfremde Standardfloskel.',
        );
        continue;
      }
      if (_leaksCorrect(text, correct)) {
        issues.add('Falschantwort ${i + 1} enthält die richtige Antwort.');
        continue;
      }
      if (quantity && correctHasNumber && !_hasNumber(text)) {
        issues.add(
          'Falschantwort ${i + 1} passt nicht zum Zahlenformat der Frage.',
        );
        continue;
      }
      if (_definesOtherTerm(text, subject, correct)) {
        issues.add('Falschantwort ${i + 1} definiert ein anderes Thema.');
        continue;
      }
      if (!_hasRelevance(text, question, correct, subject, quantity)) {
        issues.add(
          'Falschantwort ${i + 1} hat keinen erkennbaren Bezug zur Frage.',
        );
      }
    }

    for (var i = 0; i < items.length; i++) {
      for (var j = i + 1; j < items.length; j++) {
        if (QuestionNormalizer.areDuplicates(items[i], items[j])) {
          issues.add(
            'Die Falschantworten ${i + 1} und ${j + 1} sind zu ähnlich.',
          );
        }
      }
    }

    return DistractorCheck(semanticIssues: issues.toSet().toList());
  }

  static bool _looksLikeQuantityQuestion(String question) {
    final s = QuestionNormalizer.fold(question);
    return s.contains('wie viele') ||
        s.contains('wieviel') ||
        s.contains('aus wie vielen') ||
        s.contains('anzahl') ||
        s.contains('wie viele bit');
  }

  static bool _isJunk(String text) {
    return _junk.any((pattern) => pattern.hasMatch(text));
  }

  static bool _hasNumber(String text) => RegExp(r'\d').hasMatch(text);

  static bool _leaksCorrect(String wrong, String correct) {
    final w = QuestionNormalizer.normalize(wrong);
    final c = QuestionNormalizer.normalize(correct);
    if (w == c) return true;
    if (c.length < 24) return false;
    return w.contains(c) && w.length > c.length + 8;
  }

  static bool _definesOtherTerm(String text, String subject, String correct) {
    final def = _definitionStart.firstMatch(text.trim());
    if (def == null) return false;
    final other = def.group(1)!;
    if (QuestionNormalizer.mentionsSubject(other, subject)) return false;
    if (QuestionNormalizer.mentionsSubject(correct, other)) return false;
    if (QuestionNormalizer.mentionsSubject(text, subject)) return false;
    return true;
  }

  static bool _hasRelevance(
    String text,
    String question,
    String correct,
    String subject,
    bool quantity,
  ) {
    if (QuestionNormalizer.mentionsSubject(text, subject)) return true;
    if (quantity && _hasNumber(text) && _hasNumber(correct)) return true;

    final overlap = QuestionNormalizer.significantTokens(
      text,
    ).intersection(QuestionNormalizer.significantTokens(correct));
    if (overlap.length >= 2) return true;
    if (overlap.length == 1 && text.trim().length <= 48) return true;

    final qOverlap = QuestionNormalizer.significantTokens(
      text,
    ).intersection(QuestionNormalizer.significantTokens(question));
    if (qOverlap.length >= 2) return true;

    if (_similarLength(text, correct) &&
        _hasNumber(text) &&
        _hasNumber(correct)) {
      return true;
    }
    return false;
  }

  static bool _similarLength(String a, String b) {
    final x = a.trim().length;
    final y = b.trim().length;
    if (x == 0 || y == 0) return false;
    final ratio = x < y ? x / y : y / x;
    return ratio >= 0.35;
  }
}
