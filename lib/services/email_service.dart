import 'dart:convert';
import 'package:buy_app/services/stock_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http;
import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/seller_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/services/pdf_service.dart';
import 'package:buy_app/models/models.dart'; // Import from models file
import 'package:buy_app/services/order_service.dart';

class EmailService {
  static const String _emailServerUrl = 'http://13.203.224.103:3000/send';

  // Alternative email services (uncomment to use)
  // static const String _emailServerUrl = 'https://formspree.io/f/YOUR_FORM_ID';
  // static const String _emailServerUrl = 'https://api.emailjs.com/api/v1.0/email/send';

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

        // Parse error response for better debugging
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error']?.contains('Missing credentials') == true) {
            debugPrint('💡 Server needs SMTP credentials configuration');
            debugPrint(
              '💡 Check your Vercel environment variables: EMAIL_USER, EMAIL_PASS',
            );
          }
        } catch (_) {
          // Ignore JSON parsing errors
        }

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
      (s, item) => s + (item.effectivePrice * item.quantity),
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
      final itemTotal = item.effectivePrice * item.quantity;
      message1 += "<tr>";
      message1 += "<td style='padding: 8px; border-bottom: 1px solid #ddd;'>";
      message1 += "<strong>${item.product.name}</strong>";

      // Add variant details if available
      if (item.selectedVariantId != null &&
          item.selectedAttributes != null &&
          item.selectedAttributes!.isNotEmpty) {
        message1 += "<br><small style='color: #666;'>";
        message1 += "<strong>Variant:</strong> ";
        message1 += item.selectedAttributes!.entries
            .map((e) => "${e.key}: ${e.value}")
            .join(", ");
        message1 += "</small>";
      }

      message1 += "</td>";
      message1 +=
          "<td style='padding: 8px; text-align: center; border-bottom: 1px solid #ddd;'>${item.quantity}</td>";
      message1 +=
          "<td style='padding: 8px; text-align: right; border-bottom: 1px solid #ddd;'>₹${item.effectivePrice.toStringAsFixed(2)}</td>";
      message1 +=
          "<td style='padding: 8px; text-align: right; border-bottom: 1px solid #ddd;'>₹${itemTotal.toStringAsFixed(2)}</td>";
      message1 += "</tr>";
    }

    message1 += "</tbody></table>";
    message1 +=
        "<p><strong>TOTAL AMOUNT: ₹${totalAmount.toStringAsFixed(2)}</strong></p>";
    message1 += "<p><strong>Payment Method:</strong> $paymentMethod</p>";
    message1 += "<p><strong>Transaction ID:</strong> $txnId</p>";
    message1 += "<p><strong>Order Status:</strong> Confirmed</p>";

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
      // For now, grouping all items together
      final sellerId = item.product.sellerId;
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
      orderDetails += "<p><strong>Order Status:</strong> Confirmed</p>";

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
        final itemTotal = item.effectivePrice * item.quantity;
        orderDetails += "<tr>";
        orderDetails +=
            "<td style='padding: 8px; border-bottom: 1px solid #ddd;'>";
        orderDetails += "<strong>${item.product.name}</strong>";

        // Add variant details if available
        if (item.selectedVariantId != null &&
            item.selectedAttributes != null &&
            item.selectedAttributes!.isNotEmpty) {
          orderDetails += "<br><small style='color: #666;'>";
          orderDetails += "<strong>Variant:</strong> ";
          orderDetails += item.selectedAttributes!.entries
              .map((e) => "${e.key}: ${e.value}")
              .join(", ");
          orderDetails += "</small>";
        }

        orderDetails += "</td>";
        orderDetails +=
            "<td style='padding: 8px; text-align: center; border-bottom: 1px solid #ddd;'>${item.quantity}</td>";
        orderDetails +=
            "<td style='padding: 8px; text-align: right; border-bottom: 1px solid #ddd;'>₹${item.effectivePrice.toStringAsFixed(2)}</td>";
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

  /// Automatically send PDF invoice email when order is placed
  static Future<bool> sendOrderInvoiceEmail({
    required String customerEmail,
    required String customerName,
    required Address shippingAddress,
    required List<CartItem> orderedItems,
    required String orderId,
    required String paymentMethod,
    required String txnId,
  }) async {
    try {
      debugPrint('📧 Generating and sending invoice email to: $customerEmail');

      // Generate PDF invoice using PdfService
      final pdfBytes = await PdfService.generateInvoicePDF(
        customerName: customerName,
        customerEmail: customerEmail,
        shippingAddress: shippingAddress,
        orderedItems: orderedItems,
        orderId: orderId,
        paymentMethod: paymentMethod,
        txnId: txnId,
      );

      // Convert to base64
      final pdfBase64 = base64Encode(pdfBytes);

      // Send email with PDF attachment
      final response = await http.post(
        Uri.parse('http://13.203.224.103:3000/send/receipt/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerEmail': customerEmail,
          'customerName': customerName,
          'orderId': orderId,
          'pdfBase64': pdfBase64,
          'pdfFileName': 'Invoice_$orderId.pdf',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Invoice email sent successfully');
        return true;
      } else {
        debugPrint(
          '❌ Failed to send invoice email: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending invoice email: $e');
      return false;
    }
  }
}

Future<void> placeOrder({
  required Map<String, dynamic> customer,
  required Address address,
  String paymentMethod = 'COD',
  String txnId = 'N/A',
}) async {
  final cartItems = Cart.instance.items;
  // removed early declaration of orderId

  try {
    debugPrint('📦 Processing new order...');

    // Step 1: Check stock availability for all items
    for (final item in cartItems) {
      final available = await StockService.checkStockAvailability(
        item.product.pid,
        item.quantity,
      );
      if (!available) {
        throw Exception('${item.product.name} is out of stock');
      }
    }
    debugPrint('✅ Stock availability verified');

    // Use OrderService to create order (handles DB storage in user_orders and stock decrement)
    final orderId = await OrderService.createOrder(
      cartItems: cartItems,
      totalAmount: Cart.instance.totalAmount,
      paymentMethod: paymentMethod,
      shippingAddress: {
        'first': address.first,
        'last': address.last,
        'line1': address.line1,
        'line2': address.line2,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
      },
    );

    if (orderId == null) {
      throw Exception('Failed to create order via OrderService');
    }
    debugPrint('✅ Order created via OrderService: $orderId');

    // Trigger background notifications (Fire and forget)
    _sendBackgroundNotifications(
      customer: customer,
      address: address,
      cartItems: List.from(cartItems), // Create a copy of the list
      orderId: orderId,
      paymentMethod: paymentMethod,
      txnId: txnId,
    );

    // Step 6: Clear cart after successful order (Immediate UI feedback)
    Cart.instance.clear();
    debugPrint('✅ Order placed successfully: $orderId');
  } catch (e) {
    debugPrint('❌ Order placement failed: $e');
    rethrow;
  }
}

/// Helper method to send notifications in background
Future<void> _sendBackgroundNotifications({
  required Map<String, dynamic> customer,
  required Address address,
  required List<CartItem> cartItems,
  required String orderId,
  required String paymentMethod,
  required String txnId,
}) async {
  debugPrint('🚀 Starting background notifications for order: $orderId');

  // Step 4: Send customer confirmation
  try {
    // TODO: Fix SMTP credentials on server before enabling
    debugPrint('📧 Skipping email (server credentials not configured)');
    /* 
      await EmailService.sendCustomerConfirmationEmail(
        customerEmail: customer['email'] ?? '',
        customerName: customer['name'] ?? 'Customer',
        shippingAddress: address,
        orderedItems: cartItems,
        ordId: orderId,
        paymentMethod: paymentMethod,
        txnId: txnId,
      );
      debugPrint('✅ Customer confirmation email sent');
      */

    // Send PDF invoice automatically
    await EmailService.sendOrderInvoiceEmail(
      customerEmail: customer['email'] ?? '',
      customerName: customer['name'] ?? 'Customer',
      shippingAddress: address,
      orderedItems: cartItems,
      orderId: orderId,
      paymentMethod: paymentMethod,
      txnId: txnId,
    );
    debugPrint('✅ PDF invoice email sent');
  } catch (e) {
    debugPrint('⚠️ Failed to send customer email: $e');
  }

  // Step 5: Send order to admin/sellers
  try {
    await EmailService.sendOrderDetailsToSellers(
      customer: customer,
      shippingAddress: address,
      ordId: orderId,
      paymentMethod: paymentMethod,
      txnId: txnId,
    );
    debugPrint('✅ Seller notifications sent');
  } catch (e) {
    debugPrint('⚠️ Failed to send seller notifications: $e');
  }
  debugPrint('🏁 Background notifications completed for order: $orderId');
}
