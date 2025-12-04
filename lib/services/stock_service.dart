import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update stock quantity when order is placed
  static Future<bool> decrementStock(String productId, int quantity) async {
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

        // Properly cast stockQuantity to int
        int currentStock = 0;
        if (data['stockQuantity'] is int) {
          currentStock = data['stockQuantity'] as int;
        } else if (data['stockQuantity'] is double) {
          currentStock = (data['stockQuantity'] as double).toInt();
        } else if (data['stockQuantity'] is String) {
          currentStock = int.tryParse(data['stockQuantity'] as String) ?? 0;
        }

        debugPrint('📊 Stock Update - Product PID: $productId, Current: $currentStock, To Decrement: $quantity');

        final newStock = currentStock - quantity;

        if (newStock < 0) {
          throw Exception('Insufficient stock. Current: $currentStock, Requested: $quantity');
        }

        transaction.update(productRef, {
          'stockQuantity': newStock,
          'lastStockUpdate': FieldValue.serverTimestamp(),
        });

        debugPrint('📊 New Stock: $newStock');
      });

      debugPrint('✅ Stock decremented for product: $productId (Qty: $quantity)');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating stock for $productId: $e');
      return false;
    }
  }

  /// Check if stock is available before ordering
  static Future<bool> checkStockAvailability(String productId, int quantity) async {
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
      debugPrint('Stock check for $productId: Current=$currentStock, Required=$quantity, Available=$isAvailable');
      return isAvailable;
    } catch (e) {
      debugPrint('❌ Error checking stock for $productId: $e');
      return false;
    }
  }

  /// Restore stock if order is cancelled
  static Future<bool> restoreStock(String productId, int quantity) async {
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

      await productRef.update({
        'stockQuantity': FieldValue.increment(quantity),
        'lastStockUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Stock restored for product: $productId (Qty: $quantity)');
      return true;
    } catch (e) {
      debugPrint('❌ Error restoring stock for $productId: $e');
      return false;
    }
  }
}
