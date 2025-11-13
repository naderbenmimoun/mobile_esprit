// lib/widgets/outfit_card.dart
import 'package:flutter/material.dart';
import '../models/outfit.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback onAddToCart;
  final VoidCallback onSkip;

  const OutfitCard({
    super.key,
    required this.outfit,
    required this.onAddToCart,
    required this.onSkip,
  });

  Widget _buildImage() {
    final borderRadius = BorderRadius.circular(16);

    if (outfit.imagePath.startsWith('http')) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          outfit.imagePath,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 100,
              height: 100,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        (progress.expectedTotalBytes ?? 1)
                    : null,
                color: const Color(0xFFB8C6FF), // pastel blue
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            width: 100,
            height: 100,
            color: Colors.blue.shade50,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          outfit.imagePath,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 100,
            height: 100,
            color: Colors.blue.shade50,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF4F1FB), // very light lilac background
      elevation: 5,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: outfit.id,
              child: _buildImage(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF3A3A6A), // deep lilac text
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Match: ${outfit.matchScore.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFF6E8BFF), // soft pastel blue
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${outfit.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8C6FF), // pastel blue
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 14),
                        ),
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: const Text('Favorite'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: onSkip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF9F8CFF), // soft lilac
                          side: const BorderSide(color: Color(0xFF9F8CFF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.all(10),
                        ),
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
