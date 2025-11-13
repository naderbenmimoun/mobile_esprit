import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onToggleFavorite,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = (product.discount ?? 0) > 0;
    final discountedPrice = hasDiscount
        ? product.price * (1 - (product.discount!.toDouble() / 100))
        : product.price;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildImage(product.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (onToggleFavorite != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            product.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: product.isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: onToggleFavorite,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (hasDiscount)
                    Row(
                      children: [
                        Text(
                          'TND ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${product.discount}%',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  Text(
                    'TND ${discountedPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (onAddToCart != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Tooltip(
                        message: 'Ajouter au panier',
                        child: IconButton.filled(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(8),
                          iconSize: 20,
                          onPressed: onAddToCart,
                          icon: const Icon(Icons.add_shopping_cart),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    final isAsset = path.isNotEmpty && path.startsWith('lib/assets/');
    if (isAsset) {
      return Image.asset(
        path,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 160,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    if (path.isNotEmpty) {
      final f = File(path);
      if (f.existsSync()) {
        return Image.file(
          f,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }
    return Container(
      height: 160,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}
