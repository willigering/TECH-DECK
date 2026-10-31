import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tech_deck/data/csv/csv_parser.dart';
import 'package:tech_deck/data/db/app_database.dart';
import 'package:tech_deck/data/repositories/deck_repository.dart';

// Simulates an installation that still holds the previous bundled content
// and checks the automatic content update against the real repository SQL.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp('bundled-update-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    final db = await AppDatabase.instance.database;
    Future<void> topic(
      String id,
      String name,
      String file, {
      String? color,
      int important = 0,
    }) => db.insert('topics', {
      'id': id,
      'name': name,
      'source_filename': file,
      'sort_order': 0,
      'imported_at': 1000,
      'accent_color': color,
      'is_important': important,
    });
    Future<void> card(String id, String topicId) => db.insert('cards', {
      'id': id,
      'topic_id': topicId,
      'question': 'Alte Frage $id?',
      'answer': 'Alte Antwort $id.',
    });
    await topic(
      'grundlagen-id',
      'IT Grundlagen',
      '01_IT_Grundlagen.csv',
      color: 'blue',
      important: 1,
    );
    await card('old-grundlagen', 'grundlagen-id');
    await topic(
      'klausur-id',
      'Klausurvorbereitung',
      '17_Klausurvorbereitung.csv',
      color: 'exam',
      important: 1,
    );
    await card('old-klausur', 'klausur-id');
    await topic(
      'ds-klausur-id',
      'Datenschutz-Klausur',
      '26_Datenschutz_Klausur.csv',
    );
    await card('old-ds-klausur', 'ds-klausur-id');
    // A user import that happens to share a retired name stays untouched.
    await topic('own-ihk-id', 'IHK-Prüfung', 'IHK-Prüfung.csv');
    await card('own-ihk-card', 'own-ihk-id');
    await topic('own-id', 'Meine Klausur', 'Meine_Klausur.csv');
    await card('own-card', 'own-id');
    await db.insert('app_meta', {
      'key': 'bundled_rev',
      'value': 'learn-only-3',
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

  test('Content update replaces bundled cards, keeps deck IDs, marks and '
      'own decks, and removes only retired bundled decks', () async {
    final repo = DeckRepository();
    await repo.ensureBundledTopics();
    // A second start must not duplicate or drop anything.
    await repo.ensureBundledTopics();

    final db = await AppDatabase.instance.database;
    final topics = await repo.loadTopics();
    final byName = {for (final t in topics) t.name: t};

    expect(byName.containsKey('Klausurvorbereitung'), isFalse);
    expect(byName.containsKey('Datenschutz-Klausur'), isFalse);
    expect(
      await db.query(
        'cards',
        where: 'id IN (?, ?)',
        whereArgs: ['old-klausur', 'old-ds-klausur'],
      ),
      isEmpty,
    );

    final grundlagen = byName['IT Grundlagen']!;
    expect(grundlagen.id, 'grundlagen-id');
    expect(grundlagen.colorKey, 'blue');
    expect(grundlagen.isImportant, isTrue);
    expect(
      await db.query('cards', where: 'id = ?', whereArgs: ['old-grundlagen']),
      isEmpty,
    );

    expect(byName['IHK-Prüfung']!.id, 'own-ihk-id');
    expect(byName['IHK-Prüfung']!.cardCount, 1);
    expect(byName['Meine Klausur']!.id, 'own-id');
    expect(byName['Meine Klausur']!.cardCount, 1);

    // Every bundled card arrives; the import de-duplication drops none.
    final files =
        Directory('assets/decks')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.csv'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final bundled = topics.where(
      (t) => RegExp(r'^\d\d_').hasMatch(t.sourceFilename),
    );
    expect(bundled, hasLength(files.length));
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final expected = CsvParser.parseCards(file.readAsStringSync()).cards;
      final topic = topics.firstWhere((t) => t.sourceFilename == name);
      expect(topic.cardCount, expected.length, reason: name);
    }

    final rev = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: ['bundled_rev'],
    );
    expect(rev.single['value'], DeckRepository.bundledContentRev);
  });
}
