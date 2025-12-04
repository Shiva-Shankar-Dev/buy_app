import 'package:flutter/material.dart';

import '../colorPallete/color_pallete.dart';

// ignore: must_be_immutable
class NormalButton extends StatelessWidget {
  NormalButton({
    super.key,
    required this.hintText,
    required this.onPressed,
    this.length = 320,
    this.height = 55,
  });
  String hintText;
  VoidCallback onPressed;
  double length;
  double height;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorPallete.color1, ColorPallete.color2],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          fixedSize: Size(length, height),
          shadowColor: ColorPallete.color4,
          backgroundColor: ColorPallete.color4,
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
