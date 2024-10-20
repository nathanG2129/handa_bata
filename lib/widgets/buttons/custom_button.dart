import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Container(
            alignment: Alignment.center,
            width: ResponsiveValue<double>(
              context,
              defaultValue: width ?? double.infinity,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: (width ?? double.infinity) * 1.1), // Increased width for smaller screens
                Condition.largerThan(name: MOBILE, value: (width ?? double.infinity) * 1.2),
              ],
            ).value,
            height: ResponsiveValue<double>(
              context,
              defaultValue: height ?? 50,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: (height ?? 50) * 0.8),
                Condition.largerThan(name: MOBILE, value: (height ?? 50) * 1.2),
              ],
            ).value,
            child: Text(
              text,
              style: GoogleFonts.rubik(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}