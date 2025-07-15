import 'package:cloud_firestore/cloud_firestore.dart';

class SellerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get seller details by their Firebase user ID
  static Future<Map<String, dynamic>?> getSellerDetails(String sellerId) async {
    try {
      print("🔍 Fetching seller details for ID: $sellerId");

      final doc = await _firestore.collection('sellers').doc(sellerId).get();

      if (doc.exists) {
        final data = doc.data();
        print("✅ Seller found: ${data?['name']} (${data?['email']})");
        return data;
      } else {
        print("❌ No seller found with ID: $sellerId");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching seller details: $e");
      return null;
    }
  }

  // Get seller email by their Firebase user ID
  static Future<String?> getSellerEmail(String sellerId) async {
    final sellerData = await getSellerDetails(sellerId);
    return sellerData?['email'];
  }
}
