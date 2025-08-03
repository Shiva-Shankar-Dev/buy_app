import 'package:buy_app/colorPallete/color_pallete.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class AuthTextField extends StatelessWidget {
  AuthTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.validator,
  });
  final String? Function(String?)? validator;
  String hintText;
  TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 10.0),
        child: TextFormField(
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey.shade400.withAlpha(100),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.shade400.withAlpha(100),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
          controller: controller,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'please enter your mobile number';
            }
            return null;
          },
        ),
      ),
    );
  }
}

class AuthPassword extends StatefulWidget {
  final TextEditingController passwordController;
  const AuthPassword({super.key, required this.passwordController});

  @override
  State<AuthPassword> createState() => _AuthPasswordState();
}

class _AuthPasswordState extends State<AuthPassword> {
  bool isPasswordVisible = true;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 10.0),
        child: TextFormField(
          obscureText: isPasswordVisible,
          decoration: InputDecoration(
            hintText: "Password",
            filled: true,
            fillColor: Colors.grey.shade400.withAlpha(100),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey.shade400.withAlpha(100),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  isPasswordVisible = !isPasswordVisible;
                });
              },
              icon: isPasswordVisible
                  ? Icon(Icons.visibility_outlined)
                  : Icon(Icons.visibility_off_outlined),
            ),
          ),
          controller: widget.passwordController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'please enter your mobile number';
            }
            return null;
          },
        ),
      ),
    );
  }
}

