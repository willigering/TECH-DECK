import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/models/topic.dart';

/// Shared normalization for category rules and literal, multi-word searches.
String normalizeTopicSearch(String text) => text
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss')
    .replaceAll(RegExp(r'[_\s]+'), ' ');

class TopicCategory {
  const TopicCategory({
    required this.id,
    required this.name,
    this.keywords = const [],
  });

  final String id;
  final String name;
  final List<String> keywords;
}

/// Ordered rules live in an asset, not in the navigation widget. Unknown decks
/// always remain reachable; users can override a rule without renaming a deck.
class TopicCatalog {
  const TopicCatalog(this.categories);

  final List<TopicCategory> categories;

  static Future<TopicCatalog> load() async => TopicCatalog.fromJson(
    jsonDecode(await rootBundle.loadString('assets/navigation/categories.json'))
        as List<dynamic>,
  );

  factory TopicCatalog.fromJson(List<dynamic> json) => TopicCatalog([
    for (final item in json)
      TopicCategory(
        id: item['id'] as String,
        name: item['name'] as String,
        keywords: (item['keywords'] as List).cast<String>(),
      ),
  ]);

  TopicCategory categoryFor(Topic topic, {String? overrideId}) {
    for (final category in categories) {
      if (category.id == overrideId) return category;
    }
    final title = normalizeTopicSearch(topic.name);
    for (final category in categories) {
      if (category.keywords.any(
        (word) => title.contains(normalizeTopicSearch(word)),
      )) {
        return category;
      }
    }
    return categories.last;
  }

  bool matches(
    Topic topic,
    TopicCategory category,
    String query,
    String cards,
  ) {
    final haystack = normalizeTopicSearch(
      '${category.name} ${category.keywords.join(' ')} '
      '${topic.name} ${topic.sourceFilename} $cards',
    );
    return normalizeTopicSearch(
      query,
    ).trim().split(RegExp(r'\s+')).every(haystack.contains);
  }
}
