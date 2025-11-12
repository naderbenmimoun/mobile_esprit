import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/reclamation.dart';

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

    // version = 2 pour ajouter attachments JSON
    return await openDatabase(
      path,
      version: 2,
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
      attachments TEXT NOT NULL DEFAULT '[]'
    )
    ''');
    await db.execute('CREATE INDEX idx_reclamations_date ON reclamations(dateCreation)');
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
  }

  // CREATE
  Future<Reclamation> create(Reclamation reclamation) async {
    final db = await instance.database;
    await db.insert('reclamations', reclamation.toMap());
    return reclamation;
  }

  // READ ALL
  Future<List<Reclamation>> readAll() async {
    final db = await instance.database;
    const orderBy = 'dateCreation DESC';
    final result = await db.query('reclamations', orderBy: orderBy);
    return result.map((map) => Reclamation.fromMap(map)).toList();
  }

  // READ by ID
  Future<Reclamation?> readById(String id) async {
    final db = await instance.database;
    final maps = await db.query('reclamations', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Reclamation.fromMap(maps.first);
    return null;
  }

  // UPDATE
  Future<int> update(Reclamation reclamation) async {
    final db = await instance.database;
    return db.update(
      'reclamations',
      reclamation.toMap(),
      where: 'id = ?',
      whereArgs: [reclamation.id],
    );
  }

  // DELETE
  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete('reclamations', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
