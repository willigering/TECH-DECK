class Flashcard {
  const Flashcard({
    required this.id,
    required this.topicId,
    required this.question,
    required this.answer,
  });

  final String id;
  final String topicId;
  final String question;
  final String answer;

  Map<String, Object?> toMap() => {
    'id': id,
    'topic_id': topicId,
    'question': question,
    'answer': answer,
  };

  factory Flashcard.fromMap(Map<String, Object?> map) {
    return Flashcard(
      id: map['id'] as String,
      topicId: map['topic_id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
    );
  }
}
