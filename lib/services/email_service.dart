import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/seller_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/screens/home_page.dart'; // For Product model
//Code + Generate and save to database
import 'package:intl/intl.dart';
import 'dart:math';

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

    String message1 = "Dear $customerName,\n\n";
    message1 += "Your order has been successfully placed!\n\n";
    message1 += "ORDER SUMMARY:\n\n";
    message1 += "Order ID: $ordId\n\n";
    message1 += "Ordered Products:\n\n";
    for (final product in orderedProducts) {
      message1 += "- ${product.title} - ₹${product.price.toStringAsFixed(2)}\n";
    }

    message1 += "\nTOTAL AMOUNT: ₹${totalAmount.toStringAsFixed(2)}\n\n";
    message1 += "Payment Method: $paymentMethod\n\n";
    message1 += "Transaction ID: $txnId\n\n";
    message1 += "\n\nSHIPPING ADDRESS:\n";
    message1 += "${shippingAddress.first} ${shippingAddress.last}\n";
    message1 += "${shippingAddress.line1}\n";
    if (shippingAddress.line2.isNotEmpty) {
      message1 += "${shippingAddress.line2}\n";
    }

    // Use HTML line breaks for email formatting

    message1 +=
        "${shippingAddress.city}, ${shippingAddress.state} - ${shippingAddress.pincode}\n\n";
    message1 +=
        "\nYour order will be processed soon. You will receive updates via email and SMS.\n\n";
    message1 += "Thank you for shopping with us!";
    message1 = message1.replaceAll('\n', '<br>');
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
      orderDetails += "Order ID: $ordId\n\n";
      for (final product in products) {
        orderDetails +=
            "• ${product.title} - ₹${product.price.toStringAsFixed(2)}\n";
        totalAmount += product.price;
      }

      orderDetails +=
          "\n💰 TOTAL AMOUNT: ₹${totalAmount.toStringAsFixed(2)}\n\n";
      orderDetails += "Payment Method: $paymentMethod\n";
      orderDetails += "Transaction ID: $txnId\n\n";
      orderDetails +=
          "📞 Please process this order and contact the customer if needed.\n";
      orderDetails += "📧 Customer Email: $customerEmail\n";
      orderDetails += "📱 Customer Phone: $customerPhone\n\n";
      orderDetails += "Thank you for using our platform! 🙏";

      // Convert newlines to <br> for HTML emails
      orderDetails = orderDetails.replaceAll('\n', '<br>');

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
