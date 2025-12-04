import 'package:flutter/material.dart';
import 'package:buy_app/screens/payments/payment_completed_page.dart';
import 'dart:math';
import 'package:intl/intl.dart';

String generateTxnIdCOD() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyyMMddHHmmss');
  final timestamp = formatter.format(now);

  final random = Random();
  final randomNumber = random.nextInt(9000) + 1000;

  return 'COD-$timestamp-$randomNumber';
}

class PaymentCodPage extends StatefulWidget {
  final Map<String, dynamic> customer;
  final dynamic address; // Replace with your Address type

  const PaymentCodPage({
    super.key,
    required this.customer,
    required this.address,
  });

  @override
  State<PaymentCodPage> createState() => _PaymentCodPageState();
}

class _PaymentCodPageState extends State<PaymentCodPage> {
  bool _isProcessing = false;

  void _completeOrder() async {
    debugPrint('🟢 Starting order completion process...');
    debugPrint('🟢 Customer Data: ${widget.customer}');
    debugPrint('🟢 Address Data: ${widget.address}');

    if (widget.customer.isEmpty || widget.address == null) {
      debugPrint('❌ Invalid customer or address data.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid customer or address data.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      debugPrint('🟢 Navigating to PaymentCompletedPage...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentCompletedPage(
            message: "Order Placed Successfully!\nRedirecting to Order Page...",
            paymentMethod: "Cash on Delivery",
            txnId: "COD",
            customer: widget.customer,
            address: widget.address,
            shouldSendEmails: true, // Explicitly enable email sending
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error navigating to PaymentCompletedPage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
      debugPrint('🟢 Order completion process finished.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cash on Delivery")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.money, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              "Cash on Delivery",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "You have chosen to pay with Cash on Delivery. Please keep the exact amount ready.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _isProcessing
                ? Column(
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Processing your order...",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _completeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        "Place Order",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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
