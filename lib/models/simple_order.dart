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
