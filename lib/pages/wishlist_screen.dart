import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';

class WishlistScreen extends StatelessWidget {
  final List<Product> wishlist;
  const WishlistScreen({super.key, required this.wishlist});

  @override
  Widget build(BuildContext context) {
    if (wishlist.isEmpty) {
      return const Center(
        child: Text(
          'Your Wishlist is empty ❤️',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: wishlist.length,
      itemBuilder: (context, index) {
        final product = wishlist[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (product.imageUrl.isNotEmpty && File(product.imageUrl).existsSync())
                  ? Image.file(
                      File(product.imageUrl),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox(
                      width: 60,
                      height: 60,
                      child: Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                    ),
            ),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              'TND ${product.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),
        );
      },
    );
  }
}
