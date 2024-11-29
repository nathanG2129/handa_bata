import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AdminFooterWidget extends StatelessWidget {
  const AdminFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isSmallScreen = sizingInformation.deviceScreenType == DeviceScreenType.mobile || 
                            MediaQuery.of(context).size.width < 600;

        final footerHeight = isSmallScreen ? 120.0 : 60.0;

        return Container(
          height: footerHeight,
          color: const Color(0xFF241242),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: isSmallScreen 
            // Vertical layout for small screens
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Copyright 2024 © under license from Handa Bata',
                    style: GoogleFonts.vt323(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Handle Privacy Policy
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Privacy Policy',
                          style: GoogleFonts.vt323(
                            fontSize: 14,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        '•',
                        style: GoogleFonts.vt323(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Handle Terms of Service
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Terms of Service',
                          style: GoogleFonts.vt323(
                            fontSize: 14,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            // Horizontal layout for larger screens
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Copyright 2024 © under license from Handa Bata',
                    style: GoogleFonts.vt323(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Handle Privacy Policy
                        },
                        child: Text(
                          'Privacy Policy',
                          style: GoogleFonts.vt323(
                            fontSize: 16,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      TextButton(
                        onPressed: () {
                          // Handle Terms of Service
                        },
                        child: Text(
                          'Terms of Service',
                          style: GoogleFonts.vt323(
                            fontSize: 16,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        );
      },
    );
  }
} 