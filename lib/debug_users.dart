import 'package:cloud_firestore/cloud_firestore.dart';

class DebugUsers {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debug function to list all users and their phone numbers
  static Future<void> listAllUsers() async {
    try {
      print('🔍 Fetching all users from Firestore...');
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      
      print('📊 Found ${snapshot.docs.length} users in total:');
      print('=' * 50);
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        DocumentSnapshot doc = snapshot.docs[i];
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        print('User ${i + 1}:');
        print('  - UID: ${doc.id}');
        print('  - Name: ${data['name'] ?? 'N/A'}');
        print('  - Email: ${data['email'] ?? 'N/A'}');
        print('  - Phone: ${data['phone'] ?? 'N/A'}');
        print('  - Mobile: ${data['mobile'] ?? 'N/A'}');
        print('  - Created: ${data['createdAt']?.toDate() ?? 'N/A'}');
        print('-' * 30);
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
    }
  }

  // Check if a specific phone number exists
  static Future<bool> checkPhoneExists(String phone) async {
    try {
      print('🔍 Checking if phone exists: $phone');
      
      QuerySnapshot result = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      
      print('📱 Phone search result: ${result.docs.length} users found');
      
      if (result.docs.isNotEmpty) {
        for (var doc in result.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          print('  - Found user: ${data['name']} (${data['email']})');
        }
        return true;
      }
      
      // Also check 'mobile' field for backwards compatibility
      QuerySnapshot mobileResult = await _firestore
          .collection('users')
          .where('mobile', isEqualTo: phone)
          .get();
      
      print('📱 Mobile search result: ${mobileResult.docs.length} users found');
      
      return mobileResult.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking phone: $e');
      return false;
    }
  }
}
