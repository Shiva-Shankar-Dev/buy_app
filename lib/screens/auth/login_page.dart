import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/widgets/auth_button.dart';
import 'package:buy_app/widgets/auth_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void loginHandle() async {
    debugPrint("Password: ${passwordController.text}");
    String? result = await _authService.signInUser(
      email: emailController.text,
      password: passwordController.text,
    );
    if (result == null) {
      Navigator.pushNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.white,),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 50.0, bottom: 10.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorPallete.color1,
                        colorPallete.color2,
                      ]
                  ),
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(Icons.person_2_outlined, size: 80, color: Colors.white,),
                ),
              ),
              SizedBox(height: 10,),
              Column(
                children: [
                  Text('Welcome', style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins"
                    ),
                  ).animate().slideY(
                    begin: 0.5,
                    duration: Duration(milliseconds: 500),
                  ).then().fadeIn(
                     duration: Duration(milliseconds: 1500)
                  ),
                  Text('Continue with your Email and Password', style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey
                  ),
                  ).animate().slideY(
                    begin: 0.5,
                    duration: Duration(milliseconds: 500),
                  ).then().fadeIn(
                      duration: Duration(milliseconds: 1500)
                  ),
                ],
              ),
              SizedBox(height: 20.0,),
              Form(
                key: _formKey,
                child: Column(
                  spacing: 3,
                  children: [
                    AuthTextField(
                      hintText: 'Email',
                      controller: emailController,
                    ),
                    AuthPassword(
                      passwordController: passwordController,
                    ),
                    SizedBox(height: 10),
                    AuthButton(
                      hintText: 'Login',
                      onPressed: () {
                        FadeEffect(
                          duration: Duration(milliseconds: 500),
                        );
                        loginHandle();
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(
                  duration: Duration(milliseconds: 1000)
              ).then(),
              SizedBox(height: 20,),
              Container(
                width: MediaQuery.of(context).size.width - 30,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(15)
                ),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Use ',
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Phone Number instead?',
                          style: TextStyle(color: colorPallete.color1, fontSize: 15),
                          recognizer: TapGestureRecognizer()..onTap = () {
                              Navigator.pushNamed(context, '/mobile');
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12,),
              Container(
                width: MediaQuery.of(context).size.width - 30,
                height: 56,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Don\'t have an account? ',
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Sign Up Now',
                          style: TextStyle(color: colorPallete.color1, fontSize: 15),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            Navigator.pushNamed(context, '/signup');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
    // TRY THIS: Try changing the color here to a specific color (to
  }
}
