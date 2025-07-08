import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up
  Future<String?> signUpUser({
    required String name,
    required String email,
    required String password,
    required String mobile,
  }) async {
    try {
      print('🔥 Creating Firebase Auth user...');
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;
      print('✅ Firebase Auth user created with UID: $uid');

      final userData = {
        'name': name,
        'email': email,
        'phone': mobile, // This is what mobile login searches for
        'mobile': mobile, // Keep both for compatibility
        'role': "customer",
        'createdAt': Timestamp.now(),
      };

      print('💾 Saving user data to Firestore:');
      print('   - Name: $name');
      print('   - Email: $email');
      print('   - Phone: $mobile');
      print('   - UID: $uid');

      await _firestore.collection('customers').doc(uid).set(userData);
      print('✅ User data saved to Firestore successfully!');

      return null; // success
    } catch (e) {
      print('❌ Firebase SignUp error: $e');
      return e.toString(); // return error message
    }
  }

  // Login
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } catch (e) {
      return e.toString(); // return error message
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user ID
  String? getCurrentUID() {
    return _auth.currentUser?.uid;
  }

  // Get user details
  Future<DocumentSnapshot> getUserDetails() async {
    final uid = getCurrentUID();
    return _firestore.collection('customers').doc(uid).get();
  }

  Future<String?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // success
    } catch (e) {
      print('Login error: $e');
      return e.toString(); // return error string
    }
  }

  Future<Map<String, dynamic>?> getUserDetailsAsMap() async {
    final uid = getCurrentUID();
    final doc = await _firestore.collection('customers').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}
