import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/services/sms_service.dart';
import 'package:buy_app/widgets/normal_button.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? customer;
  late Address address;

  @override
  void initState() {
    super.initState();
    // Can't use ModalRoute.of(context) here yet — use addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      address = ModalRoute.of(context)!.settings.arguments as Address;
      loadCustomerAndSendSMS();
    });
  }

  String formatPhoneNumber(String rawPhone) {
    // Remove any non-digit characters
    String digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');

    // Remove leading country code (91) if present
    if (digitsOnly.startsWith('91') && digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(2); // Remove first 2 chars
    }

    return digitsOnly;
  }

  void loadCustomerAndSendSMS() async {
    final data = await _authService.getUserDetailsAsMap();
    if (data == null) return;

    setState(() {
      customer = data;
    });

    // Now send SMS after data is ready
    String? phone = formatPhoneNumber(customer?['phone']);
    String name = customer?['name'] ?? 'Customer';

    if (phone.isNotEmpty) {
      await sendSMS(
        phone,
        "$name,\nYour Order has been placed!\n\nShipping Address:\n"
        "${address.line1}, ${address.line2},\n"
        "${address.cityState} - ${address.pincode}",
      );
      print("SMS sent to $phone");
    } else {
      print("No phone number available.");
    }
  }

  Future<void> sendEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    final url = Uri.parse(
      'http://192.168.189.250:3000/send',
    ); // replace with your IP

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'to': to, 'subject': subject, 'text': message}),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully!');
      } else {
        print('❌ Failed to send email: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment Details')),
      body: Center(
        child: customer == null
            ? CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NormalButton(
                    hintText: 'Confirm Order',
                    onPressed: () {
                      print('🧪 Button Pressed');
                      if (customer != null) {
                        final email = customer!['email'];
                        final name = customer!['name'] ?? 'Customer';
                        print('Sending mail to the customer');
                        sendEmail(
                          to: email,
                          subject: "Your Order has been placed!",
                          message:
                              "$name,\nYour order has been successfully placed.\n\nThank you!",
                        );
                        sendEmail(
                          to: "",
                          subject: "New order placed!",
                          message: "",
                        );
                        print('Mail sent');
                      } else {
                        print("Customer data not loaded yet.");
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
