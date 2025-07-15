import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/screens/product_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/services/auth.dart';
import '../debug_users.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class Product {
  final String title, description, deliveryTime, reviews;
  final double price;
  final List<String> images;
  final Map<String, dynamic> extraFields; // ← dynamic extras
  final String? sellerId; // ← Add seller ID field

  Product({
    required this.title,
    required this.description,
    required this.price,
    required this.deliveryTime,
    required this.reviews,
    required this.images,
    required this.extraFields,
    this.sellerId, // ← Add seller ID parameter
  });

  num? get length => null;
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  AuthService _authService = AuthService();
  List<Product> products = [];
  int _selectedIndex = 0;
  get data => null;

  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      final products = snapshot.docs.map((doc) => doc.data()).toList();
      return products;
    } catch (e) {
      print("🔥 Error fetching products: $e");
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

    final loadedProducts = docs.map((doc) {
      return Product(
        title: doc['title'] ?? 'Untitled',
        description: doc['description'] ?? '',
        price: (doc['price'] ?? 0).toDouble(),
        deliveryTime: doc['Delivery Time'] ?? 'N/A',
        reviews: doc['ratings'] ?? 'No ratings',
        images: List<String>.from(doc['images'] ?? []),
        extraFields: Map<String, dynamic>.from(doc['extraFields'] ?? {}),
        sellerId: doc['sellerId'], // ← Add seller ID from Firestore
      );
    }).toList();

    setState(() {
      products = loadedProducts;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Home Page",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'PlayfairDisplay',
          ),
        ),
        automaticallyImplyLeading: true,
        backgroundColor: colorPallete.color1,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined),
            tooltip: 'Your Cart',
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
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
              leading: Icon(Icons.bug_report),
              title: Text('Debug Users'),
              onTap: () async {
                Navigator.pop(context);
                await DebugUsers.listAllUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Check console for debug output')),
                );
              },
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: products.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'There are no products available to display!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return InkWell(
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
                            margin: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            shadowColor: Colors.transparent,
                            color: Color(0xFFFFFFFF).withAlpha(84),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 20,
                                top: 20,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 10),
                                  Image.network(
                                    product.images.first,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.image),
                                  ),
                                  SizedBox(width: 15),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'PlayfairDisplay',
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.orange,
                                            size: 12,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            product.reviews,
                                            style: TextStyle(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '\₹${product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Delivery Time | ${product.deliveryTime}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
