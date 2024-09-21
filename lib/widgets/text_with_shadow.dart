// lib/widgets/text_with_shadow.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextWithShadow extends StatelessWidget {
  final String text;
  final double fontSize;

  const TextWithShadow({
    super.key,
    required this.text,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: GoogleFonts.vt323(
            fontSize: fontSize,
            color: Colors.transparent,
            shadows: [
              const Shadow(
                offset: Offset(0, 6.5),
                blurRadius: 0.0,
                color: Color(0xFF241242), // Updated shadow color
              ),
            ],
          ),
        ),
        Text(
          text,
          style: GoogleFonts.vt323(
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: GoogleFonts.vt323(fontSize: fontSize, color: Colors.white),
        ),
      ],
    );
  }
}