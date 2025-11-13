import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/reclamation.dart';
import 'session_service.dart';

class ReclamationDatabase {
  static final ReclamationDatabase instance = ReclamationDatabase._init();

  static Database? _database;

  ReclamationDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reclamations.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // version = 3 to add userId and attachments if needed
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE reclamations (
      id TEXT PRIMARY KEY,
      titre TEXT NOT NULL,
      description TEXT NOT NULL,
      statut TEXT NOT NULL,
      dateCreation TEXT NOT NULL,
      attachments TEXT NOT NULL DEFAULT '[]',
      userId INTEGER NOT NULL
    )
    ''');
    await db.execute('CREATE INDEX idx_reclamations_date ON reclamations(dateCreation)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reclamations_user ON reclamations(userId)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // ajouter la colonne attachments si nécessaire
      try {
        await db.execute("ALTER TABLE reclamations ADD COLUMN attachments TEXT NOT NULL DEFAULT '[]'");
      } catch (e) {
        // ignore si déjà présent
      }
    }
    if (oldVersion < 3) {
      // add userId column if missing; default to 0 then app will only read rows with current userId
      try {
        await db.execute('ALTER TABLE reclamations ADD COLUMN userId INTEGER');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reclamations_user ON reclamations(userId)');
      } catch (e) {
        // ignore if already present
      }
    }
  }

  // CREATE
  Future<Reclamation> create(Reclamation reclamation) async {
    final db = await instance.database;
    final userId = await SessionService.instance.getUserIdOrThrow();
    final data = Map<String, dynamic>.from(reclamation.toMap())
      ..['userId'] = userId;
    await db.insert('reclamations', data);
    return reclamation;
  }

  // READ ALL
  Future<List<Reclamation>> readAll() async {
    final db = await instance.database;
    final userId = await SessionService.instance.getUserIdOrThrow();
    const orderBy = 'dateCreation DESC';
    final result = await db.query(
      'reclamations',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: orderBy,
    );
    return result.map((map) => Reclamation.fromMap(map)).toList();
  }

  // READ by ID
  Future<Reclamation?> readById(String id) async {
    final db = await instance.database;
    final userId = await SessionService.instance.getUserIdOrThrow();
    final maps = await db.query(
      'reclamations',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) return Reclamation.fromMap(maps.first);
    return null;
  }

  // UPDATE
  Future<int> update(Reclamation reclamation) async {
    final db = await instance.database;
    final userId = await SessionService.instance.getUserIdOrThrow();
    return db.update(
      'reclamations',
      reclamation.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [reclamation.id, userId],
    );
  }

  // DELETE
  Future<int> delete(String id) async {
    final db = await instance.database;
    final userId = await SessionService.instance.getUserIdOrThrow();
    return await db.delete(
      'reclamations',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // DELETE ALL for current user (useful to purge previously seeded/static data)
  Future<int> deleteAllForCurrentUser() async {
    final db = await instance.database;
    final userId = await SessionService.instance.getUserIdOrThrow();
    return await db.delete('reclamations', where: 'userId = ?', whereArgs: [userId]);
  }

  // CLEANUP legacy rows without userId (from old versions). Not fetched anymore but can be removed.
  Future<int> deleteLegacyWithoutUserId() async {
    final db = await instance.database;
    return await db.delete('reclamations', where: 'userId IS NULL');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
