import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/seller_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/models/models.dart'; // Import from models file

class EmailService {
  static const String _emailServerUrl = 'http://10.0.2.2:3000/send';

  // Define maximum quantities per category
  static const Map<String, int> _categoryMaxQuantities = {
    'mobiles': 4,
    'mobile': 4,
    'phone': 4,
    'smartphone': 4,
    'electronics': 3,
    'laptop': 2,
    'computer': 2,
    'tablet': 3,
    'headphones': 5,
    'earphones': 5,
    'watch': 3,
    'smartwatch': 3,
    'camera': 2,
    'gaming': 2,
    'console': 1,
    'tv': 1,
    'television': 1,
    'appliances': 1,
    'refrigerator': 1,
    'washing machine': 1,
    'microwave': 1,
    'ac': 1,
    'air conditioner': 1,
    'furniture': 2,
    'books': 10,
    'clothing': 8,
    'shoes': 6,
    'accessories': 10,
    'beauty': 5,
    'cosmetics': 5,
    'health': 5,
    'sports': 4,
    'toys': 6,
    'home': 5,
    'kitchen': 3,
    'automotive': 2,
    'jewelry': 4,
    'default': 10, // Default maximum for categories not listed
  };

  /// Get maximum allowed quantity for a category
  static int getMaxQuantityForCategory(String category) {
    if (category.isEmpty) return _categoryMaxQuantities['default']!;

    final categoryLower = category.toLowerCase().trim();

    // Check for exact match first
    if (_categoryMaxQuantities.containsKey(categoryLower)) {
      return _categoryMaxQuantities[categoryLower]!;
    }

    // Check for partial matches
    for (final key in _categoryMaxQuantities.keys) {
      if (categoryLower.contains(key) || key.contains(categoryLower)) {
        return _categoryMaxQuantities[key]!;
      }
    }

    return _categoryMaxQuantities['default']!;
  }

