import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:buy_app/models/models.dart';

class CommentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'product_comments';

  /// Get user details from database
  static Future<Map<String, dynamic>> _getUserDetails(String userId) async {
    try {
      // Try customers collection first
      var doc = await _firestore.collection('customers').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        debugPrint('✅ Found user in customers collection');
        return doc.data()!;
      }

      // Try users collection as fallback
      doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        debugPrint('✅ Found user in users collection');
        return doc.data()!;
      }

      // Try sellers collection as another fallback
      doc = await _firestore.collection('sellers').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        debugPrint('✅ Found user in sellers collection');
        return doc.data()!;
      }

      debugPrint('❌ User not found in any collection');
      return {};
    } catch (e) {
      debugPrint('❌ Error fetching user details: $e');
      return {};
    }
  }

  /// Add a new comment/review for a product
  static Future<bool> addComment({
    required String productId,
    required String comment,
    required double rating,
    String? variantId,
    Map<String, String>? variantAttributes,
    List<String> images = const [],
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      // Validate input
      if (productId.isEmpty || comment.trim().isEmpty) {
        debugPrint('❌ Invalid input: productId or comment is empty');
        return false;
      }

      if (rating < 1.0 || rating > 5.0) {
        debugPrint('❌ Invalid rating: must be between 1.0 and 5.0');
        return false;
      }

      // Get user details from database
      final userDetails = await _getUserDetails(currentUser.uid);

      // Create comment document
      final commentData = {
        'productId': productId,
        'userId': currentUser.uid,
        'userName': userDetails['name'] ?? 'Anonymous',
        'userEmail': userDetails['email'] ?? currentUser.email ?? '',
        'comment': comment.trim(),
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': false, // Can be updated later based on purchase history
        'images': images,
        if (variantId != null) 'variantId': variantId,
        if (variantAttributes != null) 'variantAttributes': variantAttributes,
      };

      await _firestore.collection(_collection).add(commentData);

      debugPrint('✅ Comment added successfully for product: $productId');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      return false;
    }
  }

  /// Get all comments for a specific product
  static Future<List<ProductComment>> getProductComments(
    String productId, {
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      if (productId.isEmpty) {
        debugPrint('❌ Product ID is empty');
        return [];
      }

      Query query = _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .orderBy('timestamp', descending: true);

      // Apply limit if specified
      if (limit != null) {
        query = query.limit(limit);
      }

      // Pagination support
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(_collection)
            .doc(lastDocumentId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        return ProductComment.fromFirestore(
          doc.data()! as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching comments: $e');
      return [];
    }
  }

  /// Get comment statistics for a product
  static Future<CommentStatistics> getCommentStatistics(
    String productId,
  ) async {
    try {
      if (productId.isEmpty) {
        return CommentStatistics.empty();
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return CommentStatistics.empty();
      }

      int totalComments = querySnapshot.docs.length;
      double totalRating = 0.0;
      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] ?? 0.0).toDouble();
        totalRating += rating;

        // Count rating distribution
        final ratingInt = rating.round();
        if (ratingInt >= 1 && ratingInt <= 5) {
          ratingDistribution[ratingInt] = ratingDistribution[ratingInt]! + 1;
        }
      }

      double averageRating = totalComments > 0
          ? totalRating / totalComments
          : 0.0;

      return CommentStatistics(
        totalComments: totalComments,
        averageRating: averageRating,
        ratingDistribution: ratingDistribution,
      );
    } catch (e) {
      debugPrint('❌ Error fetching comment statistics: $e');
      return CommentStatistics.empty();
    }
  }

  /// Check if current user has already commented on this product
  static Future<bool> hasUserCommented(
    String productId, {
    String? variantId,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      Query query = _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: currentUser.uid);

      // If checking for specific variant
      if (variantId != null) {
        query = query.where('variantId', isEqualTo: variantId);
      }

      final querySnapshot = await query.limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking user comment: $e');
      return false;
    }
  }

  /// Update an existing comment
  static Future<bool> updateComment({
    required String commentId,
    required String comment,
    required double rating,
    List<String> images = const [],
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      // Verify ownership
      final doc = await _firestore.collection(_collection).doc(commentId).get();
      if (!doc.exists) {
        debugPrint('❌ Comment not found');
        return false;
      }

      final data = doc.data();
      if (data!['userId'] != currentUser.uid) {
        debugPrint('❌ User not authorized to update this comment');
        return false;
      }

      // Update comment
      await _firestore.collection(_collection).doc(commentId).update({
        'comment': comment.trim(),
        'rating': rating,
        'images': images,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Comment updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating comment: $e');
      return false;
    }
  }

  /// Delete a comment
  static Future<bool> deleteComment(String commentId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      // Verify ownership
      final doc = await _firestore.collection(_collection).doc(commentId).get();
      if (!doc.exists) {
        debugPrint('❌ Comment not found');
        return false;
      }

      final data = doc.data();
      if (data!['userId'] != currentUser.uid) {
        debugPrint('❌ User not authorized to delete this comment');
        return false;
      }

      // Delete comment
      await _firestore.collection(_collection).doc(commentId).delete();

      debugPrint('✅ Comment deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting comment: $e');
      return false;
    }
  }

  /// Get comments by current user
  static Future<List<ProductComment>> getUserComments({int? limit}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return [];
      }

      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        return ProductComment.fromFirestore(
          doc.data()! as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching user comments: $e');
      return [];
    }
  }

  /// Listen to real-time comments for a product
  static Stream<List<ProductComment>> streamProductComments(
    String productId, {
    int? limit,
  }) {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('productId', isEqualTo: productId)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return ProductComment.fromFirestore(
            doc.data()! as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ Error streaming comments: $e');
      return Stream.value([]);
    }
  }
}
