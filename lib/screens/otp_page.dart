import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../colorPallete/color_pallete.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  final String verificationId;
  final int? resendToken;

  const OtpPage({
    super.key,
    required this.phone,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  late String verificationId;
  late String phone;
  int? resendToken;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    verificationId = widget.verificationId;
    phone = widget.phone;
    resendToken = widget.resendToken;
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError('Please enter the OTP');
      return;
    }
    
    if (otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    print('🔐 Verifying OTP: $otp');
    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      print('✅ OTP verification successful!');
      
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      print('❌ OTP verification failed: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please check and try again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP expired. Please request a new one.';
          break;
        default:
          errorMessage = e.message ?? 'Verification failed';
      }
      _showError(errorMessage);
    } catch (e) {
      print('💥 Unexpected error during verification: $e');
      _showError('Network error. Please try again.');
    }

    setState(() => _isVerifying = false);
  }

  void _resendOtp() async {
    if (!_canResend || _isResending) return;
    
    print('📱 Resending OTP to: $phone');
    setState(() => _isResending = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('🎉 Auto verification completed on resend!');
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            Navigator.pushReplacementNamed(context, '/home');
          } catch (e) {
            print('❌ Auto verification failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Resend verification failed: ${e.code} - ${e.message}');
          _showError('Failed to resend OTP: ${e.message}');
        },
        codeSent: (String newVerificationId, int? newResendToken) {
          print('📨 OTP resent successfully!');
          setState(() {
            verificationId = newVerificationId;
            resendToken = newResendToken;
            _resendTimer = 30;
            _canResend = false;
          });
          _startResendTimer();
          _showSuccess('OTP sent successfully!');
        },
        codeAutoRetrievalTimeout: (String newVerificationId) {
          print('⏰ Auto retrieval timeout for resend: $newVerificationId');
        },
      );
    } catch (e) {
      print('💥 Unexpected error during resend: $e');
      _showError('Failed to resend OTP. Please try again.');
    }

    setState(() => _isResending = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text('Verify OTP'), backgroundColor: colorPallete.color4,),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter OTP', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              Text('sent to $phone'),
              SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'OTP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(width: 3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorPallete.color1, width: 3),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorPallete.color1, colorPallete.color2],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(320, 55),
                    shadowColor: colorPallete.color4,
                    backgroundColor: colorPallete.color4,
                  ),
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying
                      ? CircularProgressIndicator()
                      : Text('Verify', style: TextStyle(color: Colors.white,fontSize: 18)),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: _canResend && !_isResending ? _resendOtp : null,
                child: _isResending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Resending...'),
                        ],
                      )
                    : Text(
                        _canResend 
                            ? 'Resend OTP' 
                            : 'Resend OTP ($_resendTimer)s',
                        style: TextStyle(
                          color: _canResend ? colorPallete.color1 : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
