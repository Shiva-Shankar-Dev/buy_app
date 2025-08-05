import 'package:flutter/material.dart';
import 'package:buy_app/screens/payments/payment_completed_page.dart';
import 'dart:math';
import 'package:intl/intl.dart';

String generateTxnIdCard() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyyMMddHHmmss');
  final timestamp = formatter.format(now);

  final random = Random();
  final randomNumber = random.nextInt(9000) + 1000;

  return 'Card-$timestamp-$randomNumber';
}

class PaymentCardPage extends StatefulWidget {
  final Map<String, dynamic> customer;
  final dynamic address; // Replace with your Address type

  const PaymentCardPage({
    super.key,
    required this.customer,
    required this.address,
  });

  @override
  State<PaymentCardPage> createState() => _PaymentCardPageState();
}

class _PaymentCardPageState extends State<PaymentCardPage> {
  String _cardNumber = '';
  String _expiryMonth = '';
  String _expiryYear = '';
  String _cvv = '';
  bool _isPaying = false;

  bool get isValid =>
      _cardNumber.length == 16 &&
      _expiryMonth.length == 2 &&
      _expiryYear.length == 2 &&
      _cvv.length == 3 &&
      int.tryParse(_expiryMonth) != null &&
      int.tryParse(_expiryYear) != null &&
      int.parse(_expiryMonth) >= 1 &&
      int.parse(_expiryMonth) <= 12;

  void _proceedToPay() async {
    setState(() => _isPaying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentCompletedPage(
          message: "Payment Completed!\nRedirecting to Order Page...",
          paymentMethod: "Card Payment",
          txnId: generateTxnIdCard(),
          customer: widget.customer,
          address: widget.address,
          shouldSendEmails: true, // Explicitly enable email sending
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Card Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Enter Card Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Card Number Field
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Card Number",
                  hintText: "1234 5678 9012 3456",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Icon(
                    Icons.credit_card,
                    color: Colors.grey.shade600,
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 16,
                onChanged: (val) =>
                    setState(() => _cardNumber = val.replaceAll(' ', '')),
              ),
            ),

            const SizedBox(height: 16),

            // Expiry and CVV Row
            Row(
              children: [
                // Expiry Month
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "MM",
                        hintText: "12",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Icon(
                          Icons.calendar_month,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      onChanged: (val) => setState(() => _expiryMonth = val),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Expiry Year
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "YY",
                        hintText: "24",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      onChanged: (val) => setState(() => _expiryYear = val),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // CVV
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "CVV",
                        hintText: "123",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Icon(
                          Icons.security,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                      onChanged: (val) => setState(() => _cvv = val),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Payment Button
            _isPaying
                ? Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          "Processing payment...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isValid ? _proceedToPay : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isValid ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isValid ? 3 : 0,
                      ),
                      child: Text(
                        "Proceed to Pay",
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
