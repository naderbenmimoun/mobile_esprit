import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../services/db_help.dart';
import '../models/order.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final DBHelper _db = DBHelper.instance;

  List<CartItem> get items => List.unmodifiable(_items);

  double get total =>
      _items.fold(0, (sum, item) => sum + (item.prix * item.qty));

  Future<void> addItem(CartItem item) async {
    final id = await _db.insertCartItem(item); // Retourne l’ID SQLite
    _items.add(CartItem(
      id: id,
      productId: item.productId,
      nom: item.nom,
      prix: item.prix,
      qty: item.qty,
      image: item.image,
    ));
    notifyListeners();
  }

  Future<void> removeItem(int id) async {
    _items.removeWhere((it) => it.id == id);
    await _db.deleteCartItem(id);
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _db.clearCart();
    notifyListeners();
  }

  Future<void> loadCart() async {
    final data = await _db.getCartItems();
    _items
      ..clear()
      ..addAll(data);
    notifyListeners();
  }

  Future<void> increaseQty(int id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = CartItem(
        id: _items[index].id,
        productId: _items[index].productId,
        nom: _items[index].nom,
        prix: _items[index].prix,
        qty: _items[index].qty + 1,
        image: _items[index].image,
      );
      await _db.updateCartItemQty(id, _items[index].qty);
      notifyListeners();
    }
  }

  Future<void> decreaseQty(int id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1 && _items[index].qty > 1) {
      _items[index] = CartItem(
        id: _items[index].id,
        productId: _items[index].productId,
        nom: _items[index].nom,
        prix: _items[index].prix,
        qty: _items[index].qty - 1,
        image: _items[index].image,
      );
      await _db.updateCartItemQty(id, _items[index].qty);
      notifyListeners();
    }
  }

  Future<int> placeOrder({
    required String? adresse,
    required String modePaiement,
    String? numeroCommande,
    String? date,
  }) async {
    try {
      final order = Order.create(
        total: total,
        modePaiement: modePaiement,
        adresseJson: adresse,
      );

      final orderId = await _db.insertOrder(order, _items);
      await clearCart();
      return orderId;
    } catch (e) {
      debugPrint('Erreur lors de la création de la commande: $e');
      rethrow;
    }
  }
}
