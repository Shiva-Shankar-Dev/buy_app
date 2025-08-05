import 'package:flutter/material.dart';
import 'package:buy_app/screens/payments/payment_completed_page.dart';
import 'dart:math';
import 'package:intl/intl.dart';

String generateTxnIdUPI() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyyMMddHHmmss');
  final timestamp = formatter.format(now);

  final random = Random();
  final randomNumber = random.nextInt(9000) + 1000;

  return 'UPI-$timestamp-$randomNumber';
}

class PaymentUpiPage extends StatefulWidget {
  final Map<String, dynamic> customer;
  final dynamic address; // Replace with your Address type

  const PaymentUpiPage({
    super.key,
    required this.customer,
    required this.address,
  });

  @override
  State<PaymentUpiPage> createState() => _PaymentUpiPageState();
}

class _PaymentUpiPageState extends State<PaymentUpiPage> {
  String? _selectedApp;
  String _upiId = '';
  bool _isPaying = false;

  bool get isValid => _selectedApp != null || _upiId.trim().isNotEmpty;

  void _proceedToPay() async {
    setState(() => _isPaying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentCompletedPage(
          message: "Payment Completed!\nRedirecting to Order Page...",
          paymentMethod: "UPI Payment",
          txnId: generateTxnIdUPI(),
          customer: widget.customer,
          address: widget.address,
          shouldSendEmails: true, // Explicitly enable email sending
        ),
      ),
    );
  }

  Widget _buildLogo(String appName, IconData fallbackIcon, Color color) {
    // Map app names to PNG file names
    final Map<String, String> logoFiles = {
      'GPay': 'gpay_logo.png',
      'PhonePe': 'phonepe_logo.png',
      'BHIM': 'bhim_logo.png',
    };

    final logoFile = logoFiles[appName];
    if (logoFile == null) {
      return Icon(fallbackIcon, color: color, size: 28);
    }

    final logoPath = 'assets/logos/$logoFile';

    return Image.asset(
      logoPath,
      width: 28,
      height: 28,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if logo fails to load
        return Icon(fallbackIcon, color: color, size: 28);
      },
    );
  }

  Widget _buildUpiOption(String appName, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedApp == appName ? color : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _selectedApp == appName ? color.withOpacity(0.1) : Colors.white,
      ),
      child: ListTile(
        title: Text(
          appName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _selectedApp == appName ? color : Colors.black87,
          ),
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: _buildLogo(appName, icon, color),
            ),
            const SizedBox(width: 12),
            Radio<String>(
              value: appName,
              groupValue: _selectedApp,
              onChanged: (val) => setState(() => _selectedApp = val),
              activeColor: color,
            ),
          ],
        ),
        onTap: () => setState(() => _selectedApp = appName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("UPI Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Choose UPI App",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildUpiOption('GPay', Icons.payment, Colors.blue),
            _buildUpiOption('PhonePe', Icons.phone_android, Colors.purple),
            _buildUpiOption('BHIM', Icons.account_balance, Colors.orange),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              "Or Enter UPI ID",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelText: "Enter UPI ID (e.g., 9876543210@paytm)",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Icon(
                    Icons.alternate_email,
                    color: Colors.grey.shade600,
                  ),
                ),
                onChanged: (val) => setState(() => _upiId = val),
              ),
            ),
            const SizedBox(height: 32),
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
