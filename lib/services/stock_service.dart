import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update stock quantity when order is placed
  /// If variantId is provided, updates variant-specific stock
  static Future<bool> decrementStock(
    String productId,
    int quantity, {
    String? variantId,
  }) async {
    try {
      // Validate inputs
      if (productId.isEmpty) {
        debugPrint('❌ Error updating stock: productId is empty');
        return false;
      }

      if (quantity <= 0) {
        debugPrint('❌ Error updating stock: quantity must be greater than 0');
        return false;
      }

      // First, find the product document by 'pid' field (outside transaction)
      final querySnapshot = await _firestore
          .collection('products')
          .where('pid', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ Product not found with PID: $productId');
        return false;
      }

      final productRef = querySnapshot.docs.first.reference;

      // Now perform the transaction to update stock
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);

        if (!snapshot.exists) {
          throw Exception('Product document not found: $productId');
        }

        final data = snapshot.data();
        if (data == null) {
          throw Exception('Product data is null for PID: $productId');
        }

        // Handle variant-specific stock or base stock
        if (variantId != null) {
          // Update variant stock
          final variants = List<dynamic>.from(data['variants'] ?? []);
          bool variantFound = false;

          for (int i = 0; i < variants.length; i++) {
            final variant = Map<String, dynamic>.from(variants[i]);
            if (variant['variantId'] == variantId) {
              final currentVariantStock =
                  (variant['stockQuantity'] as num?)?.toInt() ?? 0;

              if (currentVariantStock < quantity) {
                throw Exception(
                  'Insufficient variant stock. Available: $currentVariantStock, Requested: $quantity',
                );
              }

              variant['stockQuantity'] = currentVariantStock - quantity;
              variants[i] = variant;
              variantFound = true;
              debugPrint(
                '✅ Updated variant $variantId stock: $currentVariantStock -> ${currentVariantStock - quantity}',
              );
              break;
            }
          }

          if (!variantFound) {
            throw Exception(
              'Variant $variantId not found in product $productId',
            );
          }

          // Update the variants array
          transaction.update(productRef, {
            'variants': variants,
            'lastStockUpdate': FieldValue.serverTimestamp(),
          });
        } else {
          // Update base product stock
          int currentStock = 0;
          if (data['stockQuantity'] is int) {
            currentStock = data['stockQuantity'] as int;
          } else if (data['stockQuantity'] is double) {
            currentStock = (data['stockQuantity'] as double).toInt();
          } else if (data['stockQuantity'] is String) {
            currentStock = int.tryParse(data['stockQuantity'] as String) ?? 0;
          }

          debugPrint(
            '📊 Stock Update - Product PID: $productId, Current: $currentStock, To Decrement: $quantity',
          );

          final newStock = currentStock - quantity;

          if (newStock < 0) {
            throw Exception(
              'Insufficient stock. Current: $currentStock, Requested: $quantity',
            );
          }

          transaction.update(productRef, {
            'stockQuantity': newStock,
            'lastStockUpdate': FieldValue.serverTimestamp(),
          });

          debugPrint('📊 New Stock: $newStock');
        }
      });

      debugPrint(
        '✅ Stock decremented for product: $productId (Qty: $quantity)',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error updating stock for $productId: $e');
      return false;
    }
  }

  /// Check if stock is available before ordering
  /// If variantId is provided, checks variant-specific stock
  static Future<bool> checkStockAvailability(
    String productId,
    int quantity, {
    String? variantId,
  }) async {
    try {
      // Validate inputs
      if (productId.isEmpty) {
        debugPrint('❌ Error checking stock: productId is empty');
        return false;
      }

      if (quantity <= 0) {
        debugPrint('❌ Error checking stock: quantity must be greater than 0');
        return false;
      }

      // Query by 'pid' field instead of using it as document ID
      final querySnapshot = await _firestore
          .collection('products')
          .where('pid', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ Product not found: $productId');
        return false;
      }

      final data = querySnapshot.docs.first.data();

      // Properly cast stockQuantity to int
      int currentStock = 0;
      if (data['stockQuantity'] is int) {
        currentStock = data['stockQuantity'] as int;
      } else if (data['stockQuantity'] is double) {
        currentStock = (data['stockQuantity'] as double).toInt();
      } else if (data['stockQuantity'] is String) {
        currentStock = int.tryParse(data['stockQuantity'] as String) ?? 0;
      }

      final isAvailable = currentStock >= quantity;
      debugPrint(
        'Stock check for $productId: Current=$currentStock, Required=$quantity, Available=$isAvailable',
      );
      return isAvailable;
    } catch (e) {
      debugPrint('❌ Error checking stock for $productId: $e');
      return false;
    }
  }

  /// Restore stock if order is cancelled
  /// If variantId is provided, restores variant-specific stock
  static Future<bool> restoreStock(
    String productId,
    int quantity, {
    String? variantId,
  }) async {
    try {
      // Validate inputs
      if (productId.isEmpty) {
        debugPrint('❌ Error restoring stock: productId is empty');
        return false;
      }

      if (quantity <= 0) {
        debugPrint('❌ Error restoring stock: quantity must be greater than 0');
        return false;
      }

      // Query by 'pid' field to find the product document
      final querySnapshot = await _firestore
          .collection('products')
          .where('pid', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('❌ Product not found for restore: $productId');
        return false;
      }

      final productRef = querySnapshot.docs.first.reference;

      if (variantId != null) {
        // Restore variant stock
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(productRef);
          final data = snapshot.data();

          if (data != null) {
            final variants = List<dynamic>.from(data['variants'] ?? []);
            bool variantFound = false;

            for (int i = 0; i < variants.length; i++) {
              final variant = Map<String, dynamic>.from(variants[i]);
              if (variant['variantId'] == variantId) {
                final currentVariantStock =
                    (variant['stockQuantity'] as num?)?.toInt() ?? 0;
                variant['stockQuantity'] = currentVariantStock + quantity;
                variants[i] = variant;
                variantFound = true;
                debugPrint(
                  '✅ Restored variant $variantId stock: $currentVariantStock -> ${currentVariantStock + quantity}',
                );
                break;
              }
            }

            if (variantFound) {
              transaction.update(productRef, {
                'variants': variants,
                'lastStockUpdate': FieldValue.serverTimestamp(),
              });
            }
          }
        });
      } else {
        // Restore base product stock
        await productRef.update({
          'stockQuantity': FieldValue.increment(quantity),
          'lastStockUpdate': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('✅ Stock restored for product: $productId (Qty: $quantity)');
      return true;
    } catch (e) {
      debugPrint('❌ Error restoring stock for $productId: $e');
      return false;
    }
  }

  /// Get remaining stock for a specific product variant
  /// Returns current available stock accounting for all decrements
  static Future<Map<String, dynamic>> getStockStatus(
    String productId, {
    String? variantId,
  }) async {
    try {
      if (productId.isEmpty) {
        return {'error': 'Product ID is empty'};
      }

      // Query by 'pid' field
      final querySnapshot = await _firestore
          .collection('products')
          .where('pid', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'error': 'Product not found'};
      }

      final productData = querySnapshot.docs.first.data();
      int remainingStock = 0;
      String productName = productData['name'] as String? ?? 'Unknown Product';

      if (variantId != null) {
        // Get variant-specific stock
        final variants = List<dynamic>.from(productData['variants'] ?? []);
        for (final variant in variants) {
          final variantMap = variant as Map<String, dynamic>;
          if (variantMap['variantId'] == variantId) {
            remainingStock =
                (variantMap['stockQuantity'] as num?)?.toInt() ?? 0;
            break;
          }
        }
      } else {
        // Get base product stock
        int baseStock = 0;
        if (productData['stockQuantity'] is int) {
          baseStock = productData['stockQuantity'] as int;
        } else if (productData['stockQuantity'] is double) {
          baseStock = (productData['stockQuantity'] as double).toInt();
        } else if (productData['stockQuantity'] is String) {
          baseStock =
              int.tryParse(productData['stockQuantity'] as String) ?? 0;
        }
        remainingStock = baseStock;
      }

      return {
        'productId': productId,
        'productName': productName,
        'variantId': variantId,
        'remainingStock': remainingStock,
        'status': remainingStock > 0 ? 'in-stock' : 'out-of-stock',
        'lastUpdate': productData['lastStockUpdate'],
        'success': true,
      };
    } catch (e) {
      debugPrint('❌ Error getting stock status: $e');
      return {'error': 'Could not fetch stock: $e', 'success': false};
    }
  }

  /// Get stock levels for multiple products
  /// Useful for seller dashboard
  static Future<List<Map<String, dynamic>>> getMultipleProductsStock(
    List<String> productIds,
  ) async {
    try {
      final results = <Map<String, dynamic>>[];

      for (final productId in productIds) {
        final status = await getStockStatus(productId);
        results.add(status);
      }

      return results;
    } catch (e) {
      debugPrint('❌ Error getting multiple products stock: $e');
      return [];
    }
  }
}

