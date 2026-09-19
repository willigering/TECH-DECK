class QuizOption {
  const QuizOption({required this.text, required this.isCorrect});

  final String text;
  final bool isCorrect;
}

class QuizQuestion {
  QuizQuestion({
    required this.cardId,
    required this.prompt,
    required this.correctAnswer,
    required List<QuizOption> choices,
  }) : choices = List<QuizOption>.unmodifiable(choices);

  final String cardId;
  final String prompt;
  final String correctAnswer;
  final List<QuizOption> choices;

  List<String> get options => choices.map((c) => c.text).toList();

  int get correctIndex => choices.indexWhere((c) => c.isCorrect);
}

enum QuizVerdict { unanswered, correct, wrong, skipped }

class QuizAnswerRecord {
  const QuizAnswerRecord({
    required this.question,
    required this.selectedIndex,
    required this.verdict,
  });

  final QuizQuestion question;
  final int? selectedIndex;
  final QuizVerdict verdict;

  String? get selectedAnswer {
    final i = selectedIndex;
    if (i == null || i < 0 || i >= question.options.length) return null;
    return question.options[i];
  }

  Map<String, Object?> toJson() => {
        'cardId': question.cardId,
        'prompt': question.prompt,
        'correctAnswer': question.correctAnswer,
        'options': question.options,
        'correctIndex': question.correctIndex,
        'selectedIndex': selectedIndex,
        'verdict': verdict.name,
      };

  factory QuizAnswerRecord.fromJson(Map<String, Object?> json) {
    final options = (json['options'] as List<dynamic>).cast<String>();
    final correctIndex = json['correctIndex'] as int? ?? 0;
    final choices = <QuizOption>[
      for (var i = 0; i < options.length; i++)
        QuizOption(text: options[i], isCorrect: i == correctIndex),
    ];
    return QuizAnswerRecord(
      question: QuizQuestion(
        cardId: json['cardId'] as String,
        prompt: json['prompt'] as String,
        correctAnswer: json['correctAnswer'] as String,
        choices: choices,
      ),
      selectedIndex: json['selectedIndex'] as int?,
      verdict: QuizVerdict.values.firstWhere(
        (v) => v.name == json['verdict'],
        orElse: () => QuizVerdict.unanswered,
      ),
    );
  }
}

class QuizSession {
  const QuizSession({
    required this.id,
    required this.topicId,
    required this.questionCount,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.completedAt,
    required this.records,
  });

  final String id;
  final String topicId;
  final int questionCount;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final DateTime completedAt;
  final List<QuizAnswerRecord> records;

  int get percent {
    if (questionCount == 0) return 0;
    return ((correctCount / questionCount) * 100).round();
  }
}
