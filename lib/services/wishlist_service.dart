import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buy_app/models/models.dart';
import 'package:flutter/material.dart';

class WishlistService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'user_wishlists';

  // Add product variant to wishlist (variant required)
  static Future<bool> addToWishlist(
    Product product, {
    String? variantId,
    Map<String, String>? variantAttributes,
  }) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      // Check if product name exists
      if (product.name.isEmpty) {
        debugPrint('❌ Product name is empty');
        return false;
      }

      // Generate document ID from name and variant (sanitized)
      final baseName = product.name
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();

      String finalVariantId;
      String productId;

      if (product.hasVariants) {
        // For products with variants, require variant ID
        if (variantId == null || variantId.isEmpty) {
          debugPrint('❌ Variant selection required for products with variants');
          return false;
        }
        finalVariantId = variantId;
        productId = '${baseName}_${variantId}';
      } else {
        // For products without variants, use 'default' as variant ID
        finalVariantId = variantId ?? 'default';
        productId = '${baseName}_${finalVariantId}';
      }

      // Create wishlist document reference
      final docRef = _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .doc(productId);

      // Check if product variant already exists
      final doc = await docRef.get();
      if (!doc.exists) {
        // Find the specific variant if product has variants
        ProductVariant? selectedVariant;
        if (product.hasVariants && finalVariantId != 'default') {
          try {
            debugPrint(
              '🔍 Looking for variant: $finalVariantId among ${product.variants.length} variants',
            );
            for (final variant in product.variants) {
              debugPrint('   - Checking variant: ${variant.variantId}');
              if (variant.variantId == finalVariantId) {
                selectedVariant = variant;
                debugPrint('✅ Found matching variant: ${variant.variantId}');
                break;
              }
            }
            if (selectedVariant == null) {
              debugPrint(
                '❌ Variant $finalVariantId not found among available variants',
              );
            }
          } catch (e) {
            debugPrint('Error finding variant: $e, using base product data');
          }
        }

        // Get variant-specific data safely
        double effectivePrice = product.price;
        int effectiveStock = product.stockQuantity;
        List<String> effectiveImages = [];

        if (product.hasVariants && selectedVariant != null) {
          // For products with variants, use variant-specific data
          try {
            effectivePrice = (selectedVariant.price ?? 0.0) > 0
                ? (selectedVariant.price ?? product.price)
                : product.price;
            effectiveStock = selectedVariant.stockQuantity;

            // Check variant images with detailed logging
            final variantImages = selectedVariant.images;
            debugPrint(
              '📸 Variant images: $variantImages (length: ${variantImages?.length ?? 0})',
            );

            if (variantImages != null && variantImages.isNotEmpty) {
              effectiveImages = variantImages;
              debugPrint(
                '✅ Using variant images: ${effectiveImages.length} images',
              );
            } else {
              // Fallback to product images if variant has no images
              effectiveImages = product.images;
              debugPrint(
                '⚠️ Variant has no images, using product images: ${effectiveImages.length} images',
              );
            }
          } catch (e) {
            debugPrint('Error accessing variant properties: $e');
            effectiveImages = product.images; // Fallback to product images
          }
        } else if (!product.hasVariants) {
          // For products without variants, use base product images
          effectiveImages = product.images;
          debugPrint(
            '📱 Using product images (no variants): ${effectiveImages.length} images',
          );
        } else {
          // For products with variants but no selectedVariant found, use product images as fallback
          effectiveImages = product.images;
          debugPrint(
            '🔄 Using product images as fallback: ${effectiveImages.length} images',
          );
        }

        // Add only essential product info and specific variant details
        final wishlistItem = {
          // Basic product info (without all variants)
          'pid': product.pid,
          'name': product.name,
          'description': product.description,
          'brand': product.brand,
          'category': product.category,
          'sellerId': product.sellerId,
          'deliveryTime': product.deliveryTime,

          // Use variant-specific data if available, otherwise base product data
          'price': effectivePrice,
          'stockQuantity': effectiveStock,
          'images': effectiveImages,

          // Variant-specific information
          'selectedVariantId': finalVariantId,
          'selectedAttributes': variantAttributes != null
              ? LinkedHashMap<String, String>.from(variantAttributes)
              : <String, String>{},

          // Metadata
          'addedAt': Timestamp.now(),
          'userId': currentUser.uid,
          'hasVariants': product.hasVariants,
        };

        await docRef.set(wishlistItem);
        final variantText =
            variantAttributes != null && variantAttributes.isNotEmpty
            ? ' (${variantAttributes.values.join(', ')})'
            : finalVariantId != 'default'
            ? ' (Variant: $finalVariantId)'
            : '';
        final imageCount = effectiveImages.length;
        debugPrint(
          '✅ Added to wishlist: ${product.name}$variantText - Stored $imageCount variant image(s)',
        );
        return true;
      }

      final variantText =
          variantAttributes != null && variantAttributes.isNotEmpty
          ? ' (${variantAttributes.values.join(', ')})'
          : finalVariantId != 'default'
          ? ' (Variant: $finalVariantId)'
          : '';
      debugPrint('⚠️ Already in wishlist: ${product.name}$variantText');
      return false;
    } catch (e) {
      debugPrint('❌ Error adding to wishlist: $e');
      return false;
    }
  }

  // Remove product variant from wishlist (variant required)
  static Future<bool> removeFromWishlist(
    Product product, {
    String? variantId,
  }) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      // Generate document ID from name and variant (sanitized)
      final baseName = product.name
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();

      String finalVariantId;
      String productId;

      if (product.hasVariants) {
        // For products with variants, require variant ID
        if (variantId == null || variantId.isEmpty) {
          debugPrint('❌ Variant ID required for products with variants');
          return false;
        }
        finalVariantId = variantId;
        productId = '${baseName}_${variantId}';
      } else {
        // For products without variants, use 'default' as variant ID
        finalVariantId = variantId ?? 'default';
        productId = '${baseName}_${finalVariantId}';
      }

      // Remove from Firestore
      final docRef = _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .doc(productId);

      await docRef.delete();
      final variantText = finalVariantId != 'default'
          ? ' (Variant: $finalVariantId)'
          : '';
      debugPrint('✅ Removed from wishlist: ${product.name}$variantText');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing from wishlist: $e');
      return false;
    }
  }

  // Get all wishlist products
  static Future<List<Product>> getWishlistProducts() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return [];
      }

      // Fetch wishlist items from Firestore
      final querySnapshot = await _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .orderBy('addedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return _createProductFromWishlistData(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting wishlist: $e');
      return [];
    }
  }

  // Get all wishlist items with variant information
  static Future<List<WishlistItem>> getWishlistItemsWithVariants() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return [];
      }

      // Fetch wishlist items from Firestore
      final querySnapshot = await _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .orderBy('addedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return WishlistItem(
          product: _createProductFromWishlistData(data),
          selectedVariantId: data['selectedVariantId']?.toString(),
          selectedAttributes: _safeToStringMap(data['selectedAttributes']),
          addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting wishlist items with variants: $e');
      return [];
    }
  }

  // Check if product variant is in wishlist (variant required)
  static Future<bool> isInWishlist(Product product, {String? variantId}) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      // Generate document ID from name and variant (sanitized)
      final baseName = product.name
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();

      String finalVariantId;
      String productId;

      if (product.hasVariants) {
        // For products with variants, require variant ID
        if (variantId == null || variantId.isEmpty) {
          return false; // Simply return false, no debug needed
        }
        finalVariantId = variantId;
        productId = '${baseName}_${variantId}';
      } else {
        // For products without variants, use 'default' as variant ID
        finalVariantId = variantId ?? 'default';
        productId = '${baseName}_${finalVariantId}';
      }

      // Check if document exists
      final docRef = _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .doc(productId);

      final doc = await docRef.get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking wishlist: $e');
      return false;
    }
  }

  // Clear entire wishlist
  static Future<bool> clearWishlist() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      // Get all documents and delete them in batch
      final batch = _firestore.batch();
      final collectionRef = _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items');

      final querySnapshot = await collectionRef.get();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Wishlist cleared');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing wishlist: $e');
      return false;
    }
  }

  // Get wishlist count
  static Future<int> getWishlistCount() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return 0;
      }

      // Count documents in wishlist collection
      final querySnapshot = await _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error getting wishlist count: $e');
      return 0;
    }
  }

  // Helper method to create Product from wishlist variant data
  static Product _createProductFromWishlistData(Map<String, dynamic> data) {
    try {
      // Create a descriptive name with variant attributes if available
      String displayName = data['name']?.toString() ?? '';

      // Check if we have variant attributes to create a more descriptive name
      final selectedAttributes = data['selectedAttributes'];
      if (selectedAttributes != null && selectedAttributes is Map) {
        final attributesList = _getOrderedAttributesList(selectedAttributes);

        if (attributesList.isNotEmpty) {
          displayName = '$displayName (${attributesList.join(', ')})';
        }
      }

      // Create a simplified product with variant-specific data
      return Product(
        pid: data['pid']?.toString() ?? '',
        name: displayName,
        description: data['description']?.toString() ?? '',
        brand: data['brand']?.toString() ?? '',
        category: data['category']?.toString() ?? '',
        price: _safeToDouble(data['price']),
        stockQuantity: _safeToInt(data['stockQuantity']),
        images: _safeToStringList(data['images']),
        sellerId: data['sellerId']?.toString() ?? '',
        deliveryTime: data['deliveryTime']?.toString() ?? '',
        keywords: _safeToStringList(data['keywords']),
        hasVariants: data['hasVariants'] == true,
        variants: <ProductVariant>[], // Explicitly typed empty list
        availableAttributes: <String>[], // Explicitly typed empty list
      );
    } catch (e, stackTrace) {
      debugPrint('Error creating product from wishlist data: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Data: $data');

      // Try with minimal required fields only
      try {
        return Product(
          pid:
              data['pid']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: data['name']?.toString() ?? 'Unknown Product',
          description: data['description']?.toString() ?? '',
          brand: data['brand']?.toString() ?? '',
          category: data['category']?.toString() ?? '',
          price: _safeToDouble(data['price']),
          stockQuantity: _safeToInt(data['stockQuantity']),
          images: _safeToStringList(data['images']),
          sellerId: data['sellerId']?.toString() ?? '',
          deliveryTime: data['deliveryTime']?.toString() ?? '',
          keywords: _safeToStringList(data['keywords']),
          hasVariants: false, // Force to false for safety
          variants: <ProductVariant>[],
          availableAttributes: <String>[],
        );
      } catch (e2) {
        debugPrint('Critical error creating minimal product: $e2');
        // Return a completely minimal product as last resort
        return Product(
          pid: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Error Loading Product',
          description: 'There was an error loading this product from wishlist',
          brand: '',
          category: '',
          price: 0.0,
          stockQuantity: 0,
          images: <String>[],
          sellerId: '',
          deliveryTime: '',
          keywords: <String>[],
          hasVariants: false,
          variants: <ProductVariant>[],
          availableAttributes: <String>[],
        );
      }
    }
  }

  // Helper method to get ordered attributes list
  static List<String> _getOrderedAttributesList(
    Map<dynamic, dynamic> attributes,
  ) {
    // Define preferred attribute order (most common attributes first)
    final preferredOrder = [
      'size',
      'color',
      'colour',
      'storage',
      'memory',
      'ram',
      'capacity',
      'material',
      'style',
      'pattern',
      'finish',
      'variant',
      'type',
      'model',
    ];

    final attributeEntries = <MapEntry<String, String>>[];

    // Convert to string entries
    attributes.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        attributeEntries.add(
          MapEntry(key.toString().toLowerCase(), value.toString()),
        );
      }
    });

    // Sort by preferred order, then alphabetically
    attributeEntries.sort((a, b) {
      final aIndex = preferredOrder.indexOf(a.key);
      final bIndex = preferredOrder.indexOf(b.key);

      // If both are in preferred order, sort by their preferred position
      if (aIndex != -1 && bIndex != -1) {
        return aIndex.compareTo(bIndex);
      }
      // If only 'a' is in preferred order, it comes first
      if (aIndex != -1) return -1;
      // If only 'b' is in preferred order, it comes first
      if (bIndex != -1) return 1;
      // If neither is in preferred order, sort alphabetically by key
      return a.key.compareTo(b.key);
    });

    // Return ordered list of values
    return attributeEntries.map((entry) => entry.value).toList();
  }

  // Helper methods for safe type conversion
  static double _safeToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _safeToInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static List<String> _safeToStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').toList();
    }
    return [];
  }

  static Map<String, String>? _safeToStringMap(dynamic value) {
    if (value is Map) {
      try {
        return Map<String, String>.from(
          value.map(
            (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
          ),
        );
      } catch (e) {
        debugPrint('Error converting map: $e');
        return null;
      }
    }
    return null;
  }
}

// Wishlist item model to store product with variant information
class WishlistItem {
  final Product product;
  final String? selectedVariantId;
  final Map<String, String>? selectedAttributes;
  final DateTime addedAt;

  WishlistItem({
    required this.product,
    this.selectedVariantId,
    this.selectedAttributes,
    required this.addedAt,
  });

  // Get variant display text
  String get variantDisplayText {
    if (selectedAttributes != null && selectedAttributes!.isNotEmpty) {
      final orderedValues = WishlistService._getOrderedAttributesList(
        selectedAttributes!,
      );
      return orderedValues.join(' • ');
    }
    return '';
  }

  // Check if item has variant info
  bool get hasVariantInfo =>
      selectedVariantId != null && selectedVariantId!.isNotEmpty;
}
