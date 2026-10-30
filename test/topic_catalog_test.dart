import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_deck/core/topic_catalog.dart';
import 'package:tech_deck/data/models/topic.dart';

Topic topic(String name) => Topic(
  id: name,
  name: name,
  sourceFilename: '$name.csv',
  sortOrder: 0,
  importedAt: DateTime(2026),
);

void main() {
  final catalog = TopicCatalog.fromJson(
    jsonDecode(File('assets/navigation/categories.json').readAsStringSync())
        as List,
  );

  test(
    'All bundled decks receive a subject; examination rules take precedence',
    () {
      for (final file in Directory('assets/decks').listSync()) {
        final name = file.path.split('/').last.replaceAll('_', ' ');
        expect(
          catalog.categoryFor(topic(name)).id,
          isNot('other'),
          reason: name,
        );
      }
      expect(catalog.categoryFor(topic('Datenschutz-Klausur')).id, 'exams');
      expect(
        catalog.categoryFor(topic('Datenschutz: Privacy by Design')).id,
        'security',
      );
    },
  );

  test('New/imported decks work with rules, fallback and override', () {
    expect(catalog.categoryFor(topic('IPv6 Vertiefung')).id, 'networks');
    expect(catalog.categoryFor(topic('Botanik')).id, 'other');
    expect(
      catalog.categoryFor(topic('Botanik'), overrideId: 'systems').id,
      'systems',
    );
    expect(
      catalog.categoryFor(topic('Botanik'), overrideId: 'removed').id,
      'other',
    );
  });

  test(
    'Search matches category, filename and card contents, including umlauts',
    () {
      final deck = topic('Eigenes Thema');
      final category = catalog.categories.first;
      expect(catalog.matches(deck, category, 'pruefung', ''), isTrue);
      expect(catalog.matches(deck, category, 'eigenes thema.csv', ''), isTrue);
      expect(
        catalog.matches(
          deck,
          category,
          'öffentliche schlüssel',
          'Öffentliche Schlüssel dienen zur Prüfung.',
        ),
        isTrue,
      );
      expect(
        catalog.matches(deck, category, 'schluessel fehlt', 'Schlüssel'),
        isFalse,
      );
      expect(catalog.matches(deck, category, '%_', ''), isFalse);
    },
  );
}
