import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'tech_deck.db');
    return openDatabase(
      path,
      version: 6,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.delete('quiz_sessions');
          await db.delete('cards');
          await db.delete('topics');
        }
        if (oldVersion < 3) {
          await _addColumnIfMissing(
            db,
            'cards',
            'wrong_answer_1',
            "TEXT NOT NULL DEFAULT ''",
          );
          await _addColumnIfMissing(
            db,
            'cards',
            'wrong_answer_2',
            "TEXT NOT NULL DEFAULT ''",
          );
          await _addColumnIfMissing(
            db,
            'cards',
            'wrong_answer_3',
            "TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_meta (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          await _addColumnIfMissing(
            db,
            'cards',
            'ai_status',
            "TEXT NOT NULL DEFAULT 'none'",
          );
          await _addColumnIfMissing(db, 'cards', 'updated_at', 'INTEGER');
        }
        if (oldVersion < 6) {
          await db.transaction((txn) async {
            await txn.execute('''
              CREATE TABLE cards_clean (
                id TEXT PRIMARY KEY,
                topic_id TEXT NOT NULL,
                question TEXT NOT NULL,
                answer TEXT NOT NULL,
                FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
              )
            ''');
            await txn.execute('''
              INSERT INTO cards_clean (id, topic_id, question, answer)
              SELECT id, topic_id, question, answer FROM cards
            ''');
            await txn.execute('DROP TABLE cards');
            await txn.execute('ALTER TABLE cards_clean RENAME TO cards');
            await txn.execute(
              'CREATE INDEX idx_cards_topic ON cards(topic_id)',
            );
            await txn.execute('DROP TABLE IF EXISTS quiz_sessions');
          });
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE topics (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            source_filename TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            imported_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cards (
            id TEXT PRIMARY KEY,
            topic_id TEXT NOT NULL,
            question TEXT NOT NULL,
            answer TEXT NOT NULL,
            FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_cards_topic ON cards(topic_id)');
        await db.execute('''
          CREATE TABLE app_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String spec,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final names = info.map((row) => row['name'] as String).toSet();
    if (!names.contains(column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $spec');
    }
  }
}
