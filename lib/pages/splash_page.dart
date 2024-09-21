import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'play_page.dart';
import 'package:handabatamae/services/auth_service.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const double titleFontSize = 100;
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

  Widget _buildTextWithShadow(String text, double fontSize) {
    return Stack(
      children: [
        // Shadow text
        Text(
          text,
          style: GoogleFonts.vt323(
            fontSize: fontSize,
            color: Colors.transparent,
            shadows: [
              const Shadow(
                offset: Offset(0, shadowOffsetY), // Shadow only at the bottom
                blurRadius: 0.0,
                color: Colors.black,
              ),
            ],
          ),
        ),
        // Border text
        Text(
          text,
          style: GoogleFonts.vt323(
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = borderStrokeWidth
              ..color = Colors.black,
          ),
        ),
        // Solid text
        Text(
          text,
          style: GoogleFonts.vt323(fontSize: fontSize, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, String text, Color color, Color textColor, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(30), // Ensure ripple effect respects border radius
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30), // Oblong shape
            border: Border.all(color: Colors.white, width: 2), // White border
          ),
          child: Container(
            alignment: Alignment.center,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * buttonWidthFactor, // Width set to 80% of screen width
              minHeight: buttonHeight,
            ),
            child: Text(
              text,
              style: GoogleFonts.rubik(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                        _buildTextWithShadow('Handa Bata', titleFontSize),
                        Transform.translate(
                          offset: const Offset(0, verticalOffset), // Adjust this value to control the vertical offset
                          child: _buildTextWithShadow('Mobile', subtitleFontSize),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 0), // Adjust this value to control the space between the titles and the buttons
                _buildButton(
                  context,
                  'Login',
                  const Color(0xFF351B61), // Login button color
                  Colors.white,
                  () {
                    // Navigate to the login page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                ),
                const SizedBox(height: buttonSpacing),
                _buildButton(
                  context,
                  'Play Now',
                  const Color(0xFFF1B33A), // Play Now button color
                  Colors.black,
                  () {
                    _signInAnonymously(context); // Sign in anonymously and navigate to PlayPage
                  },
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
    );
  }
}