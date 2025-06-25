import 'dart:typed_data';
import 'package:buy_app/screens/product_detail_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/services/auth.dart';

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
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  AuthService _authService = AuthService();
  List<Product> products = [];

  get data => null;

  Future<List<Map<String, dynamic>>> readExcelFromHive() async {
    final box = Hive.box('filesBox');
    final Uint8List? bytes = box.get('excelFile');

    if (bytes == null) {
      print("No Excel file found in Hive.");
      return [];
    }

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]; // First sheet

    if (sheet == null) return [];

    final headers = sheet.rows.first
        .map((cell) => cell?.value?.toString() ?? "")
        .toList();
    final products = <Map<String, dynamic>>[];

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final product = <String, dynamic>{};

      for (var j = 0; j < headers.length; j++) {
        product[headers[j]] = row[j]?.value;
      }

      products.add(product);
    }

    return products;
  }

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is DateTime) return 0.0; // Don't treat dates as price

    final str = value.toString().replaceAll(RegExp(r'[^\d.]'), '');

    return double.tryParse(str) ?? 0.0;
  }

  Future<void> loadProducts() async {
    final excelData = await readExcelFromHive();
    print("Excel rows loaded: $excelData");

    setState(() {
      products = excelData.map((productMap) {
        // Extract known fields
        final title = productMap['Title']?.toString() ?? 'No Title';
        final description = productMap['Description']?.toString() ?? '';
        final price = _parsePrice(productMap['Price']);
        final deliveryTime = productMap['DeliveryTime']?.toString() ?? 'N/A';
        final reviews = productMap['Reviews']?.toString() ?? 'No Reviews';

        // Split images by comma if multiple provided
        final imageField = productMap['Images']?.toString() ?? '';
        final images = imageField.split(',').map((e) => e.trim()).toList();

        // Create extraFields by filtering out known ones
        final extraFields = Map<String, dynamic>.from(productMap)
          ..remove('Title')
          ..remove('Images')
          ..remove('Description')
          ..remove('Price')
          ..remove('DeliveryTime')
          ..remove('Reviews');

        return Product(
          title: title,
          description: description,
          price: price,
          deliveryTime: deliveryTime,
          reviews: reviews,
          images: images,
          extraFields: extraFields,
        );
      }).toList();
    });

    print("Products after parsing: $products");
  }

  Future<void> pickAndStoreExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.bytes != null) {
      final box = await Hive.openBox('filesBox');
      await box.put('excelFile', result.files.single.bytes);
      print("Excel file saved to Hive.");
      await loadProducts(); // Reload products after storing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel file uploaded and products loaded!')),
      );
    } else {
      print("File picking canceled or failed.");
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
        automaticallyImplyLeading: true,
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
              leading: Icon(Icons.upload),
              title: Text('Upload'),
              onTap: () async {
                Navigator.pop(context);
                await pickAndStoreExcel();
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
    );
  }
}
