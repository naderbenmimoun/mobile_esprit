import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cart_item.dart';
import '../models/order.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();
  static Database? _database;

  Future<void> backupDatabase() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'app_db.db');
    final String backupPath = join(documentsDirectory.path, 'app_db_backup.db');

    if (await File(path).exists()) {
      await File(path).copy(backupPath);
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_db.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);
    // print('DB path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> deleteDatabase() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'app_db.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future _onCreate(Database db, int version) async {
    // Table panier
    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        nom TEXT NOT NULL,
        prix REAL NOT NULL,
        qty INTEGER NOT NULL,
        image TEXT
      )
    ''');

    // Table commandes
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total REAL NOT NULL,
        date TEXT NOT NULL,
        adresse TEXT,
        status TEXT NOT NULL DEFAULT 'en_attente',
        mode_paiement TEXT NOT NULL,
        numero_commande TEXT
      )
    ''');

    // Table articles de commande
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        nom TEXT NOT NULL,
        prix REAL NOT NULL,
        qty INTEGER NOT NULL,
        FOREIGN KEY(orderId) REFERENCES orders(id)
      )
    ''');
  }

  Future<bool> checkTableStructure() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> columns = await db.rawQuery(
        'PRAGMA table_info(orders)',
      );

      final requiredColumns = [
        'id', 'total', 'date', 'adresse', 'status',
        'mode_paiement', 'numero_commande'
      ];

      final existingColumns = columns.map((c) => c['name'] as String).toList();

      return requiredColumns.every((col) => existingColumns.contains(col));
    } catch (e) {
      // print('Erreur lors de la vérification de la structure: $e');
      return false;
    }
  }

  // Méthodes CRUD pour le panier
  Future<int> insertCartItem(CartItem item) async {
    final db = await database;
    return await db.insert('cart', item.toMap());
  }

  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cart');
    return List.generate(maps.length, (i) => CartItem.fromMap(maps[i]));
  }

  Future<int> updateCartItemQty(int id, int qty) async {
    final db = await database;
    return await db.update(
      'cart',
      {'qty': qty},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCartItem(int id) async {
    final db = await database;
    return await db.delete(
      'cart',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearCart() async {
    final db = await database;
    return await db.delete('cart');
  }

  // Méthodes CRUD pour les commandes
  Future<int> insertOrder(Order order, List<CartItem> items) async {
    final db = await database;
    return await db.transaction((txn) async {
      try {
        // Insérer la commande
        final orderId = await txn.insert('orders', {
          'total': order.total,
          'date': order.date,
          'adresse': order.adresseJson,
          'status': order.status,
          'mode_paiement': order.modePaiement,
          'numero_commande': order.numeroCommande,
        });

        // Insérer les articles de la commande
        for (var item in items) {
          await txn.insert('order_items', {
            'orderId': orderId,
            'productId': item.productId,
            'nom': item.nom,
            'prix': item.prix,
            'qty': item.qty,
          });
        }

        return orderId;
      } catch (e) {
        // print('Transaction failed: $e');
        rethrow;
      }
    });
  }

  Future<Order?> getOrderById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await database;
    return await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('orders');
    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }

  Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    return await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> deleteOrder(int orderId) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Supprimer d'abord les articles de la commande
      await txn.delete(
        'order_items',
        where: 'orderId = ?',
        whereArgs: [orderId],
      );

      // Puis supprimer la commande
      return await txn.delete(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }

  // Méthode pour obtenir les statistiques des commandes
  Future<Map<String, dynamic>> getOrderStats() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_orders,
        SUM(total) as total_amount,
        COUNT(CASE WHEN status = 'en_attente' THEN 1 END) as pending_orders,
        COUNT(CASE WHEN status = 'livree' THEN 1 END) as delivered_orders
      FROM orders
    ''');

    return result.first;
  }

  // Méthode pour rechercher des commandes
  Future<List<Order>> searchOrders({
    String? numeroCommande,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (numeroCommande != null) {
      whereClause += ' AND numero_commande LIKE ?';
      whereArgs.add('%$numeroCommande%');
    }

    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate);
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => Order.fromMap(maps[i]));
  }
}
