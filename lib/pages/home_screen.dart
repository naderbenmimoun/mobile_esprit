import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../services/product_db.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import 'client_home.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({super.key, required this.onToggleTheme, required this.isDarkMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> allProducts = [];
  List<Product> displayedProducts = [];
  List<Product> wishlist = [];

  TextEditingController searchController = TextEditingController();
  String selectedSort = 'None';
  int _selectedIndex = 0;
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Discounts',
    'Shoes',
    'Pants',
    'Shirts',
    'Bags',
    'Jackets',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final dbHelper = DatabaseHelper.instance;
    final products = await dbHelper.getProducts();
    if (products.isEmpty) {
      await _seedProducts();
    }
    final updated = await dbHelper.getProducts();
    setState(() {
      allProducts = updated;
      displayedProducts = updated;
    });
  }

  Future<void> _seedProducts() async {
    final db = DatabaseHelper.instance;
    final samples = <Product>[
      Product(
        name: 'White T-Shirt',
        imageUrl: 'lib/assets/categories/products/white t-shirt.jpg',
        price: 39.90,
        description: 'T-shirt blanc basique 100% coton, coupe classique et confortable.',
        category: 'Shirts',
        discount: 10,
      ),
      Product(
        name: 'Blue Jeans',
        imageUrl: 'lib/assets/categories/products/blue jeans.jpg',
        price: 119.00,
        description: 'Jeans bleu coupe slim, denim résistant et confortable.',
        category: 'Pants',
        discount: 0,
      ),
      Product(
        name: 'Sneakers',
        imageUrl: 'lib/assets/categories/products/sneakers.jpg',
        price: 199.00,
        description: 'Baskets légères avec semelle amortissante.',
        category: 'Shoes',
        discount: 15,
      ),
      Product(
        name: 'Everyday Bag',
        imageUrl: 'lib/assets/categories/products/bags.jpg',
        price: 149.50,
        description: 'Sac pratique pour un usage quotidien, multiples poches.',
        category: 'Bags',
        discount: 0,
      ),
      Product(
        name: 'Casual Jacket',
        imageUrl: 'lib/assets/categories/products/jackets.jpg',
        price: 249.00,
        description: 'Veste décontractée idéale pour mi-saison.',
        category: 'Jackets',
        discount: 5,
      ),
    ];
    for (final p in samples) {
      await db.insertProduct(p);
    }
  }

  void _filterProducts() {
    List<Product> filtered = List.of(allProducts);

    if (selectedCategory != 'All') {
      if (selectedCategory.toLowerCase() == 'discounts') {
        filtered = filtered.where((p) => (p.discount ?? 0) > 0).toList();
      } else {
        filtered = filtered.where((p) => p.category.toLowerCase() == selectedCategory.toLowerCase()).toList();
      }
    }

    final query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) => p.name.toLowerCase().contains(query)).toList();
    }

    setState(() {
      displayedProducts = filtered;
    });

    _applySort();
  }

  void _searchProducts(String query) => _filterProducts();

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
    _filterProducts();
  }

  void _applySort() {
    if (selectedSort == 'Price: Low to High') {
      displayedProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (selectedSort == 'Price: High to Low') {
      displayedProducts.sort((a, b) => b.price.compareTo(a.price));
    }
  }

  void _onSortChanged(String? value) {
    if (value == null) return;
    setState(() {
      selectedSort = value;
      _applySort();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleWishlist(Product product) {
    setState(() {
      if (wishlist.contains(product)) {
        wishlist.remove(product);
      } else {
        wishlist.add(product);
      }
    });
  }

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

  Widget _buildHomeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: _searchProducts,
                    decoration: const InputDecoration(
                      hintText: 'Search for clothes, shoes, or accessories...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      searchController.clear();
                      _filterProducts();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.blueAccent),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;
              final String imagePath = 'lib/assets/categories/${category.toLowerCase()}.png';

              return GestureDetector(
                onTap: () => _onCategorySelected(category),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.grey[200],
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.sort, color: Colors.blueAccent),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('None'),
                  selected: selectedSort == 'None',
                  onSelected: (_) => _onSortChanged('None'),
                  selectedColor: Colors.blueAccent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: selectedSort == 'None' ? Colors.blueAccent : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Low → High'),
                  selected: selectedSort == 'Price: Low to High',
                  onSelected: (_) => _onSortChanged('Price: Low to High'),
                  selectedColor: Colors.blueAccent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: selectedSort == 'Price: Low to High' ? Colors.blueAccent : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('High → Low'),
                  selected: selectedSort == 'Price: High to Low',
                  onSelected: (_) => _onSortChanged('Price: High to Low'),
                  selectedColor: Colors.blueAccent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: selectedSort == 'Price: High to Low' ? Colors.blueAccent : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: displayedProducts.isEmpty
              ? const Center(child: Text('No products found 😔'))
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      final product = displayedProducts[index];
                      final isFavorite = wishlist.contains(product);
                      return Stack(
                        children: [
                          ProductCard(
                            product: product,
                            onTap: () async {
                              final deleted = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
                              );
                              if (deleted == true) {
                                _loadProducts();
                              }
                            },
                            onToggleFavorite: () => _toggleWishlist(product),
                            onAddToCart: () => _addToCart(product),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => _toggleWishlist(product),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWishlistTab() {
    return Column(
      children: [
        Expanded(
          child: wishlist.isEmpty
              ? const Center(
                  child: Text(
                    '❤️ Your Wishlist is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    itemCount: wishlist.length,
                    itemBuilder: (context, index) {
                      final product = wishlist[index];
                      return Stack(
                        children: [
                          ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            onToggleFavorite: () => _toggleWishlist(product),
                            onAddToCart: () => _addToCart(product),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _toggleWishlist(product),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👤 Profile Page', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Admin Dashboard'),
            onPressed: () async {
              final Uri url = Uri.parse('https://google.com');
              final bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
              if (!launched && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impossible d’ouvrir le site.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _buildHomeTab(),
      _buildWishlistTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Clothes Marketplace'
              : _selectedIndex == 1
                  ? 'Wishlist'
                  : 'Profile',
        ),
        centerTitle: true,
        actions: [
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return IconButton(
              icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              onPressed: widget.onToggleTheme,
              tooltip: isDark ? 'Mode clair' : 'Mode sombre',
            );
          }),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const ListTile(
                title: Text('Menu'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('Accueil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientHome()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Clothes Marketplace'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Wishlist'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 2);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Mon panier'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/panier');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Historique de commande'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/historique');
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Mes réclamations'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/reclamations');
                },
              ),
              ListTile(
                leading: const Icon(Icons.recommend_outlined),
                title: const Text('Produits recommandés'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/recommendedProducts');
                },
              ),
            ],
          ),
        ),
      ),
      body: _selectedIndex == 0
          ? Column(
              children: [
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _DashedDivider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    thickness: 1.2,
                    dashWidth: 6,
                    dashGap: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: tabs[_selectedIndex]),
              ],
            )
          : tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(onProductAdded: _noop),
                  ),
                );
                await _loadProducts();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
    );
  }

  static void _noop() {}
}

class _DashedDivider extends StatelessWidget {
  final Color? color;
  final double thickness;
  final double dashWidth;
  final double dashGap;

  const _DashedDivider({
    this.color,
    this.thickness = 1,
    this.dashWidth = 5,
    this.dashGap = 3,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).dividerColor;
    return SizedBox(
      height: thickness,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedPainter(
          color: c,
          thickness: thickness,
          dashWidth: dashWidth,
          dashGap: dashGap,
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double dashWidth;
  final double dashGap;

  _DashedPainter({
    required this.color,
    required this.thickness,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      final x2 = (x + dashWidth).clamp(0, size.width);
      canvas.drawLine(Offset(x, y), Offset(x, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
