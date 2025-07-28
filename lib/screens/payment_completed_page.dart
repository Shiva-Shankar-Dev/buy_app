import 'package:buy_app/services/auth.dart';
import 'package:buy_app/services/email_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/services/addresses.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

/// Generates a unique Order ID
String generateOrderId() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyyMMddHHmmss');
  final timestamp = formatter.format(now);

  final random = Random();
  final randomNumber = random.nextInt(9000) + 1000;

  return 'ORD-$timestamp-$randomNumber';
}

class PaymentCompletedPage extends StatefulWidget {
  final String message;
  final String paymentMethod;
  final String txnId;
  final Address address;
  final Map<String, dynamic> customer;
  final Future<void> Function()? sendNotifications;
  final bool shouldSendEmails;

  const PaymentCompletedPage({
    super.key,
    required this.message,
    required this.paymentMethod,
    required this.txnId,
    required this.address,
    required this.customer,
    this.sendNotifications,
    this.shouldSendEmails = true,
  });

  @override
  State<PaymentCompletedPage> createState() => _PaymentCompletedPageState();
}

class _PaymentCompletedPageState extends State<PaymentCompletedPage> {
  @override
  void initState() {
    super.initState();
    if (widget.shouldSendEmails) {
      widget.sendNotifications?.call() ?? _sendEmailNotifications();
    }
    // Remove the Future.delayed navigation from here!
  }

  Future<void> _sendEmailNotifications() async {
    final customer = widget.customer;
    final address = widget.address;
    final email = customer['email'];
    final name = customer['name'] ?? 'Customer';
    final cart = Cart.instance;

    final ordId = generateOrderId();

    print('📧 Sending confirmation email to customer...');
    final customerEmailSent = await EmailService.sendCustomerConfirmationEmail(
      customerEmail: email,
      customerName: name,
      shippingAddress: address,
      orderedProducts: cart.items,
      ordId: ordId,
      paymentMethod: widget.paymentMethod,
      txnId: widget.txnId,
    );

    print('📧 Sending order details to sellers...');
    print(
      '📊 Cart items with seller info: ${cart.items.map((p) => {'title': p.title, 'sellerId': p.sellerId}).toList()}',
    );
    final sellerEmailsSent = await EmailService.sendOrderDetailsToSellers(
      customer: customer,
      shippingAddress: address,
      ordId: ordId,
      paymentMethod: widget.paymentMethod,
      txnId: widget.txnId,
    );
    print('📧 Seller email sending completed. Success: $sellerEmailsSent');

    if (customerEmailSent) {
      print('✅ All emails sent successfully!');
      if (!mounted) return;

      String message = '✅ Order confirmed! Customer email sent.';
      if (sellerEmailsSent) {
        message = '✅ Order confirmed! Emails sent to you and sellers.';
      } else {
        message =
            '✅ Order confirmed! Customer email sent. ⚠️ Some seller emails failed.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: sellerEmailsSent ? Colors.green : Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      throw Exception('Failed to send customer confirmation email');
    }

    // Always clear the cart after attempting to send emails
    cart.clear();
    print('🛒 Cart cleared. Items count: ${cart.items.length}');

    // Now navigate away, but only if still mounted
    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
