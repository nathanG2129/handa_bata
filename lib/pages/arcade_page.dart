import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'play_page.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework

class ArcadePage extends StatelessWidget {
  final String selectedLanguage; // Add this line
  const ArcadePage({super.key, required this.selectedLanguage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBreakpoints(
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 800, name: TABLET),
          Breakpoint(start: 801, end: 1920, name: DESKTOP),
          Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
        child: MaxWidthBox(
          maxWidth: 1200,
          child: ResponsiveScaledBox(
            width: ResponsiveValue<double>(context, conditionalValues: [
              const Condition.equals(name: MOBILE, value: 450),
              const Condition.between(start: 800, end: 1100, value: 800),
              const Condition.between(start: 1000, end: 1200, value: 1000),
            ]).value,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/backgrounds/background.svg', // Use the common background image
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50), // Adjust the top padding as needed
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => PlayPage(title: '', selectedLanguage: selectedLanguage)), // Pass selectedLanguage
                              (Route<dynamic> route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF241242), // Text color
                            backgroundColor: Colors.white, // Background color
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                          child: const Text('Back to Play Page'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}