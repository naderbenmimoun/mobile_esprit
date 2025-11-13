import 'package:flutter/material.dart';
import '../main.dart'; // AuthScope for current user
import '../models/product.dart';
import '../services/product_db.dart' as proddb;
import '../widgets/product_card.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';

class RecommendedProductsPage extends StatefulWidget {
  const RecommendedProductsPage({super.key});

  @override
  State<RecommendedProductsPage> createState() => _RecommendedProductsPageState();
}

class _RecommendedProductsPageState extends State<RecommendedProductsPage> {
  final _productDb = proddb.DatabaseHelper.instance;

  List<Product> _products = [];
  bool _loading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await _productDb.getProducts();
    // Simple scoring placeholder: discount first, then price asc
    products.sort((a, b) {
      final ad = (a.discount ?? 0).compareTo(b.discount ?? 0);
      if (ad != 0) return -ad; // higher discount first
      return a.price.compareTo(b.price);
    });
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  // Favorites removed

  Future<void> _addToCart(Product p) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final item = CartItem(
      productId: p.id ?? 0,
      nom: p.name,
      prix: p.price,
      qty: 1,
      image: p.imageUrl,
    );
    await cart.addItem(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produit ajouté au panier')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.watch(context);
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Produits recommandés')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Aucun produit'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _products.length,
                  itemBuilder: (context, i) {
                    final p = _products[i];
                    return Stack(
                      children: [
                        ProductCard(
                          product: p,
                          onTap: () {},
                          onAddToCart: () => _addToCart(p),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
