import 'package:buy_app/screens/orders/product_details.dart';
import 'package:buy_app/screens/search/category_list.dart';
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
  Set<String> selectedSubcategories = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();

      final loadedProducts = <Product>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final product = Product.fromFirestore(data);

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
      debugPrint('Error loading products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  bool isProductInCategory(Product product, String categoryName) {
    final productCategory = product.category.toLowerCase();
    final filterCategory = categoryName.toLowerCase();

    // Exact or close category match
    if (productCategory == filterCategory) {
      return true;
    }

    // Exclude mobile products from electronics
    if (filterCategory == 'electronics' &&
        (productCategory.contains('mobile') || productCategory.contains('phone') || productCategory.contains('smartphone'))) {
      return false;
    }

    // Check subcategory keywords
    final subcategories = categorySubcategories[categoryName] ?? [];
    for (final subcategory in subcategories) {
      final keywords = List<String>.from(subcategory['keywords']);
      for (final keyword in keywords) {
        if (productCategory.contains(keyword.toLowerCase()) ||
            product.keywords.any((k) => k.toLowerCase().contains(keyword.toLowerCase()))) {
          return true;
        }
      }
    }

    return false;
  }

  void applyFilters() {
    setState(() {
      if (selectedSubcategories.isEmpty) {
        filteredProducts = products;
      } else {
        final subcategories = categorySubcategories[widget.categoryName] ?? [];
        filteredProducts = products.where((product) {
          final productCategory = product.category.toLowerCase();

          for (final subcategoryName in selectedSubcategories) {
            final subcategory = subcategories.firstWhere(
                  (sub) => sub['name'] == subcategoryName,
              orElse: () => {},
            );

            if (subcategory.isNotEmpty) {
              final keywords = List<String>.from(subcategory['keywords']);
              if (keywords.any((keyword) =>
              productCategory.contains(keyword.toLowerCase()) ||
                  product.keywords.any((k) => k.toLowerCase().contains(keyword.toLowerCase())))) {
                return true;
              }
            }
          }
          return false;
        }).toList();
      }
    });
  }

  void _showFilterBottomSheet() {
    final subcategories = categorySubcategories[widget.categoryName] ?? [];
    Set<String> tempSelectedSubcategories = Set.from(selectedSubcategories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter by Category',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      Divider(),

                      // Select All / Clear All
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelectedSubcategories = subcategories
                                    .map((sub) => sub['name'] as String)
                                    .toSet();
                              });
                            },
                            child: Text(
                              'Select All',
                              style: TextStyle(color: widget.categoryColor),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelectedSubcategories.clear();
                              });
                            },
                            child: Text(
                              'Clear All',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),

                      // Checkbox list
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: subcategories.length,
                          itemBuilder: (context, index) {
                            final subcategory = subcategories[index];
                            final isSelected = tempSelectedSubcategories.contains(subcategory['name']);

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: widget.categoryColor,
                              title: Row(
                                children: [
                                  Icon(
                                    subcategory['icon'],
                                    color: widget.categoryColor,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    subcategory['name'],
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              onChanged: (value) {
                                setModalState(() {
                                  if (value == true) {
                                    tempSelectedSubcategories.add(subcategory['name']);
                                  } else {
                                    tempSelectedSubcategories.remove(subcategory['name']);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),

                      // Apply button
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.categoryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedSubcategories = tempSelectedSubcategories;
                            });
                            applyFilters();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Apply Filters (${tempSelectedSubcategories.length} selected)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          if (subcategories.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.white),
                  onPressed: _showFilterBottomSheet,
                ),
                if (selectedSubcategories.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${selectedSubcategories.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
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
      ) : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active filters display
          if (selectedSubcategories.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12),
              color: widget.categoryColor.withAlpha(10),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 18, color: widget.categoryColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filters: ${selectedSubcategories.join(", ")}',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.categoryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedSubcategories.clear();
                      });
                      applyFilters();
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(color: widget.categoryColor),
                    ),
                  ),
                ],
              ),
            ),

          // Product count
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '${filteredProducts.length} products found',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Products grid
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    selectedSubcategories.isNotEmpty
                        ? 'No products match selected filters'
                        : 'No ${widget.categoryName.toLowerCase()} products available',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  if (selectedSubcategories.isNotEmpty) ...[
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubcategories.clear();
                        });
                        applyFilters();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.categoryColor,
                      ),
                      child: Text('Clear Filters', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            )
                : Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                          builder: (context) => ProductDetailPage(product: product),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  product.images.isNotEmpty ? product.images.first : '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    product.brand,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
