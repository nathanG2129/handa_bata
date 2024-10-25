import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Button3D extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool locked;
  final double width;
  final double height;

  const Button3D({
    super.key,
    required this.text,
    required this.onPressed,
    this.locked = false,
    this.width = double.infinity,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          color: Color(0xFF351b61),
          border: Border(
            top: BorderSide(width: 2, color: Colors.black),
            left: BorderSide(width: 4, color: Colors.black),
            right: BorderSide(width: 4, color: Colors.black),
            bottom: BorderSide(width: 10, color: Colors.black),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.vt323(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}