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
  Query _buildQuery() {
    debugPrint('🔥 Building query for: ${widget.query}');

    // First filter by keywords array (server-side)
    return FirebaseFirestore.instance
        .collection('products')
        .where('keywords', arrayContains: lowerQuery)
        .limit(20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search results')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: LinearProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return ProductCard(doc: docs[index]);
            },
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const ProductCard({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'No name';
    final price = data['price'] != null ? '\$${data['price']}' : 'N/A';
    final imagesList = data['images'] as List<dynamic>?;
    final imageUrl = (imagesList != null && imagesList.isNotEmpty)
        ? imagesList[0] as String?
        : null;
    debugPrint('🔥 ProductCard built for: $name');
    Product product = Product.fromFirestore(data);
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Expanded(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
