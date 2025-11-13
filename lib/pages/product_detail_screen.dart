import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/product_db.dart';
import '../models/product.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? translatedDescription;
  bool isTranslating = false;

  Future<void> _translateText(BuildContext context, String targetLang) async {
    setState(() => isTranslating = true);

    try {
      final detectUrl = Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(widget.product.description)}&langpair=xx|en');
      final detectResponse = await http.get(detectUrl);
      final detectedLang =
          json.decode(detectResponse.body)['responseData']['language'] ?? 'en';

      if (detectedLang == targetLang) {
        setState(() {
          translatedDescription = widget.product.description;
          isTranslating = false;
        });
        return;
      }

      final translateUrl = Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(widget.product.description)}&langpair=$detectedLang|$targetLang');
      final translateResponse = await http.get(translateUrl);
      final translatedText =
          json.decode(translateResponse.body)['responseData']['translatedText'];

      setState(() {
        translatedDescription = translatedText;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Translation error: $e');
    }

    if (mounted) setState(() => isTranslating = false);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await DatabaseHelper.instance.deleteProduct(widget.product.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double discountedPrice = widget.product.discount != null
        ? widget.product.price * (1 - (widget.product.discount!.toDouble() / 100))
        : widget.product.price;

    return Scaffold(
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductScreen(product: widget.product),
                ),
              );
              if (!mounted) return;
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (widget.product.imageUrl.isNotEmpty)
            Image.file(
              File(widget.product.imageUrl),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),

          if (widget.product.isSold)
            Center(
              child: Transform.rotate(
                angle: -0.5,
                child: Text(
                  'SOLD OUT',
                  style: TextStyle(
                    fontSize: 60,
                    color: Colors.white.withOpacity(0.3),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                  ),
                ),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.product.discount != null && widget.product.discount! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.product.discount!.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (widget.product.isSold)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SOLD OUT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (widget.product.discount != null && widget.product.discount! > 0)
                    Row(
                      children: [
                        Text(
                          'TND ${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 20,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'TND ${discountedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'TND ${widget.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),

                  Text(
                    translatedDescription ?? widget.product.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: isTranslating ? null : () => _translateText(context, 'fr'),
                        child: const Text('🇫🇷 French'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isTranslating ? null : () => _translateText(context, 'en'),
                        child: const Text('🇬🇧 English'),
                      ),
                    ],
                  ),

                  if (isTranslating)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Translating...', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
