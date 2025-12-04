import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DebugUsers {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debug function to list all users and their phone numbers
  static Future<void> listAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      

      for (int i = 0; i < snapshot.docs.length; i++) {
        DocumentSnapshot doc = snapshot.docs[i];
        Map<String, dynamic> _ = doc.data() as Map<String, dynamic>;
        
      }
    } catch (e) {
      debugPrint("Firebase initialization error: $e");
    }
  }

  // Check if a specific phone number exists
  static Future<bool> checkPhoneExists(String phone) async {
    try {

      QuerySnapshot result = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      

      if (result.docs.isNotEmpty) {
        for (var doc in result.docs) {
          Map<String, dynamic> _ = doc.data() as Map<String, dynamic>;
        }
        return true;
      }
      
      // Also check 'mobile' field for backwards compatibility
      QuerySnapshot mobileResult = await _firestore
          .collection('users')
          .where('mobile', isEqualTo: phone)
          .get();
      

      return mobileResult.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
