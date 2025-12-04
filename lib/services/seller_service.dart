import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SellerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get seller details by their Firebase user ID
  static Future<Map<String, dynamic>?> getSellerDetails(String sellerId) async {
    try {
      debugPrint("🔍 Fetching seller details for ID: $sellerId");

      final doc = await _firestore.collection('sellers').doc(sellerId).get();

      if (doc.exists) {
        final data = doc.data();
        debugPrint("✅ Seller found: ${data?['name']} (${data?['email']})");
        return data;
      } else {
        debugPrint("❌ No seller found with ID: $sellerId");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error fetching seller details: $e");
      return null;
    }
  }

  // Get seller email by their Firebase user ID
  static Future<String?> getSellerEmail(String sellerId) async {
    final sellerData = await getSellerDetails(sellerId);
    return sellerData?['email'];
  }
}
