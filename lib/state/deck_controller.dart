import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/topic_catalog.dart';
import 'deck_navigation_store.dart';
import '../data/csv/csv_importer.dart';
import '../data/models/flashcard.dart';
import '../data/models/topic.dart';
import '../data/repositories/deck_repository.dart';

class DeckController extends ChangeNotifier {
  DeckController({DeckRepository? repository})
    : _repo = repository ?? DeckRepository();

  final DeckRepository _repo;
  Timer? _newBadgeTimer;
  final _navigation = DeckNavigationStore();
  TopicCatalog? _catalog;
  Future<Map<String, String>>? _searchIndex;
  TopicCatalog get catalog => _catalog!;
  List<Topic> get favoriteTopics =>
      _topics.where((topic) => isFavorite(topic.id)).toList();
  List<Topic> get recentTopics => [
    for (final id in _navigation.recent)
      if (topicById(id) case final Topic topic) topic,
  ];
  bool isFavorite(String id) => _navigation.favorites.contains(id);
  String? categoryOverride(String id) => _navigation.categories[id];
  TopicCategory categoryFor(Topic topic) =>
      catalog.categoryFor(topic, overrideId: categoryOverride(topic.id));

  Future<void> toggleFavorite(String id) async {
    if (!_navigation.favorites.remove(id)) _navigation.favorites.add(id);
    notifyListeners();
    await _navigation.save();
  }

  Future<void> assignCategory(String id, String? categoryId) async {
    if (categoryId == null) {
      _navigation.categories.remove(id);
    } else {
      _navigation.categories[id] = categoryId;
    }
    notifyListeners();
    await _navigation.save();
  }

  Future<Set<String>> searchTopicIds(String query) async {
    try {
      final index = await (_searchIndex ??= _repo.loadTopicSearchIndex());
      return {
        for (final topic in _topics)
          if (catalog.matches(
            topic,
            categoryFor(topic),
            query,
            index[topic.id] ?? '',
          ))
            topic.id,
      };
    } catch (_) {
      _searchIndex = null;
      rethrow;
    }
  }

  void _scheduleNewBadgeExpiry() {
    _newBadgeTimer?.cancel();
    final deadlines =
        _topics.where((t) => t.isNew).map((t) => t.newUntil!).toList()..sort();
    if (deadlines.isEmpty) return;
    final delay = deadlines.first.difference(DateTime.now());
    _newBadgeTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      notifyListeners();
      _scheduleNewBadgeExpiry();
    });
  }

  @override
  void dispose() {
    _newBadgeTimer?.cancel();
    super.dispose();
  }

  List<Topic> _topics = const [];
  bool _loading = true;
  String? _error;
  String? _selectedTopicId;

  List<Topic> get topics => _topics;
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
      _catalog ??= await TopicCatalog.load();
      await _navigation.load();
      await _repo.ensureBundledTopics();
      _searchIndex = null;
      _topics = await _repo.loadTopics();
      _scheduleNewBadgeExpiry();
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

  Future<void> markTopicOpened(String id) async {
    await _navigation.recordOpened(id);
    notifyListeners();
    if (topicById(id)?.isNew != true) return;
    await _repo.dismissNewBadge(id);
    _topics = await _repo.loadTopics();
    _scheduleNewBadgeExpiry();
    notifyListeners();
  }

  void selectTopic(String? id) {
    _selectedTopicId = id;
    notifyListeners();
  }

  Future<ImportSummary?> importCsv() async {
    try {
      final summary = await _repo.importCsvFiles();
      if (summary != null) await load();
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

  Future<List<Flashcard>> cardsFor(String topicId) {
    return _repo.loadCards(topicId);
  }

  Future<void> setTopicMark(
    String topicId, {
    String? colorKey,
    bool clearColor = false,
    bool? isImportant,
  }) async {
    await _repo.updateTopicMark(
      topicId,
      colorKey: colorKey,
      clearColor: clearColor,
      isImportant: isImportant,
    );
    await load();
  }

  Future<void> deleteTopic(String topicId) async {
    await _repo.deleteTopic(topicId);
    if (_selectedTopicId == topicId) _selectedTopicId = null;
    await load();
  }
}
