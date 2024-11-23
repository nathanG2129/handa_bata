import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

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
    final textSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 13.0,
      tablet: 15.0,
      desktop: 18.0,
    );

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
            width: width ?? double.infinity,
            height: height ?? ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 45.0,
              tablet: 50.0,
              desktop: 55.0,
            ),
            child: Text(
              text,
              style: GoogleFonts.rubik(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: textSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}