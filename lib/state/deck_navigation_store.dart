import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Additive preferences only: no database migration or existing key changes.
class DeckNavigationStore {
  static const storageKey = 'deck_navigation_v1';
  static const recentLimit = 5;
  final Set<String> favorites = {};
  final List<String> recent = [];
  final Map<String, String> categories = {};
  SharedPreferences? _preferences;
  Future<void> _writes = Future.value();

  Future<void> load() async {
    if (_preferences != null) return;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        favorites.addAll(
          (data['favorites'] as List? ?? []).whereType<String>(),
        );
        recent.addAll(
          (data['recent'] as List? ?? []).whereType<String>().toSet().take(
            recentLimit,
          ),
        );
        final assignments = data['categories'];
        if (assignments is Map) {
          for (final entry in assignments.entries) {
            if (entry.key is String && entry.value is String) {
              categories[entry.key as String] = entry.value as String;
            }
          }
        }
      } on FormatException {
        // Ignore only this optional navigation state; never touch user data.
      } on TypeError {
        // Older/malformed optional state must not prevent learning.
      }
    }
    _preferences = preferences;
  }

  Future<void> save() {
    final value = jsonEncode({
      'favorites': favorites.toList(),
      'recent': recent,
      'categories': categories,
    });
    final write = _writes.then((_) async {
      await load();
      if (!await _preferences!.setString(storageKey, value)) {
        throw StateError('Kartenauswahl konnte nicht gespeichert werden.');
      }
    });
    _writes = write.catchError((Object _) {});
    return write;
  }

  Future<void> recordOpened(String id) {
    recent.remove(id);
    recent.insert(0, id);
    if (recent.length > recentLimit) recent.removeLast();
    return save();
  }
}
