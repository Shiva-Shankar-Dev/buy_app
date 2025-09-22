import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/services/sms_service.dart';
import 'package:buy_app/services/email_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/widgets/normal_button.dart';
import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

String generateOrderId() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyyMMddHHmmss');
  final timestamp = formatter.format(now);

  final random = Random();
  final randomNumber = random.nextInt(9000) + 1000;

  return 'ORD-$timestamp-$randomNumber';
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? customer;
  Address? address;
  String? _selectedPaymentMode = 'COD';
  bool _isProcessing = false;

  // Fix: Use item.product.price instead of item.price
  double get totalAmount => Cart.instance.items.fold(
    0.0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );

  @override
  void initState() {
    super.initState();
    loadCustomer();
    _selectedPaymentMode = 'COD';
  }

  String formatPhoneNumber(String rawPhone) {
    String digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.startsWith('91') && digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(2);
    }
    return digitsOnly;
  }

  void loadCustomer() async {
    final data = await _authService.getUserDetailsAsMap();
    if (data == null) return;
    setState(() {
      customer = data;
    });
  }

  Future<void> _sendOrderNotifications() async {
    final cart = Cart.instance;
    final email = customer!['email'];
    final name = customer!['name'] ?? 'Customer';
    final phone = formatPhoneNumber(customer?['phone'] ?? '');
    final paymentMethod = _selectedPaymentMode ?? 'COD';

    try {
      final ordId = generateOrderId();
      final txnId = paymentMethod == 'COD' ? 'N/A' : ordId;

      // 1. Send confirmation email to customer
      // Fix: Use orderedItems instead of orderedProducts
      await EmailService.sendCustomerConfirmationEmail(
        customerEmail: email,
        customerName: name,
        shippingAddress: address!,
        orderedItems: cart.items, // Changed from orderedProducts
        ordId: ordId,
        paymentMethod: paymentMethod,
        txnId: txnId,
      );

      // 2. Send order details to sellers
      await EmailService.sendOrderDetailsToSellers(
        customer: customer!,
        shippingAddress: address!,
        ordId: ordId,
        paymentMethod: paymentMethod,
        txnId: txnId,
      );

      // 3. Send SMS to customer
      if (phone.isNotEmpty) {
        await sendSMS(
          phone,
          "$name,\nYour Order has been placed!\n\nShipping Address:\n"
          "${address!.line1}, ${address!.line2},\n"
          "${address!.city}, ${address!.state} - ${address!.pincode}",
        );
      }

      // 4. Clear cart after notifications
      print('🛒 Clearing cart after notifications sent successfully');
      cart.clear();
      print('🛒 Cart cleared. Items count: ${cart.items.length}');
    } catch (e) {
      print("❌ Error sending notifications: $e");
      // Clear cart even on error to prevent duplicate orders
      cart.clear();
    }
  }

  void _handlePayment() async {
    if (_selectedPaymentMode == null) return;
    setState(() => _isProcessing = true);

    if (_selectedPaymentMode == 'COD') {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            isCOD: true,
            sendNotifications: _sendOrderNotifications,
          ),
        ),
      );
    } else if (_selectedPaymentMode == 'UPI') {
      setState(() => _isProcessing = false);
      Navigator.of(context).pushNamed(
        '/payment_upi',
        arguments: {'customer': customer, 'address': address},
      );
      return;
    } else if (_selectedPaymentMode == 'Card') {
      setState(() => _isProcessing = false);
      Navigator.of(context).pushNamed(
        '/payment_card',
        arguments: {'customer': customer, 'address': address},
      );
      return;
    } else {
      await Future.delayed(Duration(seconds: 2));
      setState(() => _isProcessing = false);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            isCOD: false,
            sendNotifications: _sendOrderNotifications,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    address ??= ModalRoute.of(context)?.settings.arguments as Address?;

    if (customer == null || address == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Payment Details'),
          backgroundColor: colorPallete.color1,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
        backgroundColor: colorPallete.color1,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Items: ${Cart.instance.totalItems}'),
                    Text(
                      'Total: ₹${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorPallete.color1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Payment Options
            Text(
              "Select Payment Method:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text("Cash on Delivery (COD)"),
                    subtitle: Text("Pay when you receive"),
                    leading: Radio<String>(
                      value: 'COD',
                      groupValue: _selectedPaymentMode,
                      onChanged: (val) =>
                          setState(() => _selectedPaymentMode = val),
                    ),
                    trailing: Icon(Icons.local_shipping),
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text("UPI Payment"),
                    subtitle: Text("Pay using UPI apps"),
                    leading: Radio<String>(
                      value: 'UPI',
                      groupValue: _selectedPaymentMode,
                      onChanged: (val) =>
                          setState(() => _selectedPaymentMode = val),
                    ),
                    trailing: Icon(Icons.account_balance_wallet),
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text("Credit/Debit Card"),
                    subtitle: Text("Pay using card"),
                    leading: Radio<String>(
                      value: 'Card',
                      groupValue: _selectedPaymentMode,
                      onChanged: (val) =>
                          setState(() => _selectedPaymentMode = val),
                    ),
                    trailing: Icon(Icons.credit_card),
                  ),
                ],
              ),
            ),

            Spacer(),

            // Payment Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPallete.color1,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _selectedPaymentMode == 'COD'
                            ? 'Place Order'
                            : 'Pay ₹${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderSuccessPage extends StatefulWidget {
  final bool isCOD;
  final Future<void> Function()? sendNotifications;

  const OrderSuccessPage({
    super.key,
    required this.isCOD,
    this.sendNotifications,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  @override
  void initState() {
    super.initState();
    if (widget.sendNotifications != null) {
      widget.sendNotifications!();
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });
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
              widget.isCOD
                  ? "Order Placed Successfully!"
                  : "Payment Successful!\nOrder Placed Successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Thank you for your order!",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: colorPallete.color1),
            SizedBox(height: 10),
            Text(
              "Redirecting to Home...",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
