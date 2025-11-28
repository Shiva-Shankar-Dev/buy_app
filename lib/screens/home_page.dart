import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/screens/orders/product_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/models/models.dart'; // Import the models
import '../debug_users.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isSearching = false;
  late PageController _pageController;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
    _pageController.dispose();
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
    loadProductsFromFirestore();
    _startAutoScroll();

    _pageController.addListener(() {
      if (_pageController.page == 1.0) {
        // When reaching last page, jump smoothly back
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
    print("📊 Loaded ${docs.length} products from Firestore");

    final loadedProducts = <Product>[];

    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i];
      final product = Product(
        name: doc['name'] ?? 'Untitled',
        brand: doc['brand'] ?? '',
        description: doc['description'] ?? '',
        price: (doc['price'] ?? 0).toDouble(),
        deliveryTime: doc['Delivery Time'] ?? 'N/A',
        category: doc['category'] ?? '',
        images: List<String>.from(doc['images'] ?? []),
        keywords: List<String>.from(doc['keywords'] ?? []),
        pid: doc['pid'] ?? '',
        stockQuantity: doc['stockQuantity'] ?? 0,
      );

      // Debug first few products
      if (i < 3) {
        print("Product loaded: ${product.name}");
        print("  Brand: ${product.brand}");
        print("  Category: ${product.category}");
        print("  Keywords: ${product.keywords}");
        print("---");
      }

      loadedProducts.add(product);
    }

    setState(() {
      products = loadedProducts;
      filteredProducts = loadedProducts; // Initialize filtered products
    });

    print("✅ Total products loaded: ${products.length}");
  }

  Widget _buildCategoryCard(
    String categoryName,
    IconData icon,
    Color color
  ) {
    return Container(
      width: 80,
      margin: EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          // Filter products by category
          _searchController.text = categoryName;
          //searchProducts(categoryName);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 58,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            SizedBox(height: 5),
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
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
              decoration: BoxDecoration(color: colorPallete.color1),
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

      body: products.isEmpty ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colorPallete.color1),
            SizedBox(height: 16),
            Text(
              'Loading Products...',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      ) : isSearching && filteredProducts.isEmpty ? Center(
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
      ) : CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            titleSpacing: 0,
            backgroundColor: colorPallete.color1,
            foregroundColor: Colors.white,
            expandedHeight: 100,
            title: Text(
              "Buy App",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 5.0,
                  horizontal: 8.0,
                ),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, '/search'),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 13.0, horizontal: 10.0),
                        child: Row(
                          children: [
                            SizedBox(width: 5,),
                            Icon(Icons.search),
                            SizedBox(width: 5,),
                            Text("Search products..."),
                            Spacer(),
                            Icon(Icons.camera_alt_outlined),
                            SizedBox(width: 5,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 85,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
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
                // Banner Image
                // dart
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Image.asset(
                              "assets/banner.jpg",
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: 200,
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
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Image.asset(
                              "assets/banner.jpg",
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: 200,
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
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Image.asset(
                              "assets/banner.jpg",
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: double.infinity,
                                height: 200,
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
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 16,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                final page = _pageController.page ?? 0.0;
                                final isActive = (page.round() == index);
                                final progress = (page - page.toInt()).abs();

                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  child: isActive
                                      ? SizedBox(
                                    width: 24,
                                    height: 8,
                                    child: LinearProgressIndicator(
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(20),
                                      backgroundColor: Colors.grey[400],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorPallete.color1,
                                      ),
                                      value: isActive ? progress : 1.0,
                                    ),
                                  )
                                      : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      )

                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = filteredProducts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailPage(product: product),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0.5,
                    shadowColor: Colors.black12,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Hero(
                              tag: 'product',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  product.images.isNotEmpty
                                      ? product.images.first
                                      : '',
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Container(
                                    height: 140,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 45,
                                  width: double.infinity,
                                  child: Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                  ],
                                ),
                                Text(
                                  '₹${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorPallete.color1,
                                  ),
                                ),
                                SizedBox(height: 2),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: filteredProducts.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
