import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class ProductFavoriteDB {
  ProductFavoriteDB._();
  static final ProductFavoriteDB instance = ProductFavoriteDB._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // Use the same DB file as products (marketplace.db)
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
      CREATE TABLE IF NOT EXISTS product_favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        addedAt TEXT NOT NULL
      );
    ''');
  }

  Future<bool> isFavorite(int productId, int userId) async {
    final db = await database;
    final res = await db.query(
      'product_favorites',
      where: 'productId = ? AND userId = ?',
      whereArgs: [productId, userId],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  Future<int> add(int productId, int userId) async {
    final db = await database;
    // avoid duplicates
    if (await isFavorite(productId, userId)) return 0;
    return await db.insert('product_favorites', {
      'productId': productId,
      'userId': userId,
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> remove(int productId, int userId) async {
    final db = await database;
    return await db.delete(
      'product_favorites',
      where: 'productId = ? AND userId = ?',
      whereArgs: [productId, userId],
    );
  }

  Future<List<Product>> listFavoriteProducts(int userId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT p.* FROM products p
      INNER JOIN product_favorites f ON f.productId = p.id
      WHERE f.userId = ?
      ORDER BY f.addedAt DESC
    ''', [userId]);
    return res.map((m) => Product.fromMap(m)).toList();
  }
}
