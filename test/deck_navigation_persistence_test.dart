import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tech_deck/data/db/app_database.dart';
import 'package:tech_deck/data/repositories/deck_repository.dart';
import 'package:tech_deck/state/deck_controller.dart';

// Exercise real repository SQL against an existing database, without importing
// the bundled content again (the navigation does not change its revision).
class ExistingDeckRepository extends DeckRepository {
  @override
  Future<void> ensureBundledTopics() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({'theme_choice': 'lightGold'});
    directory = await Directory.systemTemp.createTemp('deck-navigation-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    final db = await AppDatabase.instance.database;
    await db.insert('topics', {
      'id': 'unchanged-id',
      'name': 'Eigene Lernkartei',
      'source_filename': 'Eigene_Lernkartei.csv',
      'sort_order': 31,
      'imported_at': 1000,
      'accent_color': 'blue',
      'is_important': 1,
    });
    await db.insert('cards', {
      'id': 'existing-card',
      'topic_id': 'unchanged-id',
      'question': 'Wofür dient die Namensauflösung?',
      'answer': 'DNS übersetzt Namen.',
    });
    await db.insert('app_meta', {
      'key': 'existing_progress',
      'value': 'preserve-me',
    });
  });
  tearDown(() async {
    await AppDatabase.instance.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });

  test(
    'Existing marks, cards, metadata and settings survive navigation and restart',
    () async {
      final deck = DeckController(repository: ExistingDeckRepository());
      await deck.load();
      expect(deck.error, isNull);
      expect(deck.topics.single.colorKey, 'blue');
      expect(deck.topics.single.isImportant, isTrue);
      await deck.setTopicMark(
        'unchanged-id',
        colorKey: 'green',
        isImportant: false,
      );
      await deck.toggleFavorite('unchanged-id');
      await deck.assignCategory('unchanged-id', 'networks');
      await deck.markTopicOpened('unchanged-id');
      expect(await deck.searchTopicIds('namensauflösung'), {'unchanged-id'});
      deck.dispose();
      await AppDatabase.instance.close();

      final restored = DeckController(repository: ExistingDeckRepository());
      await restored.load();
      expect(restored.error, isNull);
      final topic = restored.topics.single;
      expect(topic.id, 'unchanged-id');
      expect(topic.sortOrder, 31);
      expect(topic.colorKey, 'green');
      expect(topic.isImportant, isFalse);
      expect(topic.cardCount, 1);
      expect(restored.isFavorite(topic.id), isTrue);
      expect(restored.categoryFor(topic).id, 'networks');
      expect(restored.recentTopics.single.id, topic.id);
      expect((await restored.cardsFor(topic.id)).single.id, 'existing-card');
      final db = await AppDatabase.instance.database;
      expect(
        (await db.query(
          'app_meta',
          where: 'key = ?',
          whereArgs: ['existing_progress'],
        )).single['value'],
        'preserve-me',
      );
      expect(await db.getVersion(), 7);
      expect(
        (await SharedPreferences.getInstance()).getString('theme_choice'),
        'lightGold',
      );
      await restored.setTopicMark(
        topic.id,
        clearColor: true,
        isImportant: true,
      );
      await restored.load();
      expect(restored.topics.single.colorKey, isNull);
      expect(restored.topics.single.isImportant, isTrue);
      await restored.deleteTopic(topic.id);
      expect(restored.recentTopics, isEmpty);
      expect(restored.favoriteTopics, isEmpty);
      restored.dispose();
    },
  );
}
