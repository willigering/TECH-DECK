class Flashcard {
  const Flashcard({
    required this.id,
    required this.topicId,
    required this.question,
    required this.answer,
    this.wrongAnswer1 = '',
    this.wrongAnswer2 = '',
    this.wrongAnswer3 = '',
    this.aiStatus = 'none',
    this.updatedAt,
    this.isFavorite = false,
    this.timesSeen = 0,
    this.lastSeen,
  });

  final String id;
  final String topicId;
  final String question;
  final String answer;
  final String wrongAnswer1;
  final String wrongAnswer2;
  final String wrongAnswer3;

  /// none | suggested | accepted | rejected
  /// accepted = Nutzer hat Distraktoren bestätigt, keine KI-Wahrheitsgarantie.
  final String aiStatus;
  final DateTime? updatedAt;
  final bool isFavorite;
  final int timesSeen;
  final DateTime? lastSeen;

  bool get isLearned => timesSeen > 0;

  bool get aiReviewed => aiStatus == 'accepted';

  /// Nur strukturell vollständig. Quizfähigkeit prüft [DistractorValidator].
  bool get hasThreeWrongAnswers {
    if (question.trim().isEmpty || answer.trim().isEmpty) return false;
    final wrongs = wrongAnswers.map((e) => e.trim()).toList();
    if (wrongs.length != 3 || wrongs.any((e) => e.isEmpty)) return false;
    final keys = <String>{answer.trim().toLowerCase()};
    for (final wrong in wrongs) {
      if (!keys.add(wrong.toLowerCase())) return false;
    }
    return true;
  }

  bool get quizReady => hasThreeWrongAnswers;

  /// Die drei CSV-Distraktoren in Spaltenreihenfolge, ungefiltert.
  List<String> get wrongAnswers => [wrongAnswer1, wrongAnswer2, wrongAnswer3];

  Flashcard copyWith({
    String? id,
    String? topicId,
    String? question,
    String? answer,
    String? wrongAnswer1,
    String? wrongAnswer2,
    String? wrongAnswer3,
    String? aiStatus,
    DateTime? updatedAt,
    bool? isFavorite,
    int? timesSeen,
    DateTime? lastSeen,
  }) {
    return Flashcard(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      wrongAnswer1: wrongAnswer1 ?? this.wrongAnswer1,
      wrongAnswer2: wrongAnswer2 ?? this.wrongAnswer2,
      wrongAnswer3: wrongAnswer3 ?? this.wrongAnswer3,
      aiStatus: aiStatus ?? this.aiStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      timesSeen: timesSeen ?? this.timesSeen,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'topic_id': topicId,
    'question': question,
    'answer': answer,
    'wrong_answer_1': wrongAnswer1,
    'wrong_answer_2': wrongAnswer2,
    'wrong_answer_3': wrongAnswer3,
    'ai_status': aiStatus,
    'updated_at': updatedAt?.millisecondsSinceEpoch,
    'is_favorite': isFavorite ? 1 : 0,
    'times_seen': timesSeen,
    'last_seen': lastSeen?.millisecondsSinceEpoch,
  };

  factory Flashcard.fromMap(Map<String, Object?> map) {
    final last = map['last_seen'] as int?;
    return Flashcard(
      id: map['id'] as String,
      topicId: map['topic_id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      wrongAnswer1: map['wrong_answer_1'] as String? ?? '',
      wrongAnswer2: map['wrong_answer_2'] as String? ?? '',
      wrongAnswer3: map['wrong_answer_3'] as String? ?? '',
      aiStatus: map['ai_status'] as String? ?? 'none',
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      timesSeen: map['times_seen'] as int? ?? 0,
      lastSeen: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
    );
  }
}
