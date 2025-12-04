import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, this.quantity = 1});

  @override
  String toString() {
    return 'CartItem(product: ${product.name}, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.product.name == product.name &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => product.name.hashCode ^ quantity.hashCode;

  // Add toMap method for Firestore
  Map<String, dynamic> toMap() {
    return {'product': product.toFirestore(), 'quantity': quantity};
  }

  // Add fromMap method for Firestore
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromFirestore(map['product'] ?? {}),
      quantity: map['quantity'] ?? 1,
    );
  }
}

class Product {
  final String name, brand, description, deliveryTime, pid, sellerId;
  final double price;
  final String category;
  final List<String> keywords;
  final List<String> images;
  final int stockQuantity;

  Product({
    required this.name,
    required this.brand,
    required this.images,
    required this.description,
    required this.category,
    required this.price,
    required this.deliveryTime,
    required this.pid,
    required this.keywords,
    required this.stockQuantity,
    required this.sellerId,
  });

  factory Product.fromFirestore(Map<String, dynamic> data) {
    return Product(
      name: data['name'] ?? 'Untitled',
      brand: data['brand'] ?? '',
      description: data['description'] ?? '',
      deliveryTime: data['deliveryTime'] ?? 'N/A',
      pid: data['pid'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      keywords: List<String>.from(data['keywords'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      stockQuantity: data['stockQuantity'] ?? 0,
      sellerId: data['sellerId'] ?? null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'description': description,
      'deliveryTime': deliveryTime,
      'pid': pid,
      'price': price,
      'category': category,
      'keywords': keywords,
      'images': images,
      'stockQuantity': stockQuantity,
      'sellerId' : sellerId,
    };
  }

  @override
  String toString() {
    return 'Product(name: $name, price: $price, brand: $brand)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

class Order {
  final String orderId;
  final String customerEmail;
  final String customerName;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String txnId;
  final DateTime orderDate;
  final String status;
  final Map<String, dynamic> shippingAddress;

  Order({
    required this.orderId,
    required this.customerEmail,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.txnId,
    required this.orderDate,
    required this.status,
    required this.shippingAddress,
  });

  factory Order.fromFirestore(Map<String, dynamic> data) {
    try {
      return Order(
        orderId: data['orderId']?.toString() ?? '',
        customerEmail: data['customerEmail']?.toString() ?? '',
        customerName: data['customerName']?.toString() ?? '',
        items: _parseItems(data['items']),
        totalAmount: _parseDouble(data['totalAmount']),
        paymentMethod: data['paymentMethod']?.toString() ?? '',
        txnId: data['txnId']?.toString() ?? '',
        orderDate: _parseDateTime(data['orderDate']),
        status: data['status']?.toString() ?? 'Pending',
        shippingAddress: Map<String, dynamic>.from(
          data['shippingAddress'] ?? {},
        ),
      );
    } catch (e) {
      debugPrint('❌ Error parsing Order from Firestore: $e');
      // Return a default order in case of parsing error
      return Order(
        orderId: data['orderId']?.toString() ?? 'unknown',
        customerEmail: data['customerEmail']?.toString() ?? '',
        customerName: data['customerName']?.toString() ?? '',
        items: [],
        totalAmount: 0.0,
        paymentMethod: '',
        txnId: '',
        orderDate: DateTime.now(),
        status: 'Error',
        shippingAddress: {},
      );
    }
  }

  // Helper methods for parsing (static methods inside Order class)
  static List<CartItem> _parseItems(dynamic itemsData) {
    try {
      if (itemsData is List) {
        return itemsData.map((item) {
          try {
            return CartItem.fromMap(Map<String, dynamic>.from(item ?? {}));
          } catch (e) {
            debugPrint('❌ Error parsing CartItem: $e');
            // Return a default CartItem with basic Product
            return CartItem(
              product: Product(
                name: 'Error Product',
                brand: '',
                description: '',
                deliveryTime: '',
                pid: '',
                price: 0.0,
                category: '',
                keywords: [],
                images: [],
                stockQuantity: 0,
                sellerId: '',
              ),
              quantity: 1,
            );
          }
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error parsing items list: $e');
      return [];
    }
  }

  static double _parseDouble(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (e) {
      debugPrint('❌ Error parsing double: $e');
      return 0.0;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    try {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    } catch (e) {
      debugPrint('❌ Error parsing DateTime: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerEmail': customerEmail,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'txnId': txnId,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status,
      'shippingAddress': shippingAddress,
    };
  }

  @override
  String toString() {
    return 'Order(orderId: $orderId, customerEmail: $customerEmail, totalAmount: $totalAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.orderId == orderId;
  }

  @override
  int get hashCode => orderId.hashCode;
}
