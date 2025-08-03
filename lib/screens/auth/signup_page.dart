import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/auth_button.dart';
import 'package:buy_app/services/auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

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
  Null get result => null;

  void handleSignup() async {
    final mobile = mobileController.text.trim();
    debugPrint("📝 Starting signup process...");
    debugPrint("📱 Mobile number being saved: $mobile");
    final valid = await FirebaseFirestore.instance.collection('customers')
        .where('mobile', isEqualTo: mobile).get();
    if (valid.docs.isEmpty) {
      String? result = await _authService.signUpUser(
        name: fullNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        mobile: mobile,
      );
      if (result == null) {
        debugPrint(" Signup success! User created with mobile: $mobile");
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        if(!mounted) return;
        Navigator.pushNamed(context, '/home');
      } else {
        debugPrint("❌ Signup error: $result");
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
        );
      }
    } else {
      debugPrint("Sign Up error!");
      if(!mounted) return;
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

  @override
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
      appBar: AppBar(
        leading: CloseButton(color: Colors.black,),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Account...', style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Poppins",
                      )),
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text('Create your account with your Email and Password', style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                        )),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
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
                      AuthPassword(
                        passwordController: passwordController,
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
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AuthButton(
                      hintText: 'Sign Up',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          handleSignup();
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 36),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width - 30,
                    height: 56,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: 'Login Now',
                              style: TextStyle(color: colorPallete.color1, fontSize: 15),
                              recognizer: TapGestureRecognizer()..onTap = () {
                                Navigator.pushNamed(context, '/login');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
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
