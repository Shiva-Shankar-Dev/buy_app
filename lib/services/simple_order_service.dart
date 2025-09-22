import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleOrder {
  final String id;
  final String customerEmail;
  final String customerName;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic> details;

  SimpleOrder({
    required this.id,
    required this.customerEmail,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.details,
  });

  factory SimpleOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SimpleOrder(
      id: doc.id,
      customerEmail: data['customerEmail'] ?? '',
      customerName: data['customerName'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: data['details'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerEmail': customerEmail,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'details': details,
    };
  }
}

class SimpleOrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String collection = 'orders';

  // Save order
  static Future<String?> createOrder({
    required String customerEmail,
    required String customerName,
    required double totalAmount,
    required Map<String, dynamic> orderDetails,
  }) async {
    try {
      final docRef = await _db.collection(collection).add({
        'customerEmail': customerEmail,
        'customerName': customerName,
        'totalAmount': totalAmount,
        'status': 'Confirmed',
        'createdAt': Timestamp.now(),
        'details': orderDetails,
      });

      print('✅ Order created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating order: $e');
      return null;
    }
  }

  // Get user orders
  static Future<List<SimpleOrder>> getUserOrders(String userEmail) async {
    try {
      final snapshot = await _db
          .collection(collection)
          .where('customerEmail', isEqualTo: userEmail)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SimpleOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting orders: $e');
      return [];
    }
  }

  // Get orders by status
  static Future<List<SimpleOrder>> getUserOrdersByStatus(
    String userEmail,
    String status,
  ) async {
    try {
      final snapshot = await _db
          .collection(collection)
          .where('customerEmail', isEqualTo: userEmail)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SimpleOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting orders by status: $e');
      return [];
    }
  }

  // Update order status
  static Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _db.collection(collection).doc(orderId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('❌ Error updating order: $e');
      return false;
    }
  }

  // Get single order
  static Future<SimpleOrder?> getOrderById(String orderId) async {
    try {
      final doc = await _db.collection(collection).doc(orderId).get();
      if (doc.exists) {
        return SimpleOrder.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting order: $e');
      return null;
    }
  }
}
