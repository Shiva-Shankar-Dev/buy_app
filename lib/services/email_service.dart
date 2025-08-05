import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/seller_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/screens/home_page.dart'; // For Product model
//Code + Generate and save to database

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
    required String ordId,
    required String paymentMethod,
    required String txnId,
  }) async {
    double totalAmount = orderedProducts.fold(
      0.0,
      (sum, product) => sum + product.price,
    );

    String message1 = "<html><body>";
    message1 += "<h2>Dear $customerName,</h2>";
    message1 += "<p>Your order has been successfully placed!</p>";
    message1 += "<h3>ORDER SUMMARY</h3>";
    message1 += "<p><strong>Order ID:</strong> $ordId</p>";

    // Create HTML table for products
    message1 += "<h4>Ordered Products:</h4>";
    message1 +=
        "<table border='1' cellpadding='8' cellspacing='0' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
    message1 += "<thead style='background-color: #f0f0f0;'>";
    message1 +=
        "<tr><th style='text-align: left; padding: 10px;'>Product Name</th><th style='text-align: right; padding: 10px;'>Price</th></tr>";
    message1 += "</thead><tbody>";

    for (final product in orderedProducts) {
      message1 += "<tr>";
      message1 +=
          "<td style='padding: 8px; border-bottom: 1px solid #ddd;'>${product.title}</td>";
      message1 +=
          "<td style='padding: 8px; text-align: right; border-bottom: 1px solid #ddd;'>₹${product.price.toStringAsFixed(2)}</td>";
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
      print("❌ No items in cart to send to sellers");
      return false;
    }

    print(
      "🛒 Cart items: ${cart.items.map((e) => {'title': e.title, 'sellerId': e.sellerId}).toList()}",
    );

    // Group products by seller ID
    Map<String?, List<Product>> productsBySeller = {};
    int productsWithoutSellerId = 0;

    for (final product in cart.items) {
      final sellerId = product.sellerId;
      if (sellerId == null || sellerId.isEmpty) {
        print(
          "⚠️ Product '${product.title}' without seller ID found, skipping...",
        );
        productsWithoutSellerId++;
        continue;
      }
      if (productsBySeller[sellerId] == null) {
        productsBySeller[sellerId] = [];
      }
      productsBySeller[sellerId]!.add(product);
    }

    if (productsWithoutSellerId > 0) {
      print("⚠️ Found $productsWithoutSellerId products without seller IDs");
    }

    if (productsBySeller.isEmpty) {
      print("❌ No products with valid seller IDs found");
      return false;
    }

    print("📊 Found ${productsBySeller.length} sellers to notify");

    bool allEmailsSent = true;
    // Send email to each seller
    for (final entry in productsBySeller.entries) {
      final sellerId = entry.key;
      final products = entry.value;

      if (sellerId == null || sellerId.isEmpty) {
        print("⚠️ Product without seller ID found in group, skipping...");
        continue;
      }

      print(
        "📧 Sending email to sellerId: $sellerId for products: ${products.map((e) => e.title).toList()}",
      );

      final success = await _sendSellerOrderEmail(
        sellerId: sellerId,
        products: products,
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
    required List<Product> products,
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
        print("❌ No email found for seller ID: $sellerId");
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

      // Create HTML table for products
      orderDetails +=
          "<table border='1' cellpadding='8' cellspacing='0' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
      orderDetails +=
          "<thead style='background-color: #28a745; color: white;'>";
      orderDetails +=
          "<tr><th style='text-align: left; padding: 10px;'>Product Name</th><th style='text-align: right; padding: 10px;'>Price</th></tr>";
      orderDetails += "</thead><tbody>";

      double totalAmount = 0;
      for (final product in products) {
        orderDetails += "<tr>";
        orderDetails +=
            "<td style='padding: 8px; border-bottom: 1px solid #ddd;'>${product.title}</td>";
        orderDetails +=
            "<td style='padding: 8px; text-align: right; border-bottom: 1px solid #ddd;'>₹${product.price.toStringAsFixed(2)}</td>";
        orderDetails += "</tr>";
        totalAmount += product.price;
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

      // Convert newlines to <br> for HTML emails

      // Send email to seller
      final success = await sendEmail(
        to: sellerEmail,
        subject: "🆕 New Order Received - Order from $customerName",
        message: orderDetails,
      );

      if (success) {
        print("✅ Order details sent to seller: $sellerEmail");
        return true;
      } else {
        print("❌ Failed to send order to seller: $sellerEmail");
        return false;
      }
    } catch (e) {
      print("❌ Error sending order to seller $sellerId: $e");
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
}

Future<void> placeOrder(Map<String, dynamic> customer, Address address) async {
  // ... existing order placement code ...

  await EmailService.sendOrderDetailsToSellers(
    customer: customer,
    shippingAddress: address,
    ordId: 'N/A',
    paymentMethod: 'COD', // Assuming COD for this example
    txnId: 'N/A', // No transaction ID for COD
  );
  Cart.instance.clear();
}
