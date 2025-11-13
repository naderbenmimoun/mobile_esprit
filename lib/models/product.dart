class Product {
  final int? id;
  final String name;
  final String imageUrl;
  final double price;
  final String description;
  final String category;
  bool isFavorite;
  final bool isSold;
  final int? discount;

  Product({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.category,
    this.isFavorite = false,
    this.isSold = false,
    this.discount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'description': description,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
      'isSold': isSold ? 1 : 0,
      'discount': discount,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      isSold: (map['isSold'] ?? 0) == 1,
      discount: map['discount'] == null
          ? 0
          : (map['discount'] is double
              ? (map['discount'] as double).toInt()
              : map['discount']),
    );
  }
}
