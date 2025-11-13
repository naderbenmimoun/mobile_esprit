import 'package:flutter/material.dart';
import '../widgets/outfit_card.dart';
import '../models/outfit.dart';
import '../database/database_helper.dart';
import 'try_on_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final db = DatabaseHelper.instance;
  List<Outfit> favorites = [];
  bool isLoading = true;

  final Color primaryLilac = const Color(0xFFB388FF);
  final Color secondaryBlue = const Color(0xFF8C9EFF);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => isLoading = true);
    favorites = await db.getFavoriteOutfits();
    setState(() => isLoading = false);
  }

  Future<void> _removeFavorite(String outfitId) async {
    await db.removeFavorite(outfitId);
    await _loadFavorites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from favorites')),
    );
  }

  Future<void> _editFavorite(Outfit outfit) async {
    final newNameController = TextEditingController(text: outfit.name);

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Edit Favorite Outfit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: newNameController,
                  decoration: InputDecoration(
                    labelText: 'Outfit name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryLilac,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final newName = newNameController.text.trim();
                        if (newName.isNotEmpty) {
                          final updated = outfit.copyWith(name: newName);
                          await db.updateOutfit(updated);
                          if (!mounted) return;
                          Navigator.pop(context);
                          await _loadFavorites();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Outfit updated')),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _tryOnOutfit(Outfit outfit) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TryOnPage(outfit: outfit)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: primaryLilac,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: const Text('My Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryLilac))
            : favorites.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 80, color: primaryLilac.withOpacity(0.5)),
                        const SizedBox(height: 10),
                        Text(
                          'No favorites yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: primaryLilac.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favorites.length,
                    itemBuilder: (context, i) {
                      final outfit = favorites[i];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              const Color(0xFFEDE7F6).withOpacity(0.9)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryLilac.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              outfit.imagePath,
                              width: 65,
                              height: 65,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            outfit.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            'Price: \$${outfit.price.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: secondaryBlue),
                            onSelected: (value) {
                              if (value == 'try') _tryOnOutfit(outfit);
                              if (value == 'edit') _editFavorite(outfit);
                              if (value == 'delete') _removeFavorite(outfit.id);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'try', child: Text('Try On')),
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Remove')),
                            ],
                          ),
                          onTap: () => _tryOnOutfit(outfit),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
