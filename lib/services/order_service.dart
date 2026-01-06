import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'stock_service.dart';

// Order Item for storage
class OrderItem {
  final String productTitle;
  final double productPrice;
  final int quantity;
  final String? productImage;
  final String sellerId;
  final String productId; // Add product ID for stock management
  final String? variantId; // Variant ID if product has variants
  final Map<String, String>?
  variantAttributes; // Variant attributes for display

  OrderItem({
    required this.productTitle,
    required this.productPrice,
    required this.quantity,
    this.productImage,
    required this.sellerId,
    required this.productId,
    this.variantId,
    this.variantAttributes,
  });

  // Convert from CartItem
  factory OrderItem.fromCartItem(CartItem cartItem) {
    // Use effective price and images which account for variants
    final effectiveImages = cartItem.effectiveImages;

    return OrderItem(
      productTitle: cartItem.product.name,
      productPrice: cartItem.effectivePrice,
      quantity: cartItem.quantity,
      productImage: effectiveImages.isNotEmpty ? effectiveImages[0] : null,
      sellerId: cartItem.product.sellerId,
      productId: cartItem.product.pid,
      variantId: cartItem.selectedVariantId,
      variantAttributes: cartItem.selectedAttributes,
    );
  }

  // Convert to/from Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productTitle': productTitle,
      'productPrice': productPrice,
      'quantity': quantity,
      'productImage': productImage,
      'sellerId': sellerId,
      'productId': productId,
      if (variantId != null) 'variantId': variantId,
      if (variantAttributes != null) 'variantAttributes': variantAttributes,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productTitle: map['productTitle'] ?? 'Unknown Product',
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      productImage: map['productImage'],
      sellerId: map['sellerId'] ?? '',
      productId: map['productId'] ?? '',
      variantId: map['variantId'],
      variantAttributes: map['variantAttributes'] != null
          ? Map<String, String>.from(map['variantAttributes'])
          : null,
    );
  }
}

// Order for storage and display
class Order {
  final String orderId;
  final String userId;
  final String customerName;
  final String customerEmail;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final DateTime orderDate;
  final Map<String, dynamic> shippingAddress;
  final List<String> sellerIds;
  final DateTime lastUpdated;

  Order({
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    this.status = 'Confirmed',
    required this.orderDate,
    required this.shippingAddress,
    required this.sellerIds,
    required this.lastUpdated,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
      'shippingAddress': shippingAddress,
      'sellerIds': sellerIds,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'createdAt': Timestamp.now(),
    };
  }

  // Create from Firestore
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      orderId: data['orderId'] ?? doc.id,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? 'Unknown Customer',
      customerEmail: data['customerEmail'] ?? '',
      items: (data['items'] as List? ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Unknown',
      status: data['status'] ?? 'Confirmed',
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shippingAddress: Map<String, dynamic>.from(data['shippingAddress'] ?? {}),
      sellerIds: List<String>.from(data['sellerIds'] ?? []),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Order Service - Clean and focused
class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'user_orders'; // Updated table name

  // Generate simple order ID
  static String _generateOrderId() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMddHHmmss');
    final timestamp = formatter.format(now);
    final random = Random();
    final randomNumber = random.nextInt(9000) + 1000;

    return 'ORD-$timestamp-$randomNumber';
  }

