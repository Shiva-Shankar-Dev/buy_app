// dart
import 'package:buy_app/models/models.dart';
import 'package:buy_app/screens/orders/product_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchResults extends StatefulWidget {
  final String query;
  const SearchResults({super.key, required this.query});

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  late final lowerQuery = widget.query.toLowerCase();

  // Helper method for fuzzy matching
  bool _fuzzyMatch(String text, String searchTerm) {
    if (text.isEmpty || searchTerm.isEmpty) return false;

    // Split search term into words for better matching
    final searchWords = searchTerm
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    // Check if all search words are found in the text
    return searchWords.every((word) => text.contains(word)) ||
        // Or check if the text contains the search term with some flexibility
        text.replaceAll(' ', '').contains(searchTerm.replaceAll(' ', '')) ||
        // Or check individual characters for partial matches
        _partialMatch(text, searchTerm);
  }

  bool _partialMatch(String text, String searchTerm) {
    if (searchTerm.length < 3) return false; // Avoid too fuzzy matches

    int matchCount = 0;
    for (int i = 0; i < searchTerm.length - 1; i++) {
      final substring = searchTerm.substring(i, i + 2);
      if (text.contains(substring)) {
        matchCount++;
      }
    }

    // Return true if at least half of the 2-char substrings match
    return matchCount >= (searchTerm.length - 1) * 0.5;
  }

  Stream<QuerySnapshot> _buildQuery() {
    debugPrint('🔥 Building query for: ${widget.query}');

    // Use broader search - get all products and filter in memory
    // This is more reliable than relying on keywords field
    return FirebaseFirestore.instance
        .collection('products')
        .limit(100) // Get more products for better filtering
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _debugDatabaseContents();
  }

  // Debug method to check what's in the database
  void _debugDatabaseContents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .limit(5)
          .get();

      debugPrint(
        '🔥 DEBUG: Database contains ${snapshot.docs.length} products',
      );
      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint(
          '🔥 DEBUG: Product: ${data['name']} | Keywords: ${data['keywords']}',
        );
      }
    } catch (e) {
      debugPrint('🔥 DEBUG: Error checking database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search: ${widget.query}'),
        backgroundColor: const Color(0xFF6200EA),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('🔥 Search Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Searching...'),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final allDocs = snapshot.data!.docs;
          debugPrint('🔥 Total docs found: ${allDocs.length}');

          // Debug: Print first few documents to see structure
          if (allDocs.isNotEmpty) {
            final sampleDoc = allDocs.first.data() as Map<String, dynamic>;
            debugPrint('🔥 Sample doc keys: ${sampleDoc.keys.toList()}');
            debugPrint('🔥 Sample doc name: ${sampleDoc['name']}');
            debugPrint('🔥 Sample doc keywords: ${sampleDoc['keywords']}');
          }

          // Filter results in-memory for broader search
          final filteredDocs = allDocs.where((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final brand = (data['brand'] ?? '').toString().toLowerCase();
              final category = (data['category'] ?? '')
                  .toString()
                  .toLowerCase();
              final description = (data['description'] ?? '')
                  .toString()
                  .toLowerCase();

              // Handle keywords more safely
              final keywordsData = data['keywords'];
              List<String> keywords = [];
              if (keywordsData is List) {
                keywords = keywordsData
                    .map((k) => k.toString().toLowerCase())
                    .toList();
              }

              final searchTerm = lowerQuery;

              debugPrint('🔥 Checking product: $name');
              debugPrint('🔥 Against search term: $searchTerm');

              // More flexible matching
              final matches =
                  name.contains(searchTerm) ||
                  brand.contains(searchTerm) ||
                  category.contains(searchTerm) ||
                  description.contains(searchTerm) ||
                  keywords.any((keyword) => keyword.contains(searchTerm)) ||
                  // Additional fuzzy matching
                  _fuzzyMatch(name, searchTerm) ||
                  _fuzzyMatch(brand, searchTerm);

              if (matches) {
                debugPrint('🔥 MATCH FOUND: $name');
              }

              return matches;
            } catch (e) {
              debugPrint('🔥 Error filtering doc: $e');
              return false;
            }
          }).toList();

          debugPrint('🔥 Filtered docs: ${filteredDocs.length}');

          if (filteredDocs.isEmpty) {
            return _buildNoResultsView();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              return ProductCard(doc: filteredDocs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No products found for "${widget.query}"',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try searching with different keywords',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const ProductCard({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      debugPrint('🔥 ProductCard data: ${data.keys.toList()}');

      final name = data['name'] ?? 'No name';
      final price = data['price'];
      final priceText = price != null ? '₹${price.toString()}' : 'N/A';
      final brand = data['brand'] ?? '';
      final category = data['category'] ?? '';
      final stockQuantity = data['stockQuantity'] ?? 0;

      final imagesList = data['images'] as List<dynamic>?;
      final imageUrl = (imagesList != null && imagesList.isNotEmpty)
          ? imagesList[0] as String?
          : null;

      debugPrint(
        '🔥 ProductCard built for: $name, Price: $priceText, Images: ${imagesList?.length}',
      );

      // Try to create Product object with error handling
      Product? product;
      try {
        product = Product.fromFirestore(data);
      } catch (e) {
        debugPrint('🔥 Error creating Product: $e');
        // Create minimal product if fromFirestore fails
        product = Product(
          name: name,
          brand: brand,

          description: data['description'] ?? '',
          category: category,
          price: (price ?? 0).toDouble(),
          deliveryTime: data['deliveryTime'] ?? 'N/A',
          pid: data['pid'] ?? doc.id,
          keywords: (data['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
          stockQuantity: stockQuantity,
          sellerId: data['sellerId'] ?? '',
          hasVariants: data['hasVariants'] ?? false,
          variants: [],
          availableAttributes: [],
        );
      }

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (product != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(product: product!),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('🔥 Image error for $imageUrl: $error');
                            return Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 32,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Image not available',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 32,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No image',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // Product Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),

                      // Brand
                      if (brand.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          brand,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const Spacer(),

                      // Price and Stock
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              priceText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (stockQuantity > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Text(
                                'In Stock',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Text(
                                'Out of Stock',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
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
      );
    } catch (e) {
      debugPrint('🔥 Error building ProductCard: $e');
      return Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              const Text('Error loading product'),
              Text(
                e.toString(),
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}
