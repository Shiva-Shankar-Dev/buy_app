import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/screens/product_detail_page.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  void initState() {
    super.initState();
    loadProductsFromFirestore();
  }

  void loadProductsFromFirestore() async {
    final docs = await fetchAllProducts();
    print("📊 Loaded ${docs.length} products from Firestore");

    final loadedProducts = <Product>[];

    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i];
      final product = Product(
        title: doc['title'] ?? 'Untitled',
        description: doc['description'] ?? '',
        price: (doc['price'] ?? 0).toDouble(),
        deliveryTime: doc['Delivery Time'] ?? 'N/A',
        reviews: doc['ratings'] ?? 'No ratings',
        images: List<String>.from(doc['images'] ?? []),
        extraFields: Map<String, dynamic>.from(doc['extraFields'] ?? {}),
        sellerId: doc['sellerId'],
      );

      // Debug first few products
      if (i < 3) {
        print("Product loaded: ${product.title}");
        print("  ExtraFields: ${product.extraFields}");
        print(
          "  Category: ${product.extraFields['category'] ?? 'No category'}",
        );
        print("  Brand: ${product.extraFields['brand'] ?? 'No brand'}");
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

  bool _matchesSearch(String text, String query) {
    if (text.isEmpty || query.isEmpty) return false;

    final textLower = text.toLowerCase().trim();
    final queryLower = query.toLowerCase().trim();

    print("🔍 Checking match: '$textLower' vs '$queryLower'");

    // Check if the whole text starts with the query
    if (textLower.startsWith(queryLower)) {
      print("✅ Full text match");
      return true;
    }

    // Word-by-word prefix matching (only from start of words)
    final words = textLower.split(RegExp(r'\s+'));
    for (String word in words) {
      if (word.isNotEmpty && word.startsWith(queryLower)) {
        print("✅ Word match: '$word' starts with '$queryLower'");
        return true;
      }
    }

    // Segment prefix matching for compound words/categories
    // Split by common separators and check prefixes from start only
    final segments = textLower.split(RegExp(r'[,\-_\s]+'));
    for (String segment in segments) {
      if (segment.isNotEmpty && segment.startsWith(queryLower)) {
        print("✅ Segment match: '$segment' starts with '$queryLower'");
        return true;
      }
    }

    print("❌ No match found");
    return false;
  }

  void searchProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = products;
        isSearching = false;
      } else {
        isSearching = true;
        print("🔍 Searching for: '$query'");
        print("📦 Total products: ${products.length}");

        filteredProducts = products.where((product) {
          // Search in title with smart matching
          final titleMatch = _matchesSearch(product.title, query);

          // Search in description with smart matching
          final descriptionMatch = _matchesSearch(product.description, query);

          // Search in brand (from extraFields) with smart matching
          final brand = product.extraFields['brand']?.toString() ?? '';
          final brandMatch = _matchesSearch(brand, query);

          // Search in category (from extraFields) with smart matching
          final category = product.extraFields['category']?.toString() ?? '';
          final categoryMatch = _matchesSearch(category, query);

          final isMatch =
              titleMatch || descriptionMatch || brandMatch || categoryMatch;

          // Debug logging for first few products
          if (products.indexOf(product) < 3) {
            print("Product: ${product.title}");
            print("  Category: '$category'");
            print("  Brand: '$brand'");
            print("  Title match: $titleMatch, Desc match: $descriptionMatch");
            print("  Brand match: $brandMatch, Category match: $categoryMatch");
            print("  Overall match: $isMatch");
            print("---");
          }

          return isMatch;
        }).toList();

        print("🎯 Found ${filteredProducts.length} matching products");
      }
    });
  }

  void clearSearch() {
    _searchController.clear();
    setState(() {
      filteredProducts = products;
      isSearching = false;
    });
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

      body: products.isEmpty
          ? Center(
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
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: colorPallete.color1,
                  foregroundColor: Colors.white,
                  expandedHeight: 100,
                  title: const Text(
                    "eCommerce",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 8.0,
                      ),
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(30),
                        child: TextField(
                          controller: _searchController,
                          autofocus: false,
                          onChanged: searchProducts,
                          decoration: InputDecoration(
                            hintText: "Search Products…",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: isSearching
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: clearSearch,
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Image.asset(
                    "assets/banner.jpg",
                    width: double.infinity,
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
                          elevation: 4,
                          shadowColor: Colors.black12,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'product-${product.title}-$index',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      product.images.isNotEmpty
                                          ? product.images.first
                                          : '',
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
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
                                SizedBox(height: 8),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.orange,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              product.reviews,
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '₹${product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: colorPallete.color1,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Delivery by ${product.deliveryTime}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
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
                    }, childCount: filteredProducts.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.7,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