  /// Send a basic email
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_emailServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'to': to, 'subject': subject, 'text': message}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Email sent successfully to: $to');
        return true;
      } else {
        debugPrint('❌ Failed to send email: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Email exception: $e');
      return false;
    }
  }

  /// Send order confirmation email to customer
  static Future<bool> sendCustomerConfirmationEmail({
    required String customerEmail,
    required String customerName,
    required Address shippingAddress,
    required List<CartItem> orderedItems,
    required String ordId,
    required String paymentMethod,
    required String txnId,
  }) async {
    // Calculate total amount considering quantities
    double totalAmount = orderedItems.fold(
      0.0,
      (s, item) => s + (item.product.price * item.quantity),
    );

    String message1 = "<html><body>";
    message1 += "<h2>Dear $customerName,</h2>";
    message1 += "<p>Your order has been successfully placed!</p>";
    message1 += "<h3>ORDER SUMMARY</h3>";
    message1 += "<p><strong>Order ID:</strong> $ordId</p>";

    // Create HTML table for products with quantities
    message1 += "<h4>Ordered Products:</h4>";
    message1 +=
        "<table border='1' cellpadding='8' cellspacing='0' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
    message1 += "<thead style='background-color: #f0f0f0;'>";
    message1 +=
        "<tr><th style='text-align: left; padding: 10px;'>Product Name</th><th style='text-align: center; padding: 10px;'>Quantity</th><th style='text-align: right; padding: 10px;'>Unit Price</th><th style='text-align: right; padding: 10px;'>Total</th></tr>";
    message1 += "</thead><tbody>";

    for (final item in orderedItems) {
      final itemTotal = item.product.price * item.quantity;
      message1 += "<tr>";
      message1 +=
          "<td style='padding: 8px; border-bottom: 1px solid #ddd;'>${item.product.name}</td>";
      message1 +=
          "<td style='padding: 8px; text-align: center; border-bottom: 1px solid #ddd;'>${item.quantity}</td>";
      message1 +=
          "<td style='padding: 8px; text-align: right; border-bottom: 1px solid #ddd;'>₹${item.product.price.toStringAsFixed(2)}</td>";
      message1 +=
          "<td style='padding: 8px; text-align: right; border-bottom: 1px solid #ddd;'>₹${itemTotal.toStringAsFixed(2)}</td>";
      message1 += "</tr>";
    }

    message1 += "</tbody></table>";
    message1 +=
        "<p><strong>TOTAL AMOUNT: ₹${totalAmount.toStringAsFixed(2)}</strong></p>";
    message1 += "<p><strong>Payment Method:</strong> $paymentMethod</p>";
    message1 += "<p><strong>Transaction ID:</strong> $txnId</p>";

    message1 += "<h4>SHIPPING ADDRESS:</h4>";
    message1 +=
        "<div style='background-color: #f9f9f9; padding: 10px; border-left: 4px solid #007bff; margin: 10px 0;'>";
    message1 += "<p>${shippingAddress.first} ${shippingAddress.last}<br>";
    message1 += "${shippingAddress.line1}<br>";
    if (shippingAddress.line2.isNotEmpty) {
      message1 += "${shippingAddress.line2}<br>";
    }
    message1 +=
        "${shippingAddress.city}, ${shippingAddress.state} - ${shippingAddress.pincode}</p>";
    message1 += "</div>";

    message1 += "<hr style='margin: 20px 0;'>";
    message1 +=
        "<p>Your order will be processed soon. You will receive updates via email and SMS.</p>";
    message1 += "<p><strong>Thank you for shopping with us!</strong></p>";
    message1 += "</body></html>";

    return await sendEmail(
      to: customerEmail,
      subject: "Order Confirmation - Your order has been placed!",
      message: message1,
    );
  }

  /// Send order details to sellers
  static Future<bool> sendOrderDetailsToSellers({
    required Map<String, dynamic> customer,
    required Address shippingAddress,
    required String ordId,
    required String paymentMethod,
    required String txnId,
  }) async {
    final cart = Cart.instance;

    if (cart.items.isEmpty) {
      debugPrint("❌ No items in cart to send to sellers");
      return false;
    }

    debugPrint(
      "🛒 Cart items: ${cart.items.map((item) => item.product.name).toList()}",
    );

    // Group cart items by seller ID (if available from a separate source)
    // Note: Product no longer has sellerId field, you may need to fetch this from another service
    Map<String?, List<CartItem>> itemsBySeller = {};
    int itemsWithoutSellerId = 0;

    for (final item in cart.items) {
      // TODO: Fetch seller ID from product or order service
      // For now, grouping all items together
      final sellerId = null; // product.sellerId is no longer available
      if (sellerId == null) {
        debugPrint("⚠️ Product '${item.product.name}' seller ID not available...");
        itemsWithoutSellerId++;
        continue;
      }
      if (itemsBySeller[sellerId] == null) {
        itemsBySeller[sellerId] = [];
      }
      itemsBySeller[sellerId]!.add(item);
    }

    if (itemsWithoutSellerId > 0) {
      debugPrint("⚠️ Found $itemsWithoutSellerId items without seller IDs");
    }

    if (itemsBySeller.isEmpty) {
      debugPrint("❌ No items with valid seller IDs found");
      return false;
    }

    debugPrint("📊 Found ${itemsBySeller.length} sellers to notify");

    bool allEmailsSent = true;
    // Send email to each seller
    for (final entry in itemsBySeller.entries) {
      final sellerId = entry.key;
      final items = entry.value;

      if (sellerId == null || sellerId.isEmpty) {
        debugPrint("⚠️ Item without seller ID found in group, skipping...");
        continue;
      }

      debugPrint(
        "📧 Sending email to sellerId: $sellerId for products: ${items.map((item) => item.product.name).toList()}",
      );

      final success = await _sendSellerOrderEmail(
        sellerId: sellerId,
        items: items,
        customer: customer,
        shippingAddress: shippingAddress,
        ordId: ordId,
        paymentMethod: paymentMethod,
        txnId: txnId,
      );

      if (!success) {
        allEmailsSent = false;
      }
    }

    return allEmailsSent;
  }

  /// Private method to send email to individual seller
  static Future<bool> _sendSellerOrderEmail({
    required String sellerId,
    required List<CartItem> items,
    required Map<String, dynamic> customer,
    required Address shippingAddress,
    required String ordId,
    required String paymentMethod,
    required String txnId,
  }) async {
    try {
      // Get seller email
      final sellerEmail = await SellerService.getSellerEmail(sellerId);

      if (sellerEmail == null) {
        debugPrint("❌ No email found for seller ID: $sellerId");
        return false;
      }

      // Prepare order details message
      final customerName = customer['name'] ?? 'Customer';
      final customerEmail = customer['email'] ?? 'Not provided';
      final customerPhone = customer['phone'] ?? 'Not provided';

      String orderDetails = "<html><body>";
      orderDetails += "<h2>Dear Seller,</h2>";
      orderDetails +=
          "<p>🎉 You have received a new order from <strong>$customerName</strong>!</p>";

      orderDetails += "<h3>📋 CUSTOMER DETAILS</h3>";
      orderDetails +=
          "<div style='background-color: #f0f8ff; padding: 10px; border-radius: 5px; margin: 10px 0;'>";
      orderDetails += "<p><strong>Name:</strong> $customerName<br>";
      orderDetails += "<strong>Email:</strong> $customerEmail<br>";
      orderDetails += "<strong>Phone:</strong> $customerPhone</p>";
      orderDetails += "</div>";

      orderDetails += "<h3>📦 SHIPPING ADDRESS</h3>";
      orderDetails +=
          "<div style='background-color: #f9f9f9; padding: 10px; border-left: 4px solid #28a745; margin: 10px 0;'>";
      orderDetails += "<p>${shippingAddress.first} ${shippingAddress.last}<br>";
      orderDetails += "${shippingAddress.line1}<br>";
      if (shippingAddress.line2.isNotEmpty) {
        orderDetails += "${shippingAddress.line2}<br>";
      }
      orderDetails +=
          "${shippingAddress.city}, ${shippingAddress.state} - ${shippingAddress.pincode}</p>";
      orderDetails += "</div>";

      orderDetails += "<h3>🛍️ ORDERED PRODUCTS</h3>";
      orderDetails += "<p><strong>Order ID:</strong> $ordId</p>";

      // Create HTML table for products with quantities
      orderDetails +=
          "<table border='1' cellpadding='8' cellspacing='0' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
      orderDetails +=
          "<thead style='background-color: #28a745; color: white;'>";
      orderDetails +=
          "<tr><th style='text-align: left; padding: 10px;'>Product Name</th><th style='text-align: center; padding: 10px;'>Quantity</th><th style='text-align: right; padding: 10px;'>Unit Price</th><th style='text-align: right; padding: 10px;'>Total</th></tr>";
      orderDetails += "</thead><tbody>";

      double totalAmount = 0;
      for (final item in items) {
        final itemTotal = item.product.price * item.quantity;
        orderDetails += "<tr>";
        orderDetails +=
            "<td style='padding: 8px; border-bottom: 1px solid #ddd;'>${item.product.name}</td>";
        orderDetails +=
            "<td style='padding: 8px; text-align: center; border-bottom: 1px solid #ddd;'>${item.quantity}</td>";
        orderDetails +=
            "<td style='padding: 8px; text-align: right; border-bottom: 1px solid #ddd;'>₹${item.product.price.toStringAsFixed(2)}</td>";
        orderDetails +=
            "<td style='padding: 8px; text-align: right; border-bottom: 1px solid #ddd;'>₹${itemTotal.toStringAsFixed(2)}</td>";
        orderDetails += "</tr>";
        totalAmount += itemTotal;
      }

      orderDetails += "</tbody></table>";
      orderDetails +=
          "<p><strong>💰 TOTAL AMOUNT: ₹${totalAmount.toStringAsFixed(2)}</strong></p>";
      orderDetails += "<p><strong>Payment Method:</strong> $paymentMethod<br>";
      orderDetails += "<strong>Transaction ID:</strong> $txnId</p>";

      orderDetails += "<hr style='margin: 20px 0;'>";
      orderDetails += "<h4>📞 Next Steps:</h4>";
      orderDetails +=
          "<p>Please process this order and contact the customer if needed.</p>";
      orderDetails +=
          "<div style='background-color: #fff3cd; padding: 10px; border-radius: 5px; border-left: 4px solid #ffc107;'>";
      orderDetails +=
          "<p><strong>📧 Customer Email:</strong> $customerEmail<br>";
      orderDetails += "<strong>📱 Customer Phone:</strong> $customerPhone</p>";
      orderDetails += "</div>";
      orderDetails +=
          "<p><strong>Thank you for using our platform! 🙏</strong></p>";
      orderDetails += "</body></html>";

      // Send email to seller
      final success = await sendEmail(
        to: sellerEmail,
        subject: "🆕 New Order Received - Order from $customerName",
        message: orderDetails,
      );

      if (success) {
        debugPrint("✅ Order details sent to seller: $sellerEmail");
        return true;
      } else {
        debugPrint("❌ Failed to send order to seller: $sellerEmail");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error sending order to seller $sellerId: $e");
      return false;
    }
  }

  /// Send multiple emails at once (utility method)
  static Future<List<bool>> sendMultipleEmails(
    List<Map<String, String>> emails,
  ) async {
    List<bool> results = [];

    for (final emailData in emails) {
      final result = await sendEmail(
        to: emailData['to']!,
        subject: emailData['subject']!,
        message: emailData['message']!,
      );
      results.add(result);
    }

    return results;
  }

  /// Enhanced stock availability check with quantity limits
  static Future<Map<String, dynamic>> checkStockAvailability({
    required List<CartItem> items,
  }) async {
    try {
      debugPrint(
        '🔍 Checking stock availability and quantity limits for ${items.length} items...',
      );

      // Note: Quantity limits should be validated at UI level before reaching this point

      List<Map<String, dynamic>> unavailableItems = [];
      bool allAvailable = true;

      for (final item in items) {
        try {
          // Try multiple field names to find the product
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('name', isEqualTo: item.product.name)
              .limit(1)
              .get();

          // If not found by name, try pid
          if (querySnapshot.docs.isEmpty && item.product.pid.isNotEmpty) {
            querySnapshot = await FirebaseFirestore.instance
                .collection('products')
                .where('pid', isEqualTo: item.product.pid)
                .limit(1)
                .get();
          }

          if (querySnapshot.docs.isNotEmpty) {
            final productDoc = querySnapshot.docs.first;
            final productData = productDoc.data() as Map<String, dynamic>;
            final currentStock = productData['stockQuantity'] ?? 0;

            if (currentStock < item.quantity) {
              allAvailable = false;
              unavailableItems.add({
                'product': item.product.name,
                'category': item.product.category,
                'requested': item.quantity,
                'available': currentStock,
                'type': 'insufficient_stock',
              });
              debugPrint(
                '❌ Insufficient stock: ${item.product.name} (Requested: ${item.quantity}, Available: $currentStock)',
              );
            } else {
              debugPrint(
                '✅ Stock available: ${item.product.name} (Requested: ${item.quantity}, Available: $currentStock)',
              );
            }
          } else {
            allAvailable = false;
            unavailableItems.add({
              'product': item.product.name,
              'category': item.product.category,
              'requested': item.quantity,
              'available': 0,
              'type': 'product_not_found',
              'error': 'Product not found',
            });
            debugPrint('❌ Product not found: ${item.product.name}');
          }
        } catch (e) {
          debugPrint('❌ Error checking stock for ${item.product.name}: $e');
          allAvailable = false;
          unavailableItems.add({
            'product': item.product.name,
            'category': item.product.category,
            'requested': item.quantity,
            'available': 0,
            'type': 'error',
            'error': e.toString(),
          });
        }
      }

      return {
        'available': allAvailable,
        'unavailableItems': unavailableItems,
        'quantityLimitsChecked': true,
      };
    } catch (e) {
      debugPrint('❌ Error checking stock availability: $e');
      return {
        'available': false,
        'unavailableItems': [],
        'error': e.toString(),
      };
    }
  }

  /// Update stock quantities in Firestore after order placement
  static Future<bool> updateStockQuantities({
    required List<CartItem> orderedItems,
    required String orderId,
  }) async {
    try {
      debugPrint('📦 Updating stock quantities for order: $orderId');

      // Use batch write for atomic updates
      final batch = FirebaseFirestore.instance.batch();
      int successfulUpdates = 0;

      for (final item in orderedItems) {
        try {
          debugPrint('🔍 Looking for product: ${item.product.name}');

          // Try multiple field names to find the product
          QuerySnapshot querySnapshot;

          // First try with 'name' field
          querySnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('name', isEqualTo: item.product.name)
              .limit(1)
              .get();

          // If not found, try with other possible field names
          if (querySnapshot.docs.isEmpty) {
            debugPrint(
              '🔍 Product not found by name, trying pid: ${item.product.pid}',
            );
            querySnapshot = await FirebaseFirestore.instance
                .collection('products')
                .where('pid', isEqualTo: item.product.pid)
                .limit(1)
                .get();
          }

          if (querySnapshot.docs.isNotEmpty) {
            final productDoc = querySnapshot.docs.first;
            final productData = productDoc.data() as Map<String, dynamic>;

            debugPrint('📋 Found product document: ${productDoc.id}');
            debugPrint('📋 Product data fields: ${productData.keys.toList()}');

            final currentStock = productData['stockQuantity'] ?? 0;
            final newStock = (currentStock - item.quantity)
                .clamp(0, double.infinity)
                .toInt();

            debugPrint('📊 Product: ${item.product.name}');
            debugPrint('   Document ID: ${productDoc.id}');
            debugPrint('   Current Stock: $currentStock');
            debugPrint('   Ordered Quantity: ${item.quantity}');
            debugPrint('   New Stock: $newStock');

            // Validate that the stock won't go negative
            if (currentStock >= item.quantity) {
              // Add update operation to batch
              batch.update(productDoc.reference, {
                'stockQuantity': newStock,
                'lastUpdated': FieldValue.serverTimestamp(),
              });
              successfulUpdates++;
              debugPrint('✅ Added to batch: ${item.product.name}');
            } else {
              debugPrint(
                '⚠️ Insufficient stock for ${item.product.name}: Available=$currentStock, Requested=${item.quantity}',
              );
            }
          } else {
            debugPrint('❌ Product not found in database: ${item.product.name}');
            debugPrint('   Tried fields: name, pid');
            debugPrint(
              '   Product details: name=${item.product.name}, pid=${item.product.pid}',
            );
          }
        } catch (e) {
          debugPrint('❌ Error processing item ${item.product.name}: $e');
        }
      }

      if (successfulUpdates > 0) {
        // Commit all updates atomically
        await batch.commit();
        debugPrint(
          '✅ Stock quantities updated successfully for $successfulUpdates items in order: $orderId',
        );
        return true;
      } else {
        debugPrint('❌ No stock updates were made for order: $orderId');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating stock quantities: $e');
      return false;
    }
  }
}

Future<void> placeOrder(Map<String, dynamic> customer, Address address) async {
  // Get cart items before clearing
  final cartItems = Cart.instance.items;
  final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';

  debugPrint('📦 Processing order: $orderId');

  // Step 1: Check stock availability AND quantity limits
  final stockCheck = await EmailService.checkStockAvailability(
    items: cartItems,
  );

  if (!stockCheck['available']) {
    // Handle stock availability issues
    debugPrint('❌ Order cannot be placed - insufficient stock');
    final unavailableItems =
        stockCheck['unavailableItems'] as List<Map<String, dynamic>>;

    String errorMessage = 'Cannot place order due to:\n\n';
    for (final item in unavailableItems) {
      if (item['type'] == 'insufficient_stock') {
        errorMessage +=
            '• ${item['product']}: Only ${item['available']} available (requested ${item['requested']})\n';
      } else if (item['type'] == 'product_not_found') {
        errorMessage += '• ${item['product']}: Product not found\n';
      }
    }

    throw Exception(errorMessage);
  }

  // Step 2: Update stock quantities
  final stockUpdated = await EmailService.updateStockQuantities(
    orderedItems: cartItems,
    orderId: orderId,
  );

  if (!stockUpdated) {
    debugPrint('⚠️ Warning: Stock quantities may not have been updated properly');
  }

  // Step 3: Send order details to sellers
  try {
    await EmailService.sendOrderDetailsToSellers(
      customer: customer,
      shippingAddress: address,
      ordId: orderId,
      paymentMethod: 'COD',
      txnId: 'N/A',
    );
  } catch (e) {
    debugPrint('⚠️ Warning: Failed to send seller notifications: $e');
  }

  // Step 4: Send customer confirmation
  try {
    await EmailService.sendCustomerConfirmationEmail(
      customerEmail: customer['email'] ?? '',
      customerName: customer['name'] ?? 'Customer',
      shippingAddress: address,
      orderedItems: cartItems,
      ordId: orderId,
      paymentMethod: 'COD',
      txnId: 'N/A',
    );
  } catch (e) {
    debugPrint('⚠️ Warning: Failed to send customer confirmation: $e');
  }

  // Step 5: Clear cart only after successful order placement
  Cart.instance.clear();
  debugPrint('✅ Order placed successfully: $orderId');
}
