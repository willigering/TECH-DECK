import 'package:flutter/foundation.dart';

import '../data/csv/csv_importer.dart';
import '../data/models/flashcard.dart';
import '../data/models/quiz.dart';
import '../data/models/stats.dart';
import '../data/models/topic.dart';
import '../data/repositories/deck_repository.dart';
import '../logic/import_analyzer.dart';

class DeckController extends ChangeNotifier {
  DeckController({DeckRepository? repository})
      : _repo = repository ?? DeckRepository();

  final DeckRepository _repo;

  List<Topic> _topics = const [];
  AppStats? _stats;
  bool _loading = true;
  String? _error;
  String? _selectedTopicId;

  List<Topic> get topics => _topics;
  AppStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedTopicId => _selectedTopicId;

  Topic? get selectedTopic => topicById(_selectedTopicId);

  Topic? topicById(String? id) {
    if (id == null) return null;
    for (final t in _topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.ensureBundledTopics();
      _topics = await _repo.loadTopics();
      _stats = await _repo.loadStats();
      if (_selectedTopicId != null &&
          !_topics.any((t) => t.id == _selectedTopicId)) {
        _selectedTopicId = null;
      }
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectTopic(String? id) {
    _selectedTopicId = id;
    notifyListeners();
  }

  Future<ImportSummary?> importCsv() async {
    try {
      final summary = await _repo.importCsvFiles();
      if (summary != null) {
        await load();
      }
      return summary;
    } catch (e) {
      _error = '$e';
      notifyListeners();
      return ImportSummary(
        outcomes: [
          ImportFileOutcome(
            filename: '',
            topicName: '',
            imported: 0,
            duplicates: 0,
            skipped: 0,
            error: '$e',
          ),
        ],
      );
    }
  }

  Future<List<ImportAnalysis>?> pickAndAnalyzeCsv() async {
    try {
      final files = await _repo.pickCsvFiles();
      if (files == null || files.isEmpty) return null;
      return _repo.analyzePickedFiles(files);
    } catch (e) {
      _error = '$e';
      notifyListeners();
      return null;
    }
  }

  Future<ImportSummary> commitAnalyses(
    List<ImportAnalysis> analyses, {
    required bool learnOnly,
  }) async {
    final summary = await _repo.commitAnalyses(analyses, learnOnly: learnOnly);
    await load();
    return summary;
  }

  Future<void> saveDistractors({
    required String cardId,
    required List<String> wrongAnswers,
    String aiStatus = 'accepted',
  }) async {
    await _repo.updateDistractors(
      cardId: cardId,
      wrongAnswers: wrongAnswers,
      aiStatus: aiStatus,
    );
    await load();
  }

  Future<List<Flashcard>> cardsFor(String topicId) {
    return _repo.loadCards(topicId);
  }

  Future<void> markSeen(String cardId) => _repo.markSeen(cardId);

  Future<void> toggleFavorite(String cardId) => _repo.toggleFavorite(cardId);

  Future<void> saveQuiz(QuizSession session) async {
    await _repo.saveQuizSession(session);
    _stats = await _repo.loadStats();
    notifyListeners();
  }

  Future<void> deleteTopic(String topicId) async {
    await _repo.deleteTopic(topicId);
    if (_selectedTopicId == topicId) _selectedTopicId = null;
    await load();
  }

  Future<void> resetStats() async {
    await _repo.resetStats();
    await load();
  }
}
