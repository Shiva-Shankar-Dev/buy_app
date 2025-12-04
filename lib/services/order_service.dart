import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'dart:math';
import 'package:intl/intl.dart';
// Order Item for storage
class OrderItem {
  final String productTitle;
  final double productPrice;
  final int quantity;
  final String? productImage;

  OrderItem({
    required this.productTitle,
    required this.productPrice,
    required this.quantity,
    this.productImage,
  });

  // Convert from CartItem
  factory OrderItem.fromCartItem(CartItem cartItem) {
    return OrderItem(
      productTitle: cartItem.product.name,
      productPrice: cartItem.product.price,
      quantity: cartItem.quantity,
      productImage: cartItem.product.images.isNotEmpty
          ? cartItem.product.images[0]
          : null,
    );
  }

  // Convert to/from Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productTitle': productTitle,
      'productPrice': productPrice,
      'quantity': quantity,
      'productImage': productImage,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productTitle: map['productTitle'] ?? 'Unknown Product',
      productPrice: (map['productPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      productImage: map['productImage'],
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

      debugPrint('🎉 [ORDER_CREATE] Order creation process completed successfully');
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
}
