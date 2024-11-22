import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isDesktop = sizingInformation.deviceScreenType == DeviceScreenType.desktop;
        final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
        
        // Adjusted text sizes
        final dynamicTextSize = isDesktop ? 18.0 :
                              isTablet ? 15.0 : // Reduced from 16.0
                              13.0;  // Reduced from 14.0

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
                height: height ?? 50,
                child: Text(
                  text,
                  style: GoogleFonts.rubik(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: dynamicTextSize,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}