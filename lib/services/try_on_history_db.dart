import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/try_on_history.dart';

class TryOnHistoryDB {
  TryOnHistoryDB._();
  static final TryOnHistoryDB instance = TryOnHistoryDB._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'marketplace.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTableIfNotExists(db);
      },
      onOpen: (db) async {
        await _createTableIfNotExists(db);
      },
    );
    return db;
  }

  Future<void> _createTableIfNotExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS try_on_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        outfitId TEXT NOT NULL,
        userImagePath TEXT NOT NULL,
        generatedImagePath TEXT,
        triedAt TEXT NOT NULL
      );
    ''');
  }

  Future<int> addTry(TryOnHistory entry) async {
    final db = await database;
    return await db.insert('try_on_history', entry.toMap());
  }

  Future<List<TryOnHistory>> getAll() async {
    final db = await database;
    final res = await db.query('try_on_history', orderBy: 'triedAt DESC');
    return res.map((e) => TryOnHistory.fromMap(e)).toList();
  }

  Future<List<TryOnHistory>> getByOutfitId(String outfitId) async {
    final db = await database;
    final res = await db.query(
      'try_on_history',
      where: 'outfitId = ?',
      whereArgs: [outfitId],
      orderBy: 'triedAt DESC',
    );
    return res.map((e) => TryOnHistory.fromMap(e)).toList();
  }

  Future<List<TryOnHistory>> recent({int limit = 10}) async {
    final db = await database;
    final res = await db.query(
      'try_on_history',
      orderBy: 'triedAt DESC',
      limit: limit,
    );
    return res.map((e) => TryOnHistory.fromMap(e)).toList();
  }

  Future<int> deleteById(int id) async {
    final db = await database;
    return await db.delete('try_on_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAll() async {
    final db = await database;
    return await db.delete('try_on_history');
  }
}
