import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/csv/csv_importer.dart';
import '../data/models/flashcard.dart';
import '../data/models/topic.dart';
import '../data/repositories/deck_repository.dart';

class DeckController extends ChangeNotifier {
  DeckController({DeckRepository? repository})
    : _repo = repository ?? DeckRepository();

  final DeckRepository _repo;
  Timer? _newBadgeTimer;
  bool _disposed = false;
  bool _importing = false;
  bool get importing => _importing;
  Future<void> _loadTail = Future.value();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _scheduleNewBadgeExpiry() {
    _newBadgeTimer?.cancel();
    if (_disposed) return;
    final deadlines = _topics.where((t) => t.isNew).map((t) => t.newUntil!).toList()..sort();
    if (deadlines.isEmpty) return;
    final delay = deadlines.first.difference(DateTime.now());
    _newBadgeTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      _notify();
      _scheduleNewBadgeExpiry();
    });
  }

  @override
  void dispose() {
    _disposed = true;
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

  Future<void> load() {
    final next = _loadTail.then((_) => _load());
    _loadTail = next;
    return next;
  }

  Future<void> _load() async {
    if (_disposed) return;
    _loading = true;
    _error = null;
    _notify();
    try {
      await _repo.ensureBundledTopics();
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
      _notify();
    }
  }

  Future<void> markTopicOpened(String id) async {
    if (topicById(id)?.isNew != true) return;
    await _repo.dismissNewBadge(id);
    _topics = await _repo.loadTopics();
    _scheduleNewBadgeExpiry();
    _notify();
  }

  void selectTopic(String? id) {
    _selectedTopicId = id;
    _notify();
  }

  Future<ImportSummary?> importCsv() async {
    if (_importing || _disposed) return null;
    _importing = true;
    _notify();
    try {
      final summary = await _repo.importCsvFiles();
      if (summary != null) await load();
      return summary;
    } catch (e) {
      _error = '$e';
      _notify();
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
    } finally {
      _importing = false;
      _notify();
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
