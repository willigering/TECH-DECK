import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/topic_marks.dart';
import '../../logic/question_normalizer.dart';
import '../csv/csv_importer.dart';
import '../csv/csv_parser.dart';
import '../db/app_database.dart';
import '../models/flashcard.dart';
import '../models/topic.dart';

class DeckRepository {
  DeckRepository({AppDatabase? database})
    : _dbProvider = database ?? AppDatabase.instance;

  static const bundledContentRev = 'learn-only-3';

  final AppDatabase _dbProvider;
  final _uuid = const Uuid();
  final _importer = CsvImporter();

  Future<Database> get _db async => _dbProvider.database;

  Future<List<Topic>> loadTopics() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT t.*, COUNT(c.id) AS card_count
      FROM topics t
      LEFT JOIN cards c ON c.topic_id = t.id
      GROUP BY t.id
      ORDER BY t.is_important DESC, t.sort_order ASC
    ''');
    return rows
        .map((row) => Topic.fromMap(row, cardCount: _asInt(row['card_count'])))
        .toList();
  }

  Future<Topic?> getTopic(String id) async {
    final topics = await loadTopics();
    for (final t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<List<Flashcard>> loadCards(String topicId) async {
    final db = await _db;
    final rows = await db.query(
      'cards',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'rowid ASC',
    );
    return rows.map(Flashcard.fromMap).toList();
  }

  Future<Flashcard?> getCard(String id) async {
    final db = await _db;
    final rows = await db.query('cards', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Flashcard.fromMap(rows.first);
  }

  Future<ImportSummary?> importCsvFiles() async {
    final files = await _importer.pickFiles();
    if (files == null) return null;
    if (files.isEmpty) {
      return const ImportSummary(outcomes: []);
    }
    return importPickedFiles(files);
  }

  Future<ImportSummary> importPickedFiles(List<PickedCsvFile> files) async {
    final outcomes = <ImportFileOutcome>[];
    for (final file in files) {
      outcomes.add(await _importOne(file));
    }
    return ImportSummary(outcomes: outcomes);
  }

  /// Lädt mitgelieferte Decks in fester Reihenfolge.
  Future<void> ensureBundledTopics() async {
    const bundled = [
      ('assets/decks/01_IT_Grundlagen.csv', 'IT Grundlagen'),
      (
        'assets/decks/02_Hardware_und_Architektur.csv',
        'Hardware und Architektur',
      ),
      ('assets/decks/03_Betriebssysteme.csv', 'Betriebssysteme'),
      ('assets/decks/04_Netzwerke_und_OSI.csv', 'Netzwerke und OSI'),
      ('assets/decks/05_IPv4_IPv6_Subnetting.csv', 'IPv4, IPv6 und Subnetting'),
      (
        'assets/decks/06_Netzwerkdienste_und_Protokolle.csv',
        'Netzwerkdienste und Protokolle',
      ),
      ('assets/decks/07_IT_Sicherheit.csv', 'IT-Sicherheit'),
      ('assets/decks/08_Datenbanken_und_SQL.csv', 'Datenbanken und SQL'),
      (
        'assets/decks/09_Programmierung_und_Skripting.csv',
        'Programmierung und Skripting',
      ),
      (
        'assets/decks/10_Virtualisierung_und_Cloud.csv',
        'Virtualisierung und Cloud',
      ),
      ('assets/decks/11_Webtechnologien.csv', 'Webtechnologien'),
      ('assets/decks/12_DevOps_und_CICD.csv', 'DevOps und CI/CD'),
      ('assets/decks/13_IT_Service_Management.csv', 'IT-Service-Management'),
      (
        'assets/decks/14_Monitoring_Logging_Backup.csv',
        'Monitoring, Logging und Backup',
      ),
      (
        'assets/decks/15_Datenschutz_Recht_Wirtschaft.csv',
        'Datenschutz, Recht und Wirtschaft',
      ),
      (
        'assets/decks/16_Pruefung_und_Fehleranalyse.csv',
        'Prüfung und Fehleranalyse',
      ),
      ('assets/decks/17_Klausurvorbereitung.csv', 'Klausurvorbereitung'),
      ('assets/decks/18_Windows_Terminal.csv', 'Windows Terminal'),
      ('assets/decks/19_Linux_Terminal.csv', 'Linux Terminal'),
    ];
    final db = await _db;
    final currentRev = await _meta(db, 'bundled_rev');
    final forceReplace = currentRev != bundledContentRev;
    for (var i = 0; i < bundled.length; i++) {
      final item = bundled[i];
      final data = await rootBundle.load(item.$1);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await _importOne(
        PickedCsvFile(filename: item.$1.split('/').last, bytes: bytes),
        topicName: item.$2,
        sortOrder: i,
        forceReplace: forceReplace,
      );
    }
    if (forceReplace) {
      await _setMeta(db, 'bundled_rev', bundledContentRev);
    }
    await _ensureKlausurMark(db);
  }

  /// Klausurvorbereitung einmalig rot und als wichtig markieren.
  Future<void> _ensureKlausurMark(Database db) async {
    if (await _meta(db, 'klausur_mark_v1') == '1') return;
    await db.update(
      'topics',
      {'is_important': 1, 'accent_color': TopicMarks.examKey},
      where: 'name = ?',
      whereArgs: ['Klausurvorbereitung'],
    );
    await _setMeta(db, 'klausur_mark_v1', '1');
  }

  Future<String?> _meta(Database db, String key) async {
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _setMeta(Database db, String key, String value) async {
    await db.insert('app_meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ImportFileOutcome> _importOne(
    PickedCsvFile file, {
    String? topicName,
    int? sortOrder,
    bool forceReplace = false,
  }) async {
    final resolvedName =
        topicName ?? CsvParser.topicNameFromFilename(file.filename);
    if (resolvedName.isEmpty) {
      return ImportFileOutcome(
        filename: file.filename,
        topicName: file.filename,
        imported: 0,
        duplicates: 0,
        skipped: 0,
        error: 'Dateiname ungültig.',
      );
    }

    try {
      final parsed = _importer.parseFile(file);
      final db = await _db;
      var imported = 0;
      var duplicates = 0;

      await db.transaction((txn) async {
        final existing = await txn.query(
          'topics',
          where: 'name = ?',
          whereArgs: [resolvedName],
        );

        late final String topicId;
        if (existing.isEmpty) {
          final maxOrder =
              Sqflite.firstIntValue(
                await txn.rawQuery('SELECT MAX(sort_order) FROM topics'),
              ) ??
              -1;
          topicId = _uuid.v4();
          final isKlausur = resolvedName == 'Klausurvorbereitung';
          await txn.insert('topics', {
            'id': topicId,
            'name': resolvedName,
            'source_filename': file.filename,
            'sort_order': sortOrder ?? maxOrder + 1,
            'imported_at': DateTime.now().millisecondsSinceEpoch,
            'is_important': isKlausur ? 1 : 0,
            'accent_color': isKlausur ? TopicMarks.examKey : null,
          });
        } else {
          topicId = existing.first['id'] as String;
          if (sortOrder != null) {
            await txn.update(
              'topics',
              {'sort_order': sortOrder},
              where: 'id = ?',
              whereArgs: [topicId],
            );
          }
        }

        if (forceReplace) {
          await txn.delete(
            'cards',
            where: 'topic_id = ?',
            whereArgs: [topicId],
          );
        }

        final known = <String, String>{};
        final current = await txn.query(
          'cards',
          columns: ['id', 'question', 'answer'],
          where: 'topic_id = ?',
          whereArgs: [topicId],
        );
        final existingQuestions = <String>[];
        for (final row in current) {
          final question = row['question'] as String;
          final answer = row['answer'] as String;
          existingQuestions.add(question);
          known['${CsvParser.normalizeKey(question)}||${CsvParser.normalizeKey(answer)}'] =
              row['id'] as String;
        }

        for (final card in parsed.cards) {
          final key =
              '${CsvParser.normalizeKey(card.question)}||${CsvParser.normalizeKey(card.answer)}';
          final existingId = known[key];
          if (existingId != null) {
            duplicates++;
            continue;
          }
          if (_nearDuplicateQuestion(card.question, existingQuestions)) {
            duplicates++;
            continue;
          }
          known[key] = _uuid.v4();
          existingQuestions.add(card.question);
          await txn.insert('cards', {
            'id': known[key],
            'topic_id': topicId,
            'question': card.question,
            'answer': card.answer,
          });
          imported++;
        }
      });

      return ImportFileOutcome(
        filename: file.filename,
        topicName: resolvedName,
        imported: imported,
        duplicates: duplicates,
        skipped: parsed.skipped,
      );
    } catch (e) {
      return ImportFileOutcome(
        filename: file.filename,
        topicName: resolvedName,
        imported: 0,
        duplicates: 0,
        skipped: 0,
        error: 'Import fehlgeschlagen: $e',
      );
    }
  }

  bool _nearDuplicateQuestion(String question, List<String> existing) {
    for (final other in existing) {
      if (QuestionNormalizer.areDuplicates(question, other)) return true;
    }
    return false;
  }

  Future<void> updateTopicMark(
    String topicId, {
    String? colorKey,
    bool clearColor = false,
    bool? isImportant,
  }) async {
    final db = await _db;
    final values = <String, Object?>{};
    if (clearColor) {
      values['accent_color'] = null;
    } else if (colorKey != null) {
      values['accent_color'] = colorKey;
    }
    if (isImportant != null) {
      values['is_important'] = isImportant ? 1 : 0;
    }
    if (values.isEmpty) return;
    await db.update(
      'topics',
      values,
      where: 'id = ?',
      whereArgs: [topicId],
    );
  }

  Future<void> deleteTopic(String topicId) async {
    final db = await _db;
    await db.delete('topics', where: 'id = ?', whereArgs: [topicId]);
  }

  static int _asInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
