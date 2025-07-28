import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/services/sms_service.dart';
import 'package:buy_app/services/email_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/widgets/normal_button.dart';
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
  String? _selectedPaymentMode = 'COD'; // Default to COD
  bool _isProcessing = false;

  double get totalAmount =>
      Cart.instance.items.fold(0.0, (sum, item) => sum + item.price);

  @override
  void initState() {
    super.initState();
    loadCustomer();
    _selectedPaymentMode = 'COD'; // Set default payment mode
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
    final phone = formatPhoneNumber(customer?['phone']);
    final paymentMethod = _selectedPaymentMode ?? 'COD';

    try {
      // Generate consistent Order ID and Transaction ID
      final ordId = generateOrderId();
      final txnId = paymentMethod == 'COD' ? 'N/A' : ordId;

      // 1. Send confirmation email to customer
      await EmailService.sendCustomerConfirmationEmail(
        customerEmail: email,
        customerName: name,
        shippingAddress: address!,
        orderedProducts: cart.items,
        ordId: ordId,
        paymentMethod: paymentMethod,
        txnId: txnId,
      );

      // 2. Send order details to all relevant sellers
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

      // 4. Clear the cart **after** all notifications are sent successfully
      print('🛒 Clearing cart after notifications sent successfully');
      cart.clear();
      print('🛒 Cart cleared. Items count: ${cart.items.length}');
    } catch (e) {
      cart.clear();
      print("❌ Error sending notifications: $e");
      // Do NOT clear the cart here!
    }
  }

  void _handlePayment() async {
    if (_selectedPaymentMode == null) return;
    setState(() => _isProcessing = true);

    // Simulate payment delay for non-COD
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
      Navigator.of(context).pushNamed(
        '/payment_upi',
        arguments: {'customer': customer, 'address': address},
      );
      return;
    } else if (_selectedPaymentMode == 'Card') {
      Navigator.of(context).pushNamed(
        '/payment_card',
        arguments: {'customer': customer, 'address': address},
      );
      return;
    } else {
      await Future.delayed(Duration(seconds: 2)); // Simulate payment
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
    // Get address from arguments if not already set
    address ??= ModalRoute.of(context)?.settings.arguments as Address?;

    if (customer == null || address == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Payment Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Payment Details')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Total Amount: ₹${totalAmount.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Text("Select Payment Mode:", style: TextStyle(fontSize: 18)),
            ListTile(
              title: Text("Cash on Delivery (COD)"),
              leading: Radio<String>(
                value: 'COD',
                groupValue: _selectedPaymentMode,
                onChanged: (val) => setState(() => _selectedPaymentMode = val),
              ),
            ),
            ListTile(
              title: Text("UPI"),
              leading: Radio<String>(
                value: 'UPI',
                groupValue: _selectedPaymentMode,
                onChanged: (val) => setState(() => _selectedPaymentMode = val),
              ),
            ),
            ListTile(
              title: Text("Credit/Debit Card"),
              leading: Radio<String>(
                value: 'Card',
                groupValue: _selectedPaymentMode,
                onChanged: (val) => setState(() => _selectedPaymentMode = val),
              ),
            ),
            SizedBox(height: 24),
            _isProcessing
                ? CircularProgressIndicator()
                : NormalButton(
                    hintText: _selectedPaymentMode == 'COD'
                        ? 'Place Order'
                        : 'Pay & Place Order',
                    onPressed: _isProcessing ? () {} : _handlePayment,
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text(
              widget.isCOD
                  ? "Order Placed Successfully!"
                  : "Payment Successful\nOrder Placed Successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Redirecting to Home...", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
