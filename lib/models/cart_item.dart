class CartItem {
  final int? id;
  final int productId;
  final String nom;
  final double prix;
  final int qty;
  final String? image;

  CartItem({
    this.id,
    required this.productId,
    required this.nom,
    required this.prix,
    required this.qty,
    this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'nom': nom,
      'prix': prix,
      'qty': qty,
      'image': image,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int?,
      productId: map['productId'] as int,
      nom: map['nom'] as String,
      prix: (map['prix'] as num).toDouble(),
      qty: map['qty'] as int,
      image: map['image'] as String?,
    );
  }
}
