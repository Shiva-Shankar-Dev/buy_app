import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:buy_app/models/models.dart';

class WishlistService {
  static const String _wishlistKey = 'user_wishlist';

  // Add product to wishlist
  static Future<bool> addToWishlist(Product product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> wishlistJson = prefs.getStringList(_wishlistKey) ?? [];

      // Check if product already exists
      bool exists = wishlistJson.any((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        return data['title'] == product.title;
      });

      if (!exists) {
        wishlistJson.add(jsonEncode(product.toFirestore()));
        await prefs.setStringList(_wishlistKey, wishlistJson);
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
      final prefs = await SharedPreferences.getInstance();
      List<String> wishlistJson = prefs.getStringList(_wishlistKey) ?? [];

      wishlistJson.removeWhere((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        return data['title'] == product.title;
      });

      await prefs.setStringList(_wishlistKey, wishlistJson);
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
      final prefs = await SharedPreferences.getInstance();
      List<String> wishlistJson = prefs.getStringList(_wishlistKey) ?? [];

      return wishlistJson.map((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        return Product.fromFirestore(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting wishlist: $e');
      return [];
    }
  }

  // Check if product is in wishlist
  static Future<bool> isInWishlist(Product product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> wishlistJson = prefs.getStringList(_wishlistKey) ?? [];

      return wishlistJson.any((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        return data['title'] == product.title;
      });
    } catch (e) {
      print('❌ Error checking wishlist: $e');
      return false;
    }
  }

  // Clear entire wishlist
  static Future<bool> clearWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_wishlistKey);
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
      final prefs = await SharedPreferences.getInstance();
      List<String> wishlistJson = prefs.getStringList(_wishlistKey) ?? [];
      return wishlistJson.length;
    } catch (e) {
      print('❌ Error getting wishlist count: $e');
      return 0;
    }
  }
}