  // Create order - Main method
  static Future<String?> createOrder({
    required List<CartItem> cartItems,
    required double totalAmount,
    required String paymentMethod,
    required Map<String, dynamic> shippingAddress,
    String status = 'Confirmed',
  }) async {
    try {
      debugPrint('🚀 [ORDER_CREATE] Starting order creation process...');
      debugPrint('🚀 [ORDER_CREATE] Collection: $_collection');

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [ORDER_CREATE] No user logged in');
        return null;
      }
      debugPrint('✅ [ORDER_CREATE] User ID: ${currentUser.uid}');

      // Fetch customer document
      final customerDoc = await _firestore
          .collection('customers')
          .doc(currentUser.uid)
          .get();

      if (!customerDoc.exists) {
        debugPrint(
          '❌ [ORDER_CREATE] Customer document not found for user: ${currentUser.uid}',
        );
        return null;
      }
      debugPrint('✅ [ORDER_CREATE] Customer document found');

      final customerData = customerDoc.data();
      if (customerData == null) {
        debugPrint('❌ [ORDER_CREATE] Customer data is null');
        return null;
      }
      debugPrint('✅ [ORDER_CREATE] Customer data: $customerData');

      // Generate order ID
      final orderId = _generateOrderId();
      debugPrint('✅ [ORDER_CREATE] Generated Order ID: $orderId');

      // Convert cart items to order items
      final orderItems = cartItems
          .map((cartItem) => OrderItem.fromCartItem(cartItem))
          .toList();
      debugPrint(
        '✅ [ORDER_CREATE] Converted ${orderItems.length} cart items to order items',
      );

      // Collect unique seller IDs from cart items
      final sellerIds = cartItems
          .map((item) => item.product.sellerId)
          .where((sellerId) => sellerId.isNotEmpty)
          .toSet()
          .toList();
      debugPrint('✅ [ORDER_CREATE] Collected seller IDs: $sellerIds');

      // Create order object
      final order = Order(
        orderId: orderId,
        userId: currentUser.uid,
        customerName: customerData['name'] ?? 'Unknown',
        customerEmail: customerData['email'] ?? '',
        items: orderItems,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        status: status,
        orderDate: DateTime.now(),
        shippingAddress: shippingAddress,
        sellerIds: sellerIds,
        lastUpdated: DateTime.now(),
      );
      debugPrint('✅ [ORDER_CREATE] Order object created: $order');

      // Convert order to map
      final orderMap = order.toMap();
      debugPrint('✅ [ORDER_CREATE] Order map: $orderMap');

      // Save order to Firestore
      await _firestore.collection(_collection).doc(orderId).set(orderMap);
      debugPrint('✅ [ORDER_CREATE] Order saved to Firestore');

      // Verify order was saved
      final savedDoc = await _firestore
          .collection(_collection)
          .doc(orderId)
          .get();
      if (savedDoc.exists) {
        debugPrint('✅ [ORDER_CREATE] Order verification successful');
      } else {
        debugPrint('❌ [ORDER_CREATE] Order verification failed');
        return null;
      }

      // IMPORTANT: Decrement stock for each item in the order
      debugPrint('📊 [ORDER_CREATE] Starting stock decrement process...');
      for (final item in cartItems) {
        final variantInfo = item.selectedVariantId != null
            ? ' (Variant: ${item.variantDisplayText})'
            : '';
        debugPrint(
          '📊 [ORDER_CREATE] Decrementing stock for: ${item.product.name}$variantInfo (PID: ${item.product.pid}, Qty: ${item.quantity})',
        );
        final stockUpdated = await StockService.decrementStock(
          item.product.pid,
          item.quantity,
          variantId: item
              .selectedVariantId, // Pass variant ID for variant-specific stock management
        );
        if (!stockUpdated) {
          debugPrint(
            '⚠️ [ORDER_CREATE] Failed to update stock for ${item.product.name}$variantInfo',
          );
        } else {
          debugPrint(
            '✅ [ORDER_CREATE] Stock updated successfully for ${item.product.name}$variantInfo',
          );
        }
      }
      debugPrint('✅ [ORDER_CREATE] Stock decrement process completed');

      debugPrint(
        '🎉 [ORDER_CREATE] Order creation process completed successfully',
      );
      return orderId;
    } catch (e, stackTrace) {
      debugPrint('❌ [ORDER_CREATE] Error: $e');
      debugPrint('❌ [ORDER_CREATE] Stack trace: $stackTrace');
      return null;
    }
  }

  // Get user orders - Simple query
  static Future<List<Order>> getUserOrders(String userId) async {
    try {
      debugPrint('🔍 [ORDER_FETCH] Collection: $_collection');

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();

      final orders = <Order>[];
      for (final doc in querySnapshot.docs) {
        try {
          final order = Order.fromFirestore(doc);
          orders.add(order);
        } catch (e) {
          debugPrint('❌ [ORDER_FETCH] Error parsing document: $e');
        }
      }

      return orders;
    } catch (e) {
      debugPrint('❌ [ORDER_FETCH] Error fetching orders: $e');
      return [];
    }
  }

  // Get single order by ID
  static Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(orderId).get();

      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching order: $e');
      return null;
    }
  }

  // Update order status
  static Future<bool> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'status': newStatus,
      });

      debugPrint('✅ Order status updated: $orderId -> $newStatus');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating order status: $e');
      return false;
    }
  }

  // ===== SELLER METHODS =====

  /// Get orders for a seller (products they've sold)
  /// This method filters orders to only show products from the specific seller
  static Future<List<Order>> getSellerOrders(String sellerId) async {
    try {
      debugPrint('🔍 Loading orders for seller: $sellerId');

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('sellerIds', arrayContains: sellerId)
          .orderBy('orderDate', descending: true)
          .get();

      final orders = <Order>[];
      for (final doc in querySnapshot.docs) {
        try {
          final order = Order.fromFirestore(doc);

          // Filter items to only show this seller's products
          final sellerItems = order.items
              .where((item) => item.sellerId == sellerId)
              .toList();

          if (sellerItems.isNotEmpty) {
            // Create a modified order with only this seller's items
            final sellerOrder = Order(
              orderId: order.orderId,
              userId: order.userId,
              customerName: order.customerName,
              customerEmail: order.customerEmail,
              items: sellerItems,
              totalAmount: sellerItems.fold(
                0.0,
                (sum, item) => sum + (item.productPrice * item.quantity),
              ),
              paymentMethod: order.paymentMethod,
              status: order.status,
              orderDate: order.orderDate,
              shippingAddress: order.shippingAddress,
              sellerIds: [sellerId],
              lastUpdated: order.lastUpdated,
            );
            orders.add(sellerOrder);
          }
        } catch (e) {
          debugPrint('❌ Error parsing order: $e');
        }
      }

      debugPrint('✅ Loaded ${orders.length} orders for seller');
      return orders;
    } catch (e) {
      debugPrint('❌ Error fetching seller orders: $e');
      return [];
    }
  }

  /// Get stock consumed by orders for a seller's products
  /// Returns a map of productId -> quantity sold
  static Future<Map<String, int>> getStockConsumedByOrders(
    String sellerId,
  ) async {
    try {
      debugPrint('📊 Calculating stock consumed for seller: $sellerId');

      final orders = await getSellerOrders(sellerId);
      final stockMap = <String, int>{};

      for (final order in orders) {
        for (final item in order.items) {
          final key = item.productId;
          stockMap[key] = (stockMap[key] ?? 0) + item.quantity;
        }
      }

      debugPrint('📊 Stock consumed: $stockMap');
      return stockMap;
    } catch (e) {
      debugPrint('❌ Error calculating stock consumed: $e');
      return {};
    }
  }

  /// Get stock analytics for seller
  /// Shows remaining stock accounting for orders
  static Future<Map<String, dynamic>> getSellerStockAnalytics(
    String sellerId,
  ) async {
    try {
      final consumed = await getStockConsumedByOrders(sellerId);

      // Query all products from this seller
      final productsSnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      final analytics = <String, dynamic>{};

      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        final productId = data['pid'] as String;
        final productName = data['name'] as String;
        final totalStock = (data['stockQuantity'] as num?)?.toInt() ?? 0;
        final consumedByOrders = consumed[productId] ?? 0;
        final remaining = totalStock - consumedByOrders;

        analytics[productId] = {
          'productName': productName,
          'totalStock': totalStock,
          'consumedByOrders': consumedByOrders,
          'remaining': remaining,
          'percentageSold': totalStock > 0 ? (consumedByOrders / totalStock) * 100 : 0,
        };
      }

      debugPrint('📊 Stock analytics: $analytics');
      return analytics;
    } catch (e) {
      debugPrint('❌ Error calculating stock analytics: $e');
      return {};
    }
  }
}
