import 'package:flutter/material.dart';

import '../colorPallete/color_pallete.dart';

// ignore: must_be_immutable
class NormalButton extends StatelessWidget {
  NormalButton({super.key, required this.hintText, required this.onPressed});
  String hintText;
  VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorPallete.color1, colorPallete.color2],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          fixedSize: const Size(double.infinity, 55),
          shadowColor: colorPallete.color4,
          backgroundColor: colorPallete.color4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(10),
          ),
        ),
        child: Text(
          hintText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
