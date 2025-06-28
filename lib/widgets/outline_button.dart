import 'package:flutter/material.dart';

import '../colorPallete/color_pallete.dart';

// ignore: must_be_immutable
class CustomOutlineButton extends StatelessWidget {
  CustomOutlineButton({
    super.key,
    required this.hintText,
    required this.onPressed,
  });
  String hintText;
  VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          fixedSize: const Size(double.infinity, 55),
          shadowColor: colorPallete.color4,
          backgroundColor: colorPallete.color4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(10),
            side: BorderSide(width: 10),
          ),
        ),
        child: Text(
          hintText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
