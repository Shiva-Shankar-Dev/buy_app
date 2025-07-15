import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/seller_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/screens/home_page.dart'; // For Product model

class EmailService {
  static const String _emailServerUrl = 'http://localhost:3000/send';

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
        print('✅ Email sent successfully to: $to');
        return true;
      } else {
        print('❌ Failed to send email: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Email exception: $e');
      return false;
    }
  }

  /// Send order confirmation email to customer
  static Future<bool> sendCustomerConfirmationEmail({
    required String customerEmail,
    required String customerName,
    required Address shippingAddress,
    required List<Product> orderedProducts,
  }) async {
    double totalAmount = orderedProducts.fold(
      0.0,
      (sum, product) => sum + product.price,
    );

    String message = "Dear $customerName,\n\n";
    message += "Your order has been successfully placed!\n\n";
    message += "ORDER SUMMARY:\n";

    for (final product in orderedProducts) {
      message += "- ${product.title} - ₹${product.price.toStringAsFixed(2)}\n";
    }

    message += "\nTOTAL AMOUNT: ₹${totalAmount.toStringAsFixed(2)}\n\n";
    message += "SHIPPING ADDRESS:\n";
    message += "${shippingAddress.first} ${shippingAddress.last}\n";
    message += "${shippingAddress.line1}\n";
    if (shippingAddress.line2.isNotEmpty) {
      message += "${shippingAddress.line2}\n";
    }
    message +=
        "${shippingAddress.city}, ${shippingAddress.state} - ${shippingAddress.pincode}\n\n";
    message +=
        "Your order will be processed soon. You will receive updates via email and SMS.\n\n";
    message += "Thank you for shopping with us!";

    return await sendEmail(
      to: customerEmail,
      subject: "Order Confirmation - Your order has been placed!",
      message: message,
    );
  }

  /// Send order details to sellers
  static Future<void> sendOrderDetailsToSellers({
    required Map<String, dynamic> customer,
    required Address shippingAddress,
  }) async {
    final cart = Cart.instance;

    if (cart.items.isEmpty) {
      print("❌ No items in cart to send to sellers");
      return;
    }

    // Group products by seller ID
    Map<String?, List<Product>> productsBySeller = {};
    for (final product in cart.items) {
      final sellerId = product.sellerId;
      if (productsBySeller[sellerId] == null) {
        productsBySeller[sellerId] = [];
      }
      productsBySeller[sellerId]!.add(product);
    }

    print("📊 Found ${productsBySeller.length} sellers to notify");

    // Send email to each seller
    for (final entry in productsBySeller.entries) {
      final sellerId = entry.key;
      final products = entry.value;

      if (sellerId == null) {
        print("⚠️ Product without seller ID found, skipping...");
        continue;
      }

      await _sendSellerOrderEmail(
        sellerId: sellerId,
        products: products,
        customer: customer,
        shippingAddress: shippingAddress,
      );
    }
  }

  /// Private method to send email to individual seller
  static Future<void> _sendSellerOrderEmail({
    required String sellerId,
    required List<Product> products,
    required Map<String, dynamic> customer,
    required Address shippingAddress,
  }) async {
    try {
      // Get seller email
      final sellerEmail = await SellerService.getSellerEmail(sellerId);

      if (sellerEmail == null) {
        print("❌ No email found for seller ID: $sellerId");
        return;
      }

      // Prepare order details message
      final customerName = customer['name'] ?? 'Customer';
      final customerEmail = customer['email'] ?? 'Not provided';
      final customerPhone = customer['phone'] ?? 'Not provided';

      String orderDetails = "Dear Seller,\n\n";
      orderDetails +=
          "🎉 You have received a new order from $customerName!\n\n";
      orderDetails += "📋 CUSTOMER DETAILS:\n";
      orderDetails += "Name: $customerName\n";
      orderDetails += "Email: $customerEmail\n";
      orderDetails += "Phone: $customerPhone\n\n";
      orderDetails += "📦 SHIPPING ADDRESS:\n";
      orderDetails += "${shippingAddress.first} ${shippingAddress.last}\n";
      orderDetails += "${shippingAddress.line1}\n";
      if (shippingAddress.line2.isNotEmpty) {
        orderDetails += "${shippingAddress.line2}\n";
      }
      orderDetails +=
          "${shippingAddress.city}, ${shippingAddress.state} - ${shippingAddress.pincode}\n\n";
      orderDetails += "🛍️ ORDERED PRODUCTS:\n";

      double totalAmount = 0;
      for (final product in products) {
        orderDetails +=
            "• ${product.title} - ₹${product.price.toStringAsFixed(2)}\n";
        totalAmount += product.price;
      }

      orderDetails +=
          "\n💰 TOTAL AMOUNT: ₹${totalAmount.toStringAsFixed(2)}\n\n";
      orderDetails +=
          "📞 Please process this order and contact the customer if needed.\n";
      orderDetails += "📧 Customer Email: $customerEmail\n";
      orderDetails += "📱 Customer Phone: $customerPhone\n\n";
      orderDetails += "Thank you for using our platform! 🙏";

      // Send email to seller
      final success = await sendEmail(
        to: sellerEmail,
        subject: "🆕 New Order Received - Order from $customerName",
        message: orderDetails,
      );

      if (success) {
        print("✅ Order details sent to seller: $sellerEmail");
      } else {
        print("❌ Failed to send order to seller: $sellerEmail");
      }
    } catch (e) {
      print("❌ Error sending order to seller $sellerId: $e");
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
}
