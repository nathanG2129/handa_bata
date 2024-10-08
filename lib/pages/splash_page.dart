import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/user_model.dart';
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

      // Check if a guest account already exists
      String? guestUid = await authService.getGuestAccountDetails();
      if (guestUid != null) {
        // Sign in with the existing guest account
        UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
        if (userCredential.user != null) {
          // Check if the widget is still mounted before using the context
          if (!context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlayPage(title: 'Handa Bata')),
          );
          return;
        }
      }

      // If no guest account exists, create a new one
      await FirebaseAuth.instance.signInAnonymously();
      await authService.createGuestProfile(); // Create guest profile in Firestore

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

  Future<void> _checkSignInStatus(BuildContext context) async {
    AuthService authService = AuthService();
    bool isSignedIn = await authService.isSignedIn();
  
    if (!context.mounted) return;
  
    if (isSignedIn) {
      // Navigate to PlayPage if the user is already signed in and chose to stay signed in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PlayPage(title: 'Handa Bata')),
      );
    } else {
      // Check for local guest profile
      UserProfile? localGuestProfile = await authService.getLocalGuestProfile();
  
      if (!context.mounted) return;
  
      if (localGuestProfile != null) {
        // Navigate to PlayPage if a local guest profile exists
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PlayPage(title: 'Handa Bata')),
        );
      } else {
        // Sign in anonymously if no local guest profile exists
        _signInAnonymously(context);
      }
    }
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
                    padding: EdgeInsets.only(
                      top: ResponsiveValue<double>(
                        context,
                        defaultValue: topPadding,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: topPadding * 0.8),
                          const Condition.largerThan(name: MOBILE, value: topPadding * 1.2),
                        ],
                      ).value,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: TextWithShadow(
                            text: 'Handa Bata',
                            fontSize: ResponsiveValue<double>(
                              context,
                              defaultValue: titleFontSize,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: titleFontSize * 0.8),
                                const Condition.largerThan(name: MOBILE, value: titleFontSize * 1.2),
                              ],
                            ).value,
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, ResponsiveValue<double>(
                            context,
                            defaultValue: verticalOffset,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: verticalOffset * 0.8),
                              const Condition.largerThan(name: MOBILE, value: verticalOffset * 1.2),
                            ],
                          ).value),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: TextWithShadow(
                              text: 'Mobile',
                              fontSize: ResponsiveValue<double>(
                                context,
                                defaultValue: subtitleFontSize,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: subtitleFontSize * 0.8),
                                  const Condition.largerThan(name: MOBILE, value: subtitleFontSize * 1.2),
                                ],
                              ).value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 0),
                SizedBox(
                  width: MediaQuery.of(context).size.width * buttonWidthFactor,
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: buttonHeight,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                      const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                    ],
                  ).value,
                  child: CustomButton(
                    text: 'Login',
                    color: const Color(0xFF351B61),
                    textColor: Colors.white,
                    width: MediaQuery.of(context).size.width * buttonWidthFactor,
                    height: ResponsiveValue<double>(
                      context,
                      defaultValue: buttonHeight,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                        const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                      ],
                    ).value,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: buttonSpacing,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: buttonSpacing * 0.8),
                      const Condition.largerThan(name: MOBILE, value: buttonSpacing * 1.2),
                    ],
                  ).value,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * buttonWidthFactor,
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: buttonHeight,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                      const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                    ],
                  ).value,
                  child: CustomButton(
                    text: 'Play Now',
                    color: const Color(0xFFF1B33A),
                    textColor: Colors.black,
                    width: MediaQuery.of(context).size.width * buttonWidthFactor,
                    height: ResponsiveValue<double>(
                      context,
                      defaultValue: buttonHeight,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                        const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                      ],
                    ).value,
                    onTap: () {
                      _checkSignInStatus(context);
                    },
                  ),
                ),
                SizedBox(
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: bottomPadding,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: bottomPadding * 0.8),
                      const Condition.largerThan(name: MOBILE, value: bottomPadding * 1.2),
                    ],
                  ).value,
                ),
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