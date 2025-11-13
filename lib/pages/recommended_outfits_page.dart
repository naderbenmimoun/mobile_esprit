import 'package:flutter/material.dart';
import '../widgets/outfit_card.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/filter_chip_widget.dart';
import '../models/outfit.dart';
import '../models/user_profile.dart';
import '../database/database_helper.dart';
import 'try_on_page.dart';
import 'favorites_page.dart';
import 'tryon_history_page.dart';

class RecommendedOutfitsPage extends StatefulWidget {
  const RecommendedOutfitsPage({super.key});

  @override
  State<RecommendedOutfitsPage> createState() => _RecommendedOutfitsPageState();
}

class _RecommendedOutfitsPageState extends State<RecommendedOutfitsPage> {
  final db = DatabaseHelper.instance;
  UserProfile? userProfile;
  List<Outfit> outfits = [];
  final List<Outfit> _selectedOutfits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    userProfile = await db.getUserProfile();
    outfits = await db.getAllOutfits();

    if (userProfile != null && outfits.isNotEmpty) {
      outfits = await db.getRecommendedOutfits(
        userProfile!.gender,
        userProfile!.morphology,
        userProfile!.season,
      );
    }

    setState(() => isLoading = false);
  }

  void _toggleSelection(Outfit outfit) {
    setState(() {
      if (_selectedOutfits.contains(outfit)) {
        _selectedOutfits.remove(outfit);
      } else {
        _selectedOutfits.add(outfit);
      }
    });
  }

  void _trySelected() {
    if (_selectedOutfits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one outfit')),
      );
      return;
    }

    final outfit = _selectedOutfits.first;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TryOnPage(outfit: outfit)),
    );
  }

  /// ✅ FIXED FAVORITE LOGIC
  Future<void> _toggleFavorite(Outfit outfit) async {
    final isFav = await db.isFavorite(outfit.id);

    if (isFav) {
      // Instead of removing, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💜 This outfit is already in your favorites!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      await db.addFavorite(outfit.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Added to favorites!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {});
  }

  Future<void> _resetProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Profile?'),
        content: const Text(
          'This will delete your profile and restart the setup process.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await db.deleteUserProfile();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile reset')));
    }
  }

  void _skipOutfit(Outfit outfit) async {
    await db.deleteOutfit(outfit.id);
    setState(() {
      outfits.removeWhere((o) => o.id == outfit.id);
      _selectedOutfits.remove(outfit);
    });
  }

  

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Outfits'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favorites',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Try-on History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TryOnHistoryPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_backup_restore),
            tooltip: 'Reset Profile',
            onPressed: _resetProfile,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (userProfile != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: UserProfileCard(
                  morphology: userProfile!.morphology,
                  gender: userProfile!.gender,
                  season: userProfile!.season,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: const [
                  FilterChipWidget(label: 'Recommended'),
                  FilterChipWidget(label: 'Trending'),
                  FilterChipWidget(label: 'New'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: outfits.isEmpty
                  ? const Center(child: Text('No outfits available'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: outfits.length,
                      itemBuilder: (context, index) {
                        final outfit = outfits[index];
                        final isSelected = _selectedOutfits.contains(outfit);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _toggleSelection(outfit),
                            child: Stack(
                              children: [
                                OutfitCard(
                                  outfit: outfit,
                                  onAddToCart: () => _toggleFavorite(outfit),
                                  onSkip: () => _skipOutfit(outfit),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.green,
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (outfits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _trySelected,
                  icon: const Icon(Icons.play_circle_fill),
                  label: Text(
                    _selectedOutfits.isEmpty
                        ? 'Select outfits to try'
                        : 'Try ${_selectedOutfits.length} selected outfit(s)',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
