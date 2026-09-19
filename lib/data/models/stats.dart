class TopicProgress {
  const TopicProgress({
    required this.topicId,
    required this.name,
    required this.sortOrder,
    required this.totalCards,
    required this.seenCards,
    required this.favoriteCards,
    required this.quizzesCompleted,
    required this.correctAnswers,
    required this.wrongAnswers,
  });

  final String topicId;
  final String name;
  final int sortOrder;
  final int totalCards;
  final int seenCards;
  final int favoriteCards;
  final int quizzesCompleted;
  final int correctAnswers;
  final int wrongAnswers;

  double get learnProgress => totalCards == 0 ? 0 : seenCards / totalCards;

  int get answered => correctAnswers + wrongAnswers;

  double get accuracy => answered == 0 ? 0 : correctAnswers / answered;
}

class AppStats {
  const AppStats({
    required this.totalCards,
    required this.learnedCards,
    required this.quizzesCompleted,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.skippedAnswers,
    required this.perTopic,
  });

  final int totalCards;
  final int learnedCards;
  final int quizzesCompleted;
  final int correctAnswers;
  final int wrongAnswers;
  final int skippedAnswers;
  final List<TopicProgress> perTopic;

  double get learnProgress => totalCards == 0 ? 0 : learnedCards / totalCards;

  int get answered => correctAnswers + wrongAnswers;

  double get accuracy => answered == 0 ? 0 : correctAnswers / answered;
}
