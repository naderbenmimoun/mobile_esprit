import 'package:sqflite/sqflite.dart';

import '../models/user.dart';

class DBService {
  DBService._();
  static final DBService instance = DBService._();

  static const _dbName = 'gestion_user.db';
  static const _dbVersion = 1;
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = await getDatabasesPath();
    final dbPath = '$path/$_dbName';
    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL CHECK (role IN ('admin','client')),
            image_url TEXT
          );
        ''');
      },
      onOpen: (db) async {
        // Ensure admin exists
        await _ensureDefaultAdmin(db);
      },
    );
  }

  Future<void> _ensureDefaultAdmin(Database db) async {
    const adminEmail = 'admin@local';
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [adminEmail],
      limit: 1,
    );
    if (existing.isEmpty) {
      // Default password: admin123 (hash to be provided by AuthService util)
      final defaultHash =
          'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f'; // sha256('admin123')
      final admin = AppUser(
        name: 'Administrator',
        email: adminEmail,
        passwordHash: defaultHash,
        role: 'admin',
        imageUrl: null,
      );
      await insertUser(admin, dbOverride: db);
    }
  }

  Future<int> insertUser(AppUser user, {Database? dbOverride}) async {
    final db = dbOverride ?? await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return AppUser.fromMap(res.first);
  }

  Future<AppUser?> getUserById(int id) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return AppUser.fromMap(res.first);
  }

  Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    final res = await db.query('users', orderBy: 'role DESC, name ASC');
    return res.map((e) => AppUser.fromMap(e)).toList();
  }

  Future<int> updateUser(AppUser user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}
