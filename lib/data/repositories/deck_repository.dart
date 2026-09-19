import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../logic/import_analyzer.dart';
import '../csv/csv_importer.dart';
import '../csv/csv_parser.dart';
import '../db/app_database.dart';
import '../models/flashcard.dart';
import '../models/quiz.dart';
import '../models/stats.dart';
import '../models/topic.dart';

class DeckRepository {
  DeckRepository({AppDatabase? database})
      : _dbProvider = database ?? AppDatabase.instance;

  static const bundledContentRev = 'thematic-2';

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
      ORDER BY t.sort_order ASC
    ''');
    return rows
        .map(
          (row) => Topic.fromMap(
            row,
            cardCount: _asInt(row['card_count']),
          ),
        )
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

  Future<List<PickedCsvFile>?> pickCsvFiles() => _importer.pickFiles();

  List<ImportAnalysis> analyzePickedFiles(List<PickedCsvFile> files) {
    return [
      for (final file in files)
        ImportAnalyzer.fromParse(
          filename: file.filename,
          parsed: _importer.parseFile(file),
        ),
    ];
  }

  Future<ImportSummary?> importCsvFiles() async {
    final files = await _importer.pickFiles();
    if (files == null) return null;
    if (files.isEmpty) {
      return const ImportSummary(outcomes: []);
    }
    return importPickedFiles(files);
  }

  Future<void> updateDistractors({
    required String cardId,
    required List<String> wrongAnswers,
    String aiStatus = 'accepted',
  }) async {
    final db = await _db;
    await db.update(
      'cards',
      {
        'wrong_answer_1': wrongAnswers.isNotEmpty ? wrongAnswers[0] : '',
        'wrong_answer_2': wrongAnswers.length > 1 ? wrongAnswers[1] : '',
        'wrong_answer_3': wrongAnswers.length > 2 ? wrongAnswers[2] : '',
        'ai_status': aiStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<ImportSummary> commitAnalyses(
    List<ImportAnalysis> analyses, {
    required bool learnOnly,
  }) async {
    final outcomes = <ImportFileOutcome>[];
    for (final analysis in analyses) {
      outcomes.add(await _commitAnalysis(analysis, learnOnly: learnOnly));
    }
    return ImportSummary(outcomes: outcomes);
  }

  Future<ImportSummary> importPickedFiles(List<PickedCsvFile> files) async {
    final outcomes = <ImportFileOutcome>[];
    for (final file in files) {
      outcomes.add(await _importOne(file));
    }
    return ImportSummary(outcomes: outcomes);
  }

  /// Lädt mitgelieferte Decks in fester Reihenfolge (16 IT-Themen à 50 Karten).
  Future<void> ensureBundledTopics() async {
    const bundled = [
      ('assets/decks/01_IT_Grundlagen.csv', 'IT Grundlagen'),
      ('assets/decks/02_Hardware_und_Architektur.csv', 'Hardware und Architektur'),
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
        replaceExisting: true,
        forceReplace: forceReplace,
      );
    }
    if (forceReplace) {
      await _setMeta(db, 'bundled_rev', bundledContentRev);
    }
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
    await db.insert(
      'app_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ImportFileOutcome> _importOne(
    PickedCsvFile file, {
    String? topicName,
    int? sortOrder,
    bool replaceExisting = false,
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
          final maxOrder = Sqflite.firstIntValue(
                await txn.rawQuery(
                  'SELECT MAX(sort_order) FROM topics',
                ),
              ) ??
              -1;
          topicId = _uuid.v4();
          await txn.insert('topics', {
            'id': topicId,
            'name': resolvedName,
            'source_filename': file.filename,
            'sort_order': sortOrder ?? maxOrder + 1,
            'imported_at': DateTime.now().millisecondsSinceEpoch,
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
        } else if (replaceExisting) {
          final sample = await txn.query(
            'cards',
            columns: ['wrong_answer_1'],
            where: 'topic_id = ?',
            whereArgs: [topicId],
            limit: 1,
          );
          final needsRefresh = sample.isEmpty ||
              ((sample.first['wrong_answer_1'] as String? ?? '').trim().isEmpty);
          if (needsRefresh && sample.isNotEmpty) {
            await txn.delete(
              'cards',
              where: 'topic_id = ?',
              whereArgs: [topicId],
            );
          }
        }

        final known = <String, String>{};
        final current = await txn.query(
          'cards',
          columns: ['id', 'question', 'answer'],
          where: 'topic_id = ?',
          whereArgs: [topicId],
        );
        for (final row in current) {
          known[
              '${CsvParser.normalizeKey(row['question'] as String)}||'
              '${CsvParser.normalizeKey(row['answer'] as String)}'] =
              row['id'] as String;
        }

        for (final card in parsed.cards) {
          final key =
              '${CsvParser.normalizeKey(card.question)}||${CsvParser.normalizeKey(card.answer)}';
          final distractors = {
            'wrong_answer_1': card.wrongAnswer1,
            'wrong_answer_2': card.wrongAnswer2,
            'wrong_answer_3': card.wrongAnswer3,
          };
          final existingId = known[key];
          if (existingId != null) {
            await txn.update(
              'cards',
              distractors,
              where: 'id = ?',
              whereArgs: [existingId],
            );
            duplicates++;
            continue;
          }
          known[key] = _uuid.v4();
          await txn.insert('cards', {
            'id': known[key],
            'topic_id': topicId,
            'question': card.question,
            'answer': card.answer,
            ...distractors,
            'ai_status': 'none',
            'updated_at': DateTime.now().millisecondsSinceEpoch,
            'is_favorite': 0,
            'times_seen': 0,
            'last_seen': null,
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

  Future<ImportFileOutcome> _commitAnalysis(
    ImportAnalysis analysis, {
    required bool learnOnly,
  }) async {
    try {
      final db = await _db;
      var imported = 0;
      var duplicates = 0;
      await db.transaction((txn) async {
        final existing = await txn.query(
          'topics',
          where: 'name = ?',
          whereArgs: [analysis.topicName],
        );
        late final String topicId;
        if (existing.isEmpty) {
          final maxOrder = Sqflite.firstIntValue(
                await txn.rawQuery('SELECT MAX(sort_order) FROM topics'),
              ) ??
              -1;
          topicId = _uuid.v4();
          await txn.insert('topics', {
            'id': topicId,
            'name': analysis.topicName,
            'source_filename': analysis.filename,
            'sort_order': maxOrder + 1,
            'imported_at': DateTime.now().millisecondsSinceEpoch,
          });
        } else {
          topicId = existing.first['id'] as String;
        }

        final known = <String, String>{};
        final current = await txn.query(
          'cards',
          columns: ['id', 'question', 'answer'],
          where: 'topic_id = ?',
          whereArgs: [topicId],
        );
        for (final row in current) {
          known[
              '${CsvParser.normalizeKey(row['question'] as String)}||'
              '${CsvParser.normalizeKey(row['answer'] as String)}'] =
              row['id'] as String;
        }

        for (final draft in analysis.cards) {
          if (draft.state == ImportCardState.duplicateQuestion) {
            duplicates++;
            continue;
          }
          final key =
              '${CsvParser.normalizeKey(draft.question)}||${CsvParser.normalizeKey(draft.answer)}';
          final useAi = !learnOnly && draft.aiSuggestion != null && draft.aiSuggestion!.length == 3;
          final wrongs = learnOnly
              ? const ['', '', '']
              : (useAi ? draft.aiSuggestion! : draft.wrongAnswers);
          final padded = [
            wrongs.isNotEmpty ? wrongs[0] : '',
            wrongs.length > 1 ? wrongs[1] : '',
            wrongs.length > 2 ? wrongs[2] : '',
          ];
          final payload = {
            'wrong_answer_1': padded[0],
            'wrong_answer_2': padded[1],
            'wrong_answer_3': padded[2],
            'ai_status': useAi ? 'accepted' : 'none',
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          };
          final existingId = known[key];
          if (existingId != null) {
            await txn.update('cards', payload, where: 'id = ?', whereArgs: [existingId]);
            duplicates++;
            continue;
          }
          known[key] = _uuid.v4();
          await txn.insert('cards', {
            'id': known[key],
            'topic_id': topicId,
            'question': draft.question,
            'answer': draft.answer,
            ...payload,
            'is_favorite': 0,
            'times_seen': 0,
            'last_seen': null,
          });
          imported++;
        }
      });
      return ImportFileOutcome(
        filename: analysis.filename,
        topicName: analysis.topicName,
        imported: imported,
        duplicates: duplicates,
        skipped: analysis.skippedEmptyQuestion + analysis.skippedEmptyAnswer,
      );
    } catch (e) {
      return ImportFileOutcome(
        filename: analysis.filename,
        topicName: analysis.topicName,
        imported: 0,
        duplicates: 0,
        skipped: 0,
        error: 'Import fehlgeschlagen: $e',
      );
    }
  }

  Future<void> deleteTopic(String topicId) async {
    final db = await _db;
    await db.delete('topics', where: 'id = ?', whereArgs: [topicId]);
  }

  Future<void> markSeen(String cardId) async {
    final db = await _db;
    await db.rawUpdate(
      '''
      UPDATE cards
      SET times_seen = times_seen + 1,
          last_seen = ?
      WHERE id = ?
      ''',
      [DateTime.now().millisecondsSinceEpoch, cardId],
    );
  }

  Future<void> toggleFavorite(String cardId) async {
    final db = await _db;
    await db.rawUpdate(
      '''
      UPDATE cards
      SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END
      WHERE id = ?
      ''',
      [cardId],
    );
  }

  Future<void> saveQuizSession(QuizSession session) async {
    final db = await _db;
    await db.insert('quiz_sessions', {
      'id': session.id,
      'topic_id': session.topicId,
      'question_count': session.questionCount,
      'correct_count': session.correctCount,
      'wrong_count': session.wrongCount,
      'skipped_count': session.skippedCount,
      'completed_at': session.completedAt.millisecondsSinceEpoch,
      'review_json': jsonEncode(session.records.map((r) => r.toJson()).toList()),
    });
  }

  Future<AppStats> loadStats() async {
    final db = await _db;
    final topics = await loadTopics();

    final learned = _asInt(
      Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM cards WHERE times_seen > 0',
        ),
      ),
    );
    final total = _asInt(
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM cards'),
      ),
    );
    final quizzes = _asInt(
      Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM quiz_sessions'),
      ),
    );
    final sums = await db.rawQuery('''
      SELECT
        COALESCE(SUM(correct_count), 0) AS correct_count,
        COALESCE(SUM(wrong_count), 0) AS wrong_count,
        COALESCE(SUM(skipped_count), 0) AS skipped_count
      FROM quiz_sessions
    ''');
    final correct = _asInt(sums.first['correct_count']);
    final wrong = _asInt(sums.first['wrong_count']);
    final skipped = _asInt(sums.first['skipped_count']);

    final perTopic = <TopicProgress>[];
    for (final topic in topics) {
      final seen = _asInt(
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM cards WHERE topic_id = ? AND times_seen > 0',
            [topic.id],
          ),
        ),
      );
      final fav = _asInt(
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM cards WHERE topic_id = ? AND is_favorite = 1',
            [topic.id],
          ),
        ),
      );
      final qCount = _asInt(
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM quiz_sessions WHERE topic_id = ?',
            [topic.id],
          ),
        ),
      );
      final qSums = await db.rawQuery(
        '''
        SELECT
          COALESCE(SUM(correct_count), 0) AS correct_count,
          COALESCE(SUM(wrong_count), 0) AS wrong_count
        FROM quiz_sessions
        WHERE topic_id = ?
        ''',
        [topic.id],
      );
      perTopic.add(
        TopicProgress(
          topicId: topic.id,
          name: topic.name,
          sortOrder: topic.sortOrder,
          totalCards: topic.cardCount,
          seenCards: seen,
          favoriteCards: fav,
          quizzesCompleted: qCount,
          correctAnswers: _asInt(qSums.first['correct_count']),
          wrongAnswers: _asInt(qSums.first['wrong_count']),
        ),
      );
    }

    return AppStats(
      totalCards: total,
      learnedCards: learned,
      quizzesCompleted: quizzes,
      correctAnswers: correct,
      wrongAnswers: wrong,
      skippedAnswers: skipped,
      perTopic: perTopic,
    );
  }

  Future<void> resetStats() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('quiz_sessions');
      await txn.rawUpdate(
        'UPDATE cards SET times_seen = 0, last_seen = NULL',
      );
    });
  }

  static int _asInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
