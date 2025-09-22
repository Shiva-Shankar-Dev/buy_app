import 'package:buy_app/services/auth.dart';
import 'package:buy_app/services/email_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/simple_order_service.dart'; // Use only this one
import 'package:buy_app/colorPallete/color_pallete.dart';
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
  bool _orderSaved = false;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _processOrder();
  }

  Future<void> _processOrder() async {
    try {
      // First save the order
      await _saveOrderToDatabase();

      // Then send notifications if needed
      if (widget.shouldSendEmails) {
        await _sendEmailNotifications();
      } else {
        // Just clear cart and navigate
        Cart.instance.clear();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      print('❌ Error processing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order processing failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveOrderToDatabase() async {
    final customer = widget.customer;
    final cart = Cart.instance;
    _orderId = generateOrderId();

    // Create order details map
    final orderDetails = {
      'paymentMethod': widget.paymentMethod,
      'txnId': widget.txnId,
      'items': cart.items
          .map(
            (item) => {
              'title': item.product.title,
              'price': item.product.price,
              'quantity': item.quantity,
              'description': item.product.description,
              'images': item.product.images,
            },
          )
          .toList(),
      'shippingAddress': {
        'first': widget.address.first,
        'last': widget.address.last,
        'line1': widget.address.line1,
        'line2': widget.address.line2,
        'city': widget.address.city,
        'state': widget.address.state,
        'pincode': widget.address.pincode,
      },
      'orderDate': DateTime.now().toIso8601String(),
    };

    try {
      final orderId = await SimpleOrderService.createOrder(
        customerEmail: customer['email'] ?? '',
        customerName: customer['name'] ?? 'Customer',
        totalAmount: cart.totalAmount,
        orderDetails: orderDetails,
      );

      if (orderId != null) {
        setState(() {
          _orderSaved = true;
          _orderId = orderId;
        });
        print('✅ Order saved to database: $orderId');
      } else {
        throw Exception('Failed to save order to database');
      }
    } catch (e) {
      print('❌ Error saving order: $e');
      throw e;
    }
  }

  Future<void> _sendEmailNotifications() async {
    if (!_orderSaved || _orderId == null) {
      print('❌ Cannot send emails: Order not saved yet');
      return;
    }

    final customer = widget.customer;
    final address = widget.address;
    final email = customer['email'] ?? '';
    final name = customer['name'] ?? 'Customer';
    final cart = Cart.instance;

    try {
      print('📧 Sending confirmation email to customer...');

      final customerEmailSent =
          await EmailService.sendCustomerConfirmationEmail(
            customerEmail: email,
            customerName: name,
            shippingAddress: address,
            orderedItems: cart.items,
            ordId: _orderId!,
            paymentMethod: widget.paymentMethod,
            txnId: widget.txnId,
          );

      print('📧 Sending order details to sellers...');
      final sellerEmailsSent = await EmailService.sendOrderDetailsToSellers(
        customer: customer,
        shippingAddress: address,
        ordId: _orderId!,
        paymentMethod: widget.paymentMethod,
        txnId: widget.txnId,
      );

      if (mounted) {
        String message;
        Color backgroundColor;

        if (customerEmailSent && sellerEmailsSent) {
          message = '✅ Order confirmed! Emails sent to you and sellers.';
          backgroundColor = Colors.green;
        } else if (customerEmailSent) {
          message =
              '✅ Order confirmed! Customer email sent. ⚠️ Some seller emails failed.';
          backgroundColor = Colors.orange;
        } else {
          message = '✅ Order saved but email notifications failed.';
          backgroundColor = Colors.orange;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print("❌ Error sending notifications: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed but email notifications failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // Always clear the cart and navigate
    cart.clear();
    print('🛒 Cart cleared. Items count: ${cart.items.length}');

    // Navigate away after delay
    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _orderSaved
                  ? "Order saved! Processing notifications..."
                  : "Saving your order...",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            if (_orderId != null) ...[
              SizedBox(height: 10),
              Text(
                "Order ID: ${_orderId!.substring(0, 12)}...",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            SizedBox(height: 30),
            CircularProgressIndicator(color: colorPallete.color1),
          ],
        ),
      ),
    );
  }
}
