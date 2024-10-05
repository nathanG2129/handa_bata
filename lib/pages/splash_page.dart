import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'login_page.dart';
import 'play_page.dart';
import 'package:handabatamae/services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/text_with_shadow.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const double titleFontSize = 90;
  static const double subtitleFontSize = 85;
  static const double buttonWidthFactor = 0.8;
  static const double buttonHeight = 55;
  static const double shadowOffsetY = 5.0;
  static const double borderStrokeWidth = 5.0;
  static const double verticalOffset = -40.0;
  static const double topPadding = 210.0;
  static const double bottomPadding = 140.0;
  static const double buttonSpacing = 20.0;

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      AuthService authService = AuthService();
      await authService.logout(); // Ensure any previous session is cleared

      // Check if the widget is still mounted before using the context
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PlayPage(title: 'Handa Bata')),
      );
    } catch (e) {
      // Check if the widget is still mounted before using the context
      if (!context.mounted) return;

      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in anonymously: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBreakpoints.builder(
        child: Stack(
          children: [
            SvgPicture.asset(
              'assets/backgrounds/background.svg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Center(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: topPadding), // Adjust this value to control the vertical position
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: TextWithShadow(text: 'Handa Bata', fontSize: titleFontSize),
                          ),
                          Transform.translate(
                            offset: const Offset(0, verticalOffset), // Adjust this value to control the vertical offset
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: TextWithShadow(text: 'Mobile', fontSize: subtitleFontSize),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 0), // Adjust this value to control the space between the titles and the buttons
                  SizedBox(
                    width: MediaQuery.of(context).size.width * buttonWidthFactor,
                    height: buttonHeight,
                    child: CustomButton(
                      text: 'Login',
                      color: const Color(0xFF351B61), // Login button color
                      textColor: Colors.white,
                      onTap: () {
                        // Navigate to the login page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: buttonSpacing),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * buttonWidthFactor,
                    height: buttonHeight,
                    child: CustomButton(
                      text: 'Play Now',
                      color: const Color(0xFFF1B33A), // Play Now button color
                      textColor: Colors.black,
                      onTap: () {
                        _signInAnonymously(context); // Sign in anonymously and navigate to PlayPage
                      },
                    ),
                  ),
                  const SizedBox(height: bottomPadding), // Adjust this value to control the space between buttons and the bottom text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      '© 2023 Handa Bata. All rights reserved.',
                      style: GoogleFonts.vt323(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}