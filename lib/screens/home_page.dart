import 'dart:typed_data';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/screens/product_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  Product({
    required this.title,
    required this.description,
    required this.price,
    required this.deliveryTime,
    required this.reviews,
    required this.images,
    required this.extraFields,
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
      );
    }).toList();

    setState(() {
      products = loadedProducts;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.pushNamed(context, '/home');
          break;
        case 1:
          Navigator.pushNamed(context, '/category');
          break;
        case 2:
          Navigator.pushNamed(context, '/account');
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
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
                  Text(
                    'Products',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
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
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'category',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_sharp),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
