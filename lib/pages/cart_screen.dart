import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _autoInjected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_autoInjected) {
      _autoInjected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeInsertTestItem());
    }
  }

  Future<void> _maybeInsertTestItem() async {
    if (!kDebugMode) return;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.loadCart();
    if (cartProvider.items.isEmpty) {
      final testItem = CartItem(
        productId: DateTime.now().millisecondsSinceEpoch % 100000,
        nom: 'T-shirt de test',
        prix: 9.99,
        qty: 1,
        image: null,
      );
      await cartProvider.addItem(testItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit de test ajouté automatiquement (debug)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.colorScheme.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white, size: 32),
            const SizedBox(width: 10),
            Text(
              'Mon Panier',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Historique',
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/historique'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stepCircle(theme, 1, done: true),
                  _stepLine(theme),
                  _stepCircle(theme, 2),
                  _stepLine(theme),
                  _stepCircle(theme, 3),
                ],
              ),
              const SizedBox(height: 28),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.items.isEmpty) {
                    return Center(
                      child: Text(
                        'Votre panier est vide.',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: cart.items.map((item) {
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 14,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                            child: const Icon(Icons.shopping_bag, size: 28),
                          ),
                          title: Text(
                            item.nom,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text('Quantité : ', style: theme.textTheme.bodyMedium),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  cart.decreaseQty(item.id ?? item.productId);
                                },
                              ),
                              Text(item.qty.toString(), style: theme.textTheme.bodyMedium),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () {
                                  cart.increaseQty(item.id ?? item.productId);
                                },
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(item.prix * item.qty).toStringAsFixed(2)} €',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  cart.removeItem(item.id ?? item.productId);
                                },
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 18),
              Divider(
                height: 32,
                thickness: 1,
                color: primaryColor.withOpacity(0.5),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total :',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${cart.total.toStringAsFixed(2)} €',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 23,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.local_shipping, color: Colors.white, size: 26),
                  label: const Text(
                    'Passer à la livraison',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/livraison'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCircle(ThemeData theme, int number, {bool done = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: done ? theme.colorScheme.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check, color: Colors.white, size: 22)
          : Text(
              number.toString(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
    );
  }

  Widget _stepLine(ThemeData theme) =>
      Container(width: 40, height: 2, color: theme.colorScheme.primary);
}
