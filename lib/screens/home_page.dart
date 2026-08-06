// ignore_for_file: use_build_context_synchronously

import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/screens/orders/product_details.dart';
import 'package:buy_app/screens/category_page.dart';
import 'package:buy_app/screens/orders/image_order_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/models/models.dart';
import '../debug_users.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isSearching = false;
  String? selectedCategory;

  // Helper method to get first variant image or empty string
  String _getFirstVariantImage(Product product) {
    if (product.variants.isNotEmpty &&
        product.variants.first.images.isNotEmpty) {
      return product.variants.first.images.first;
    }
    return '';
  }

  late PageController _pageController;
  late AnimationController _fadeController;
  final Map<int, AnimationController> _productAnimations = {};

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    for (var controller in _productAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      final products = snapshot.docs.map((doc) => doc.data()).toList();
      return products;
    } catch (e) {
      debugPrint("🔥 Error fetching products: $e");
      return [];
    }
  }

  void _startAutoScroll() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _pageController.hasClients) {
        int currentPage = _pageController.page?.toInt() ?? 0;
        int nextPage = currentPage + 1;

        // Loop back to first page when reaching the end
        if (nextPage >= 3) {
          nextPage = 0;
        }

        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _startAutoScroll(); // Recursive call for continuous loop
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController.forward();

    loadProductsFromFirestore();
    _startAutoScroll();

    _pageController.addListener(() {
      if (_pageController.page == 1.0) {
        Future.delayed(Duration(milliseconds: 3800), () {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }
    });
  }

  void loadProductsFromFirestore() async {
    final docs = await fetchAllProducts();
    debugPrint("📊 Loaded ${docs.length} products from Firestore");

    final loadedProducts = <Product>[];

    for (int i = 0; i < docs.length; i++) {
      try {
        final doc = docs[i];
        // Use Product.fromFirestore to properly parse all fields including variants
        final product = Product.fromFirestore(doc);
        loadedProducts.add(product);

        // Create animation controller for each product
        _productAnimations[i] = AnimationController(
          duration: Duration(milliseconds: 600 + (i * 50)),
          vsync: this,
        );
        _productAnimations[i]?.forward();

        if (i < 3) {
          debugPrint("Product loaded: ${product.name}");
          debugPrint("  Brand: ${product.brand}");
          debugPrint("  Category: ${product.category}");
          debugPrint("  Has Variants: ${product.hasVariants}");
          debugPrint("  Variants Count: ${product.variants.length}");
          debugPrint("  Available Attributes: ${product.availableAttributes}");
          debugPrint("---");
        }
      } catch (e) {
        debugPrint("❌ Error loading product $i: $e");
      }
    }

    setState(() {
      products = loadedProducts;
      filteredProducts = loadedProducts;
    });

    debugPrint("✅ Total products loaded: ${products.length}");
  }

  /// Filter products by category
  void filterProductsByCategory(String categoryName) {
    setState(() {
      selectedCategory = categoryName;
      isSearching = true;

      if (categoryName.isEmpty || categoryName.toLowerCase() == 'all') {
        // Show all products
        filteredProducts = products;
        selectedCategory = null;
        isSearching = false;
      } else {
        // Filter products by category
        final categoryLower = categoryName.toLowerCase();
        filteredProducts = products.where((product) {
          final productCategory = product.category.toLowerCase();

          // Check for exact match or partial match
          return productCategory.contains(categoryLower) ||
              categoryLower.contains(productCategory) ||
              _isCategoryMatch(productCategory, categoryLower);
        }).toList();
      }
    });

    debugPrint(
      "🔍 Filtered ${filteredProducts.length} products for category: $categoryName",
    );
  }

  /// Helper method to match similar categories
  bool _isCategoryMatch(String productCategory, String filterCategory) {
    // Handle common category mappings
    Map<String, List<String>> categoryMappings = {
      'mobile': ['phone', 'smartphone', 'mobiles'],
      'electronics': ['electronic', 'gadget', 'tech', 'device'],
      'appliances': ['appliance', 'home appliance', 'kitchen appliance'],
      'fashion': ['clothing', 'clothes', 'apparel', 'wear'],
      'beauty': ['cosmetics', 'makeup', 'skincare'],
      'sports': ['sport', 'fitness', 'gym', 'outdoor'],
      'books': ['book', 'literature', 'reading'],
      'groceries': ['grocery', 'food', 'kitchen'],
    };

    for (String key in categoryMappings.keys) {
      if ((filterCategory.contains(key) || key.contains(filterCategory)) &&
          categoryMappings[key]!.any(
            (cat) =>
                productCategory.contains(cat) || cat.contains(productCategory),
          )) {
        return true;
      }
    }

    return false;
  }

  /// Clear category filter
  void clearCategoryFilter() {
    setState(() {
      selectedCategory = null;
      isSearching = false;
      filteredProducts = products;
    });
  }

  Widget _buildCategoryCard(String categoryName, IconData icon, Color color) {
    return Container(
      width: 80,
      margin: EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (categoryName.toLowerCase() == 'all') {
            clearCategoryFilter();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryPage(
                  categoryName: categoryName,
                  categoryIcon: icon,
                  categoryColor: color,
                ),
              ),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: 60,
              height: 58,
              decoration: BoxDecoration(
                color: selectedCategory == categoryName
                    ? color.withAlpha(35)
                    : color.withAlpha(12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selectedCategory == categoryName
                      ? color.withAlpha(200)
                      : color.withAlpha(40),
                  width: selectedCategory == categoryName ? 2.5 : 1,
                ),
                boxShadow: selectedCategory == categoryName
                    ? [
                        BoxShadow(
                          color: color.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            SizedBox(height: 6),
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selectedCategory == categoryName
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: selectedCategory == categoryName
                    ? color
                    : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: ColorPallete.color1),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app_rounded),
              title: Text('Sign Out'),
              onTap: () {
                _authService.signOut();
                Navigator.pushNamed(context, '/login');
              },
            ),
            ListTile(
              leading: Icon(Icons.sync),
              title: Text('Migrate Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/migration-tool');
              },
            ),
            ListTile(
              leading: Icon(Icons.bug_report),
              title: Text('Debug Users'),
              onTap: () async {
                Navigator.pop(context);
                await DebugUsers.listAllUsers();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Check console for debug output')),
                );
              },
            ),
          ],
        ),
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: ColorPallete.color1,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Products...',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : isSearching && filteredProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try different keywords',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Modern App Bar
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  elevation: 0,
                  titleSpacing: 0,
                  backgroundColor: ColorPallete.color1,
                  foregroundColor: Colors.white,
                  expandedHeight: 110,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ColorPallete.color1,
                            ColorPallete.color1.withAlpha(230),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          /*Text(
                                "Buy App",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),*/
                        ],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(65),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Hero(
                        tag: 'search_bar',
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(28),
                          shadowColor: Colors.black26,
                          child: InkWell(
                            onTap: () =>
                                Navigator.pushNamed(context, '/search'),
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      color: Colors.grey[600],
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Search products...",
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ImageOrderScreen(),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Categories Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedCategory != null)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: AnimatedOpacity(
                              opacity: selectedCategory != null ? 1.0 : 0.0,
                              duration: Duration(milliseconds: 300),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: ColorPallete.color1,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${filteredProducts.length} products',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: clearCategoryFilter,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        'Clear',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ColorPallete.color1,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            physics: BouncingScrollPhysics(),
                            children: [
                              _buildCategoryCard(
                                'All',
                                Icons.grid_view,
                                Colors.grey,
                              ),
                              _buildCategoryCard(
                                'Mobile',
                                Icons.smartphone,
                                Colors.blue,
                              ),
                              _buildCategoryCard(
                                'Electronics',
                                Icons.electrical_services,
                                Colors.orange,
                              ),
                              _buildCategoryCard(
                                'Appliances',
                                Icons.home,
                                Colors.green,
                              ),
                              _buildCategoryCard(
                                'Fashion',
                                Icons.shopping_bag,
                                Colors.purple,
                              ),
                              _buildCategoryCard(
                                'Books',
                                Icons.book,
                                Colors.brown,
                              ),
                              _buildCategoryCard(
                                'Sports',
                                Icons.sports_football,
                                Colors.red,
                              ),
                              _buildCategoryCard(
                                'Beauty',
                                Icons.face_retouching_natural,
                                Colors.pink,
                              ),
                              _buildCategoryCard(
                                'Groceries',
                                Icons.local_grocery_store,
                                Colors.teal,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Banner with improved animation
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            PageView(
                              controller: _pageController,
                              scrollDirection: Axis.horizontal,
                              children: List.generate(3, (index) {
                                return AnimatedBuilder(
                                  animation: _pageController,
                                  builder: (context, child) {
                                    double value = 1.0;
                                    if (_pageController
                                        .position
                                        .haveDimensions) {
                                      value = _pageController.page! - index;
                                      value = (1 - (value.abs() * 0.3)).clamp(
                                        0.0,
                                        1.0,
                                      );
                                    }
                                    return Transform.scale(
                                      scale: value,
                                      child: child,
                                    );
                                  },
                                  child: Image.asset(
                                    "assets/banner.jpg",
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[300],
                                              child: Center(
                                                child: Icon(
                                                  Icons.image,
                                                  size: 64,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                  ),
                                );
                              }),
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  return AnimatedBuilder(
                                    animation: _pageController,
                                    builder: (context, child) {
                                      final page = _pageController.page ?? 0.0;
                                      final isActive = (page.round() == index);

                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          width: isActive ? 24 : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? ColorPallete.color1
                                                : Colors.grey[400],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            boxShadow: isActive
                                                ? [
                                                    BoxShadow(
                                                      color: ColorPallete.color1
                                                          .withAlpha(100),
                                                      blurRadius: 6,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Brand Logos Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Brands Available',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 82,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            physics: BouncingScrollPhysics(),
                            children: [
                              _buildBrandLogo(
                                'Apple',
                                'assets/BrandLogos/Mobile/apple.png',
                              ),
                              _buildBrandLogo(
                                'Samsung',
                                'assets/BrandLogos/Mobile/samsung.png',
                              ),
                              _buildBrandLogo(
                                'Xiaomi',
                                'assets/BrandLogos/Mobile/xiaomi.png',
                              ),
                              _buildBrandLogo(
                                'Realme',
                                'assets/BrandLogos/Mobile/realme.png',
                              ),
                              _buildBrandLogo(
                                'iQOO',
                                'assets/BrandLogos/Mobile/iqoo.png',
                              ),
                              _buildBrandLogo(
                                'Motorola',
                                'assets/BrandLogos/Mobile/motorola.png',
                              ),
                              _buildBrandLogo(
                                'boAt',
                                'assets/BrandLogos/Electronics/boat.png',
                              ),
                              _buildBrandLogo(
                                'Sony',
                                'assets/BrandLogos/Electronics/sony.png',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Products Grid with staggered animations
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = filteredProducts[index];
                      final controller = _productAnimations[index];

                      return ScaleTransition(
                        scale:
                            controller?.drive(Tween(begin: 0.8, end: 1.0)) ??
                            AlwaysStoppedAnimation(1.0),
                        child: FadeTransition(
                          opacity:
                              controller?.drive(Tween(begin: 0.0, end: 1.0)) ??
                              AlwaysStoppedAnimation(1.0),
                          child: _buildProductCard(product),
                        ),
                      );
                    }, childCount: filteredProducts.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.58,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBrandLogo(String brandName, String assetPath) {
    return Container(
      margin: EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () {
          // Filter products by brand
          setState(() {
            isSearching = true;
            filteredProducts = products.where((product) {
              final productBrand = product.brand.toLowerCase();
              final searchBrand = brandName.toLowerCase();

              // Handle Xiaomi-Redmi relationship
              if (searchBrand == 'xiaomi') {
                return productBrand.contains('xiaomi') ||
                    productBrand.contains('redmi');
              }

              // Handle other brand relationships
              return productBrand.contains(searchBrand) ||
                  searchBrand.contains(productBrand);
            }).toList();
          });

          // Show snackbar with filter info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Showing ${filteredProducts.length} products from $brandName',
              ),
              duration: Duration(seconds: 2),
              backgroundColor: ColorPallete.color1,
            ),
          );
        },
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.withAlpha(25), width: 1),
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
            SizedBox(height: 6),
            Text(
              brandName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build modern product card with hover effects and smooth animations
  Widget _buildProductCard(Product product) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 0.5),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Stack(
                    children: [
                      Image.network(
                        _getFirstVariantImage(product),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                ColorPallete.color1,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey[300],
                        ),
                      ),
                      // Discount badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-20%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      SizedBox(
                        height: 25,
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.grey[900],
                            height: 1.2,
                          ),
                        ),
                      ),
                      // Rating
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          SizedBox(width: 3),
                          Text(
                            '4.5',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '(2.3k)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Price section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ColorPallete.color1,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '₹${(product.price * 1.25).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Free Delivery',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
