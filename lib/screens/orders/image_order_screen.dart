import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../services/cart_manager.dart';

class OrderItem {
  final String name;
  final String quantity;
  final String variantDetails;

  OrderItem({
    required this.name,
    required this.quantity,
    this.variantDetails = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
      variantDetails: json['variant']?.toString() ?? '',
    );
  }
}

class ImageOrderScreen extends StatefulWidget {
  const ImageOrderScreen({Key? key}) : super(key: key);

  @override
  State<ImageOrderScreen> createState() => _ImageOrderScreenState();
}

class _ImageOrderScreenState extends State<ImageOrderScreen> {
  final ImagePicker _picker = ImagePicker();
  List<OrderItem> _extractedItems = [];
  bool _isLoading = false;
  bool _isAddingToCart = false;
  // TODO: Replace with your actual Gemini API Key from Google AI Studio.
  // It's highly recommended to fetch this from remote config or environment variables in production.
  final String apiKey = "AIzaSyCuuglze8YbNbnHxC9i_gIj91ZuYmr-umI";

  Future<void> _processHandwrittenList(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _isLoading = true;
        _extractedItems.clear();
      });

      // Use readAsBytes() directly from the XFile which works on all platforms (Web, Android, iOS)
      final bytes = await image.readAsBytes();

      // Initialize the Gemini vision model. Using gemini-3.5-flash which supports multimodality.
      final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: apiKey);

      final prompt = TextPart('''
        Analyze this handwritten list of items.
        Extract the items, their quantities, and variant details (e.g., Color, RAM, Size) if mentioned.
        - If an item has a number next to it (e.g., "Oneplus 13r 1"), interpret the number as the quantity.
        - If variant information is mentioned (e.g., "Oneplus 13r 8GB 128GB Black 1"), extract it under "variant".
        Return ONLY a raw JSON array of objects with "name" (string), "quantity" (string), and "variant" (string) keys. If no variant is given, leave it empty.
        Example: [{"name": "Oneplus 13r", "variant": "8GB 128GB Black", "quantity": "1"}, {"name": "Milk", "variant": "", "quantity": "1 liter"}]
        Do not include markdown blocks like ```json.
      ''');

      final imagePart = DataPart('image/jpeg', bytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      if (response.text != null && response.text!.isNotEmpty) {
        // Clean up text in case the model returns markdown markup despite instructions
        String rawJson = response.text!.trim();
        if (rawJson.startsWith('```json')) {
          rawJson = rawJson.replaceFirst('```json', '').trim();
        }
        if (rawJson.endsWith('```')) {
          rawJson = rawJson.substring(0, rawJson.length - 3).trim();
        }

        final List<dynamic> jsonList = jsonDecode(rawJson);
        setState(() {
          _extractedItems = jsonList
              .map((j) => OrderItem.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to process image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addAllToCart() async {
    setState(() => _isAddingToCart = true);

    int addedCount = 0;
    int notFoundCount = 0;

    try {
      // Fetch all products once to allow for flexible case-insensitive matching
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();
      final allProducts = productsSnapshot.docs
          .map((doc) => Product.fromFirestore(doc.data()))
          .toList();

      for (final item in _extractedItems) {
        final searchName = item.name.toLowerCase().trim();
        Product? matchedProduct;

        // 1. Try finding an exact case-insensitive match
        try {
          matchedProduct = allProducts.firstWhere(
            (p) => p.name.toLowerCase().trim() == searchName,
          );
        } catch (_) {
          // 2. If no exact match, try finding a partial match
          try {
            matchedProduct = allProducts.firstWhere(
              (p) =>
                  p.name.toLowerCase().trim().contains(searchName) ||
                  searchName.contains(p.name.toLowerCase().trim()),
            );
          } catch (_) {
            matchedProduct = null;
          }
        }

        if (matchedProduct != null) {
          // Convert quantity string back to int, e.g. "2 kg" -> 2
          int quantity =
              int.tryParse(item.quantity.replaceAll(RegExp(r'[^0-9]'), '')) ??
              1;
          if (quantity <= 0) quantity = 1;

          String? matchedVariantId;
          Map<String, String>? matchedAttributes;

          if (matchedProduct.hasVariants) {
            ProductVariant? bestVariant;

            if (item.variantDetails.isNotEmpty) {
              final searchWords = item.variantDetails.toLowerCase().split(' ');
              int bestScore = 0;

              for (final variant in matchedProduct.variants) {
                int score = 0;
                final values = variant.attributes.values
                    .map((e) => e.toLowerCase())
                    .toList();
                for (final word in searchWords) {
                  if (values.any(
                    (val) => val.contains(word) || word.contains(val),
                  )) {
                    score++;
                  }
                }
                if (score > bestScore) {
                  bestScore = score;
                  bestVariant = variant;
                }
              }
            }

            // Fallback to first variant if no match found or no variant specified
            bestVariant ??= matchedProduct.variants.isNotEmpty
                ? matchedProduct.variants.first
                : null;

            if (bestVariant != null) {
              matchedVariantId = bestVariant.variantId;
              matchedAttributes = bestVariant.attributes;
            }
          }

          Cart.instance.add(
            matchedProduct,
            quantity: quantity,
            variantId: matchedVariantId,
            variantAttributes: matchedAttributes,
          );
          addedCount++;
        } else {
          notFoundCount++;
          debugPrint("Product not found for: ${item.name}");
        }
      }
    } catch (e) {
      debugPrint("Error fetching products for cart addition: $e");
    }

    if (mounted) {
      setState(() => _isAddingToCart = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $addedCount items to cart. ${notFoundCount > 0 ? "$notFoundCount not found." : ""}',
          ),
        ),
      );

      if (addedCount > 0) {
        Navigator.pop(context); // Go back home or optionally to cart
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Order List")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Camera"),
                onPressed: _isLoading
                    ? null
                    : () => _processHandwrittenList(ImageSource.camera),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text("Gallery"),
                onPressed: _isLoading
                    ? null
                    : () => _processHandwrittenList(ImageSource.gallery),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Analyzing handwriting with Gemini AI..."),
                ],
              ),
            ),
          Expanded(
            child: _extractedItems.isEmpty && !_isLoading
                ? const Center(
                    child: Text(
                      "No items extracted yet.\nWrite the exact item name, variant (e.g. 50 inch, 8GB Black), and quantity clearly.",
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _extractedItems.length,
                    itemBuilder: (context, index) {
                      final item = _extractedItems[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(item.name),
                        subtitle: item.variantDetails.isNotEmpty
                            ? Text(
                                item.variantDetails,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : null,
                        trailing: Text(
                          item.quantity,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_extractedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isAddingToCart ? null : _addAllToCart,
                  child: _isAddingToCart
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Add All to Cart",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
