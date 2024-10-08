// lib/widgets/text_with_shadow.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';

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
    double responsiveFontSize = ResponsiveValue<double>(
      context,
      defaultValue: fontSize,
      conditionalValues: [
        Condition.smallerThan(name: MOBILE, value: fontSize * 0.8),
        Condition.largerThan(name: MOBILE, value: fontSize * 1.2),
      ],
    ).value;

    return Stack(
      children: [
        Text(
          text,
          style: GoogleFonts.vt323(
            fontSize: responsiveFontSize,
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
            fontSize: responsiveFontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: GoogleFonts.vt323(fontSize: responsiveFontSize, color: Colors.white),
        ),
      ],
    );
  }
}