import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buy_app/models/models.dart';

class WishlistService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'user_wishlists';

  // Add product to wishlist
  static Future<bool> addToWishlist(Product product) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }

      // Check if product title exists
      if (product.title.isEmpty) {
        print('❌ Product title is empty');
        return false;
      }

      // Generate document ID from title (sanitized)
      final productId = product.title
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();

      // Create wishlist document reference
      final docRef = _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .doc(productId);

      // Check if product already exists
      final doc = await docRef.get();
      if (!doc.exists) {
        // Add product with timestamp
        final wishlistItem = {
          ...product.toFirestore(),
          'addedAt': Timestamp.now(),
          'userId': currentUser.uid,
        };

        await docRef.set(wishlistItem);
        print('✅ Added to wishlist: ${product.title}');
        return true;
      }

      print('⚠️ Product already in wishlist: ${product.title}');
      return false;
    } catch (e) {
      print('❌ Error adding to wishlist: $e');
      return false;
    }
  }

  // Remove product from wishlist
  static Future<bool> removeFromWishlist(Product product) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }

      // Generate document ID from title (sanitized)
      final productId = product.title
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();

      // Remove from Firestore
      final docRef = _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .doc(productId);

      await docRef.delete();
      print('✅ Removed from wishlist: ${product.title}');
      return true;
    } catch (e) {
      print('❌ Error removing from wishlist: $e');
      return false;
    }
  }

  // Get all wishlist products
  static Future<List<Product>> getWishlistProducts() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return [];
      }

      // Fetch wishlist items from Firestore
      final querySnapshot = await _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .orderBy('addedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Product.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      print('❌ Error getting wishlist: $e');
      return [];
    }
  }

  // Check if product is in wishlist
  static Future<bool> isInWishlist(Product product) async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }

      // Generate document ID from title (sanitized)
      final productId = product.title
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_')
          .toLowerCase();

      // Check if document exists
      final docRef = _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .doc(productId);

      final doc = await docRef.get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking wishlist: $e');
      return false;
    }
  }

  // Clear entire wishlist
  static Future<bool> clearWishlist() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }

      // Get all documents and delete them in batch
      final batch = _firestore.batch();
      final collectionRef = _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items');

      final querySnapshot = await collectionRef.get();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Wishlist cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing wishlist: $e');
      return false;
    }
  }

  // Get wishlist count
  static Future<int> getWishlistCount() async {
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return 0;
      }

      // Count documents in wishlist collection
      final querySnapshot = await _firestore
          .collection(_collection)
          .doc(currentUser.uid)
          .collection('items')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ Error getting wishlist count: $e');
      return 0;
    }
  }
}
