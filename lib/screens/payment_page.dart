import 'package:buy_app/services/addresses.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/services/sms_service.dart';
import 'package:buy_app/services/email_service.dart';
import 'package:buy_app/services/cart_manager.dart';
import 'package:buy_app/widgets/normal_button.dart';
import 'package:flutter/material.dart';

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
        "${address.city}, ${address.state} - ${address.pincode}",
      );
      print("SMS sent to $phone");
    } else {
      print("No phone number available.");
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
                    onPressed: () async {
                      print('🧪 Button Pressed - Confirming Order');

                      if (customer == null) {
                        print("❌ Customer data not loaded yet.");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please wait, loading customer data...',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      try {
                        final email = customer!['email'];
                        final name = customer!['name'] ?? 'Customer';
                        final cart = Cart.instance;

                        // Send confirmation email to customer
                        print('📧 Sending confirmation email to customer...');
                        final customerEmailSent =
                            await EmailService.sendCustomerConfirmationEmail(
                              customerEmail: email,
                              customerName: name,
                              shippingAddress: address,
                              orderedProducts: cart.items,
                            );

                        // Send order details to all relevant sellers
                        print('📧 Sending order details to sellers...');
                        await EmailService.sendOrderDetailsToSellers(
                          customer: customer!,
                          shippingAddress: address,
                        );

                        // Show success message
                        if (customerEmailSent) {
                          print('✅ All emails sent successfully!');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ Order confirmed! Emails sent to you and sellers.',
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );

                          // Clear the cart after successful order
                          cart.clear();

                          // Navigate back to home or order success page
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (route) => false,
                          );
                        } else {
                          throw Exception(
                            'Failed to send customer confirmation email',
                          );
                        }
                      } catch (e) {
                        print("❌ Error confirming order: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '❌ Failed to confirm order. Please try again.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
