import 'package:flutter/material.dart';
import '../main.dart'; // AuthScope
import '../models/product.dart';
import '../services/product_favorite_db.dart';
import '../widgets/product_card.dart';

class ProductFavoritesPage extends StatefulWidget {
  const ProductFavoritesPage({super.key});

  @override
  State<ProductFavoritesPage> createState() => _ProductFavoritesPageState();
}

class _ProductFavoritesPageState extends State<ProductFavoritesPage> {
  final _favDb = ProductFavoriteDB.instance;
  List<Product> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = AuthScope.watch(context);
    final user = auth.currentUser!;
    final items = await _favDb.listFavoriteProducts(user.id!);
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris (Produits)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Aucun favori'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final p = _items[i];
                    return ProductCard(
                      product: p,
                      onTap: () {},
                      onToggleFavorite: () async {
                        final auth = AuthScope.watch(context);
                        await _favDb.remove(p.id!, auth.currentUser!.id!);
                        await _load();
                      },
                    );
                  },
                ),
    );
  }
}
