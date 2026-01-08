import 'package:buy_app/services/email_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/order_service.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:buy_app/models/models.dart';
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
    final cartItems = List<CartItem>.from(
      Cart.instance.items,
    ); // Capture items immediately

    try {
      // First save the order (Must wait for this)
      await _saveOrderToDatabase();

      if (widget.shouldSendEmails) {
        // Send emails in background (Fire and forget)
        _sendEmailNotifications(cartItems); // Not awaited
      }

      // Clear cart immediately
      Cart.instance.clear();

      // Navigate to home after short delay for UI feedback
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      debugPrint('❌ Error processing order: $e');
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
    final cart = Cart.instance;

    try {
      final orderId = await OrderService.createOrder(
        cartItems: cart.items,
        totalAmount: cart.totalAmount,
        paymentMethod: widget.paymentMethod,
        shippingAddress: {
          'first': widget.address.first,
          'last': widget.address.last,
          'line1': widget.address.line1,
          'line2': widget.address.line2,
          'city': widget.address.city,
          'state': widget.address.state,
          'pincode': widget.address.pincode,
        },
      );

      if (orderId != null) {
        setState(() {
          _orderSaved = true;
          _orderId = orderId;
        });
        debugPrint('✅ Order saved to database: $orderId');
      } else {
        throw Exception('Failed to save order to database');
      }
    } catch (e) {
      debugPrint('❌ Error saving order: $e');
      rethrow;
    }
  }

  Future<void> _sendEmailNotifications(List<CartItem> cartItems) async {
    if (!_orderSaved || _orderId == null) {
      debugPrint('❌ Cannot send emails: Order not saved yet');
      return;
    }

    final customer = widget.customer;
    final address = widget.address;
    final email = customer['email'] ?? '';
    final name = customer['name'] ?? 'Customer';

    try {
      debugPrint('📧 Sending confirmation email to customer...');

      final customerEmailSent =
          await EmailService.sendCustomerConfirmationEmail(
            customerEmail: email,
            customerName: name,
            shippingAddress: address,
            orderedItems: cartItems, // Use captured items
            ordId: _orderId!,
            paymentMethod: widget.paymentMethod,
            txnId: widget.txnId,
          );

      debugPrint('📧 Sending PDF invoice to customer...');

      final invoiceEmailSent = await EmailService.sendOrderInvoiceEmail(
        customerEmail: email,
        customerName: name,
        shippingAddress: address,
        orderedItems: cartItems, // Use captured items
        orderId: _orderId!,
        paymentMethod: widget.paymentMethod,
        txnId: widget.txnId,
      );

      debugPrint('📧 Sending order details to sellers...');
      final sellerEmailsSent = await EmailService.sendOrderDetailsToSellers(
        customer: customer,
        shippingAddress: address,
        ordId: _orderId!,
        paymentMethod: widget.paymentMethod,
        txnId: widget.txnId,
        items: cartItems, // Passed required items
      );

      if (mounted) {
        String message;
        Color backgroundColor;

        if (customerEmailSent && invoiceEmailSent && sellerEmailsSent) {
          message =
              '✅ Order confirmed! Confirmation email, invoice PDF, and seller notifications sent.';
          backgroundColor = Colors.green;
        } else if (customerEmailSent && invoiceEmailSent) {
          message =
              '✅ Order confirmed! Customer emails and PDF invoice sent. ⚠️ Some seller emails failed.';
          backgroundColor = Colors.orange;
        } else if (customerEmailSent || invoiceEmailSent) {
          message = '✅ Order confirmed! Some email notifications sent.';
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
      debugPrint("❌ Error sending notifications: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed but email notifications failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    // Always clear the cart (redundant but safe) and navigate
    // Cart is already cleared in _processOrder, but we can verify
    // debugPrint('🛒 Cart cleared. Items count: ${cart.items.length}'); // cart variable removed

    // Navigate away after delay
    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
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
            CircularProgressIndicator(color: ColorPallete.color1),
          ],
        ),
      ),
    );
  }
}
