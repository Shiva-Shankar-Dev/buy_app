import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/screens/orders/product_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/models/models.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;

  const CategoryPage({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  String? selectedSubcategory;
  bool isLoading = true;

  // Define subcategories for each main category
  Map<String, List<Map<String, dynamic>>> categorySubcategories = {
    'Electronics': [
      {
        'name': 'Television',
        'icon': Icons.tv,
        'keywords': ['tv', 'television', 'smart tv', 'led', 'oled'],
      },
      {
        'name': 'Laptop',
        'icon': Icons.laptop,
        'keywords': ['laptop', 'computer', 'pc', 'gaming laptop'],
      },
      {
        'name': 'Home Theatre',
        'icon': Icons.speaker,
        'keywords': ['speaker', 'home theatre', 'sound system', 'audio'],
      },
      {
        'name': 'Headphones',
        'icon': Icons.headphones,
        'keywords': ['headphones', 'earphones', 'earbuds', 'airpods'],
      },
      {
        'name': 'Camera',
        'icon': Icons.camera_alt,
        'keywords': ['camera', 'dslr', 'photography', 'video camera'],
      },
      {
        'name': 'Gaming',
        'icon': Icons.sports_esports,
        'keywords': ['gaming', 'console', 'playstation', 'xbox', 'nintendo'],
      },
      {
        'name': 'Smartwatch',
        'icon': Icons.watch,
        'keywords': ['watch', 'smartwatch', 'fitness tracker'],
      },
    ],
    'Mobile': [
      {
        'name': 'Smartphones',
        'icon': Icons.smartphone,
        'keywords': ['smartphone', 'android', 'iphone'],
      },
      {
        'name': 'Feature Phones',
        'icon': Icons.phone,
        'keywords': ['feature phone', 'basic phone', 'keypad phone'],
      },
      {
        'name': 'Accessories',
        'icon': Icons.phone_android,
        'keywords': ['case', 'cover', 'charger', 'screen guard'],
      },
    ],
    'Appliances': [
      {
        'name': 'Refrigerator',
        'icon': Icons.kitchen,
        'keywords': ['refrigerator', 'fridge', 'cooling'],
      },
      {
        'name': 'Washing Machine',
        'icon': Icons.local_laundry_service,
        'keywords': ['washing machine', 'laundry'],
      },
      {
        'name': 'Air Conditioner',
        'icon': Icons.ac_unit,
        'keywords': ['ac', 'air conditioner', 'cooling'],
      },
      {
        'name': 'Microwave',
        'icon': Icons.microwave,
        'keywords': ['microwave', 'oven'],
      },
      {
        'name': 'Kitchen',
        'icon': Icons.kitchen,
        'keywords': ['mixer', 'grinder', 'blender', 'kitchen appliance'],
      },
    ],
    'Fashion': [
      {
        'name': 'Mens Wear',
        'icon': Icons.man,
        'keywords': ['men', 'shirt', 'trouser', 'jeans', 'mens'],
      },
      {
        'name': 'Womens Wear',
        'icon': Icons.woman,
        'keywords': ['women', 'dress', 'saree', 'kurti', 'womens'],
      },
      {
        'name': 'Kids Wear',
        'icon': Icons.child_care,
        'keywords': ['kids', 'children', 'baby', 'infant'],
      },
      {
        'name': 'Footwear',
        'icon': Icons.directions_walk,
        'keywords': ['shoes', 'sandals', 'slippers', 'boots'],
      },
      {
        'name': 'Accessories',
        'icon': Icons.watch,
        'keywords': ['belt', 'wallet', 'bag', 'accessories'],
      },
    ],
    'Books': [
      {
        'name': 'Fiction',
        'icon': Icons.auto_stories,
        'keywords': ['fiction', 'novel', 'story'],
      },
      {
        'name': 'Non-Fiction',
        'icon': Icons.book,
        'keywords': ['non-fiction', 'biography', 'history'],
      },
      {
        'name': 'Educational',
        'icon': Icons.school,
        'keywords': ['textbook', 'educational', 'study', 'academic'],
      },
      {
        'name': 'Children',
        'icon': Icons.child_friendly,
        'keywords': ['children book', 'kids book', 'story book'],
      },
    ],
    'Sports': [
      {
        'name': 'Fitness',
        'icon': Icons.fitness_center,
        'keywords': ['gym', 'fitness', 'exercise', 'workout'],
      },
      {
        'name': 'Outdoor',
        'icon': Icons.directions_run,
        'keywords': ['outdoor', 'cycling', 'running', 'hiking'],
      },
      {
        'name': 'Indoor Games',
        'icon': Icons.sports_tennis,
        'keywords': ['indoor', 'table tennis', 'badminton'],
      },
      {
        'name': 'Team Sports',
        'icon': Icons.sports_football,
        'keywords': ['football', 'cricket', 'basketball'],
      },
    ],
    'Beauty': [
      {
        'name': 'Skincare',
        'icon': Icons.face,
        'keywords': ['skincare', 'face wash', 'moisturizer', 'serum'],
      },
      {
        'name': 'Makeup',
        'icon': Icons.brush,
        'keywords': ['makeup', 'lipstick', 'foundation', 'cosmetics'],
      },
      {
        'name': 'Hair Care',
        'icon': Icons.content_cut,
        'keywords': ['shampoo', 'conditioner', 'hair oil', 'hair care'],
      },
      {
        'name': 'Fragrances',
        'icon': Icons.local_florist,
        'keywords': ['perfume', 'fragrance', 'deodorant'],
      },
    ],
    'Groceries': [
      {
        'name': 'Fruits & Vegetables',
        'icon': Icons.eco,
        'keywords': ['fruits', 'vegetables', 'fresh', 'organic'],
      },
      {
        'name': 'Dairy',
        'icon': Icons.local_drink,
        'keywords': ['milk', 'cheese', 'butter', 'dairy'],
      },
      {
        'name': 'Packaged Food',
        'icon': Icons.inventory,
        'keywords': ['packaged', 'snacks', 'biscuits', 'chips'],
      },
      {
        'name': 'Beverages',
        'icon': Icons.local_cafe,
        'keywords': ['tea', 'coffee', 'juice', 'drinks'],
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      final loadedProducts = <Product>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final product = Product.fromFirestore(data);

        // Filter products that belong to this category
        if (isProductInCategory(product, widget.categoryName)) {
          loadedProducts.add(product);
        }
      }

      setState(() {
        products = loadedProducts;
        filteredProducts = loadedProducts;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  bool isProductInCategory(Product product, String categoryName) {
    final productCategory = product.category.toLowerCase();
    final filterCategory = categoryName.toLowerCase();

    // Direct match
    if (productCategory.contains(filterCategory) ||
        filterCategory.contains(productCategory)) {
      return true;
    }

    // Check subcategory keywords
    final subcategories = categorySubcategories[categoryName] ?? [];
    for (final subcategory in subcategories) {
      final keywords = List<String>.from(subcategory['keywords']);
      for (final keyword in keywords) {
        if (productCategory.contains(keyword.toLowerCase()) ||
            product.keywords.any(
              (k) => k.toLowerCase().contains(keyword.toLowerCase()),
            )) {
          return true;
        }
      }
    }

    return false;
  }

  void filterBySubcategory(String? subcategoryName) {
    setState(() {
      selectedSubcategory = subcategoryName;

      if (subcategoryName == null) {
        filteredProducts = products;
      } else {
        final subcategories = categorySubcategories[widget.categoryName] ?? [];
        final subcategory = subcategories.firstWhere(
          (sub) => sub['name'] == subcategoryName,
          orElse: () => {},
        );

        if (subcategory.isNotEmpty) {
          final keywords = List<String>.from(subcategory['keywords']);
          filteredProducts = products.where((product) {
            final productCategory = product.category.toLowerCase();
            return keywords.any(
              (keyword) =>
                  productCategory.contains(keyword.toLowerCase()) ||
                  product.keywords.any(
                    (k) => k.toLowerCase().contains(keyword.toLowerCase()),
                  ),
            );
          }).toList();
        }
      }
    });
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory) {
    final isSelected = selectedSubcategory == subcategory['name'];

    return Container(
      margin: EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () =>
            filterBySubcategory(isSelected ? null : subcategory['name']),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? widget.categoryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? widget.categoryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                subcategory['icon'],
                size: 18,
                color: isSelected ? Colors.white : widget.categoryColor,
              ),
              SizedBox(width: 6),
              Text(
                subcategory['name'],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = categorySubcategories[widget.categoryName] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.categoryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(widget.categoryIcon, color: Colors.white),
            SizedBox(width: 8),
            Text(
              widget.categoryName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: widget.categoryColor),
                  SizedBox(height: 16),
                  Text('Loading ${widget.categoryName} products...'),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subcategories section
                if (subcategories.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shop by Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // All categories option
                              Container(
                                margin: EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () => filterBySubcategory(null),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selectedSubcategory == null
                                          ? widget.categoryColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selectedSubcategory == null
                                            ? widget.categoryColor
                                            : Colors.grey.shade300,
                                        width: selectedSubcategory == null
                                            ? 2
                                            : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.grid_view,
                                          size: 18,
                                          color: selectedSubcategory == null
                                              ? Colors.white
                                              : widget.categoryColor,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'All',
                                          style: TextStyle(
                                            color: selectedSubcategory == null
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight:
                                                selectedSubcategory == null
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Subcategory options
                              ...subcategories
                                  .map((sub) => _buildSubcategoryCard(sub))
                                  .toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter info
                  if (selectedSubcategory != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Showing ${filteredProducts.length} products in "$selectedSubcategory"',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  SizedBox(height: 16),
                ],

                // Products section
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                selectedSubcategory != null
                                    ? 'No products found in "$selectedSubcategory"'
                                    : 'No ${widget.categoryName.toLowerCase()} products available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.65,
                                ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
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
                                  elevation: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Product image
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                            child: Image.network(
                                              product.images.isNotEmpty
                                                  ? product.images.first
                                                  : '',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
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

                                      // Product details
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                product.brand,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Spacer(),
                                              Text(
                                                '₹${product.price.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: widget.categoryColor,
                                                ),
                                              ),
                                            ],
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
                ),
              ],
            ),
    );
  }
}
