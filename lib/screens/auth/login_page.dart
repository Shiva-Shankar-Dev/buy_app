import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:buy_app/services/auth.dart';
import 'package:buy_app/widgets/auth_button.dart';
import 'package:buy_app/widgets/auth_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  void loginhandle() async {
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
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 30,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(0, 150, 0, 100),
              child: Column(
                children: [
                  Text('Login',
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PlayfairDisplay',
                        ),
                        textAlign: TextAlign.left,
                      )
                      .animate()
                      .slideY(
                        begin: 0.5,
                        duration: Duration(milliseconds: 500),
                      )
                      .then()
                      .fadeIn(duration: Duration(milliseconds: 1500)),
                  SizedBox(height: 32),
                  Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AuthTextField(
                              hintText: 'Email',
                              controller: emailController,
                            ),
                            AuthPassword(
                              passwordController: passwordController,
                            ),
                            SizedBox(height: 10),
                            /*Row(
                          children: [
                            Checkbox(value: true, onChanged: (value) {}),
                            Text('Remeber Me'),
                          ],
                        ),*/
                            SizedBox(height: 20),
                            AuthButton(
                              hintText: 'Login',
                              onPressed: () {
                                FadeEffect(
                                  duration: Duration(milliseconds: 500),
                                );
                                loginhandle();
                              },
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: Duration(milliseconds: 1000))
                      .then(),
                  SizedBox(height: 10),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      text: 'Use ',
                      children: [
                        TextSpan(
                          text: 'Mobile instead?',
                          style: TextStyle(color: colorPallete.color1),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/mobile');
                            },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0),
                ],
              ),
            ),

            Container(
              margin: EdgeInsets.only(top: 100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Don\'t have an account? ',
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(color: colorPallete.color1),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/signup');
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
    // TRY THIS: Try changing the color here to a specific color (to
  }
}
