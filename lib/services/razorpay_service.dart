import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final Function(PaymentSuccessResponse) onSuccess;
  final Function(PaymentFailureResponse) onFailure;
  final Function(ExternalWalletResponse)? onExternalWallet;

  RazorpayService({
    required this.onSuccess,
    required this.onFailure,
    this.onExternalWallet,
  });

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    if (onExternalWallet != null) {
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet!);
    }
  }

  void openCheckout({
    required double amount,
    required String contact,
    required String email,
    required String orderId,
    String? description,
    String? name,
  }) {
    var options = {
      'key': 'rzp_test_RnUNr46xdvJfJJ',
      // Amount is in paice (multiply by 100)
      'amount': (amount * 100).toInt(),
      'name': name ?? 'Buy App',
      'description': description ?? 'Order Payment',
      'prefill': {'contact': contact, 'email': email},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
