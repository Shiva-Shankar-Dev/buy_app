import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import 'package:buy_app/services/auth.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPage();
}

class _SignUpPage extends State<SignUpPage> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  get result => null;

  void handleSingup() async {
    final mobile = mobileController.text.trim();
    print("📝 Starting signup process...");
    print("📱 Mobile number being saved: $mobile");
    final valid = await FirebaseFirestore.instance
        .collection('customers')
        .where('mobile', isEqualTo: mobile)
        .get();
    if (valid.docs.isEmpty) {
      String? result = await _authService.signUpUser(
        name: fullNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        mobile: mobile,
      );
      if (result == null) {
        print(" Signup success! User created with mobile: $mobile");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamed(context, '/home');
      } else {
        print("❌ Signup error: $result");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
        );
      }
    } else {
      print("Sign Up error!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The entered phone number is already registered with another account. Please enter a different phone!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void dispose() {
    super.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    mobileController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          alignment: Alignment.center,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 85),
                Text(
                  'Sign Up.',
                  style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 27),
                Form(
                  child: Column(
                    children: [
                      AuthTextField(
                        hintText: 'User name',
                        controller: fullNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username cannot be empty';
                          }
                          return null;
                        },
                      ),
                      AuthTextField(
                        hintText: 'Email',
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email cannot be empty';
                          }
                          return null;
                        },
                      ),
                      AuthTextField(
                        hintText: 'Password',
                        controller: passwordController,
                        hide: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          return null;
                        },
                      ),
                      AuthTextField(
                        hintText: 'Mobile (+91xxxxxxxxxx)',
                        controller: mobileController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mobile cannot be empty';
                          }
                          if (!value.startsWith('+')) {
                            return 'Please enter mobile with country code (e.g., +91)';
                          }
                          if (value.length < 13) {
                            // +91 + 10 digits = 13 minimum
                            return 'Please enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),
                AuthButton(
                  hintText: 'Sign Up',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      handleSingup();
                    }
                  },
                ),
                SizedBox(height: 36),
                RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(color: colorPallete.color1),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/login');
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
