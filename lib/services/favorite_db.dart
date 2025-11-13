import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/favorite.dart';

class FavoriteDB {
  FavoriteDB._();
  static final FavoriteDB instance = FavoriteDB._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'marketplace.db'); // partager le même DB que les produits
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Si la DB est créée pour la première fois, on crée aussi la table favorites
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
      CREATE TABLE IF NOT EXISTS favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        outfitId TEXT NOT NULL,
        addedAt TEXT NOT NULL
      );
    ''');
  }

  Future<int> addFavorite(Favorite favorite) async {
    final db = await database;
    return await db.insert('favorites', favorite.toMap());
  }

  Future<List<Favorite>> getFavorites() async {
    final db = await database;
    final res = await db.query('favorites', orderBy: 'addedAt DESC');
    return res.map((e) => Favorite.fromMap(e)).toList();
  }

  Future<Favorite?> getByOutfitId(String outfitId) async {
    final db = await database;
    final res = await db.query('favorites', where: 'outfitId = ?', whereArgs: [outfitId], limit: 1);
    if (res.isEmpty) return null;
    return Favorite.fromMap(res.first);
  }

  Future<bool> isFavorite(String outfitId) async {
    final f = await getByOutfitId(outfitId);
    return f != null;
  }

  Future<int> removeById(int id) async {
    final db = await database;
    return await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> removeByOutfitId(String outfitId) async {
    final db = await database;
    return await db.delete('favorites', where: 'outfitId = ?', whereArgs: [outfitId]);
  }
}
