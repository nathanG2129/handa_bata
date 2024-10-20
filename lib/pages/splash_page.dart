import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/main_page.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'login_page.dart';
import 'package:handabatamae/services/auth_service.dart';
import '../widgets/buttons/custom_button.dart';
import '../widgets/text_with_shadow.dart';
import '/localization/splash/localization.dart'; // Import the localization file

class SplashPage extends StatefulWidget {
  final String selectedLanguage;
  const SplashPage({super.key, required this.selectedLanguage});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage; // Initialize with the passed language
  }

  static const double titleFontSize = 90;
  static const double subtitleFontSize = 85;
  static const double buttonWidthFactor = 0.8;
  static const double buttonHeight = 55;
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

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
          );
          return;
        }
      }

      // If no guest account exists, create a new one
      await FirebaseAuth.instance.signInAnonymously();
      await authService.createGuestProfile(); // Create guest profile in Firestore

      // Check if the widget is still mounted before using the context
      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
      );
    } else {
      // Check for local guest profile
      UserProfile? localGuestProfile = await authService.getLocalGuestProfile();

      if (!context.mounted) return;

      if (localGuestProfile != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
      );
      } else {
        // Sign in anonymously if no local guest profile exists
        _signInAnonymously(context);
      }
    }
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

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
            width: (ResponsiveValue<double>(context, conditionalValues: [
              const Condition.equals(name: MOBILE, value: 450),
              const Condition.between(start: 800, end: 1100, value: 800),
              const Condition.between(start: 1000, end: 1200, value: 1000),
            ]).value), // Provide a default value
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  top: 60,
                  right: 35,
                  child: DropdownButton<String>(
                    icon: const Icon(Icons.language, color: Colors.white, size: 40), // Larger icon
                    underline: Container(), // Remove underline
                    items: const [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'fil',
                        child: Text('Filipino'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _changeLanguage(newValue);
                      }
                    },
                  ),
                ),
                Center(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: (ResponsiveValue<double>(
                              context,
                              defaultValue: topPadding,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: topPadding * 0.8),
                                const Condition.largerThan(name: MOBILE, value: topPadding * 1.2),
                              ],
                            ).value), // Provide a default value
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: TextWithShadow(
                                  text: SplashLocalization.translate('title', _selectedLanguage),
                                  fontSize: (ResponsiveValue<double>(
                                    context,
                                    defaultValue: titleFontSize,
                                    conditionalValues: [
                                      const Condition.smallerThan(name: MOBILE, value: titleFontSize * 0.8),
                                      const Condition.largerThan(name: MOBILE, value: titleFontSize * 1.2),
                                    ],
                                  ).value), // Provide a default value
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(0, (ResponsiveValue<double>(
                                  context,
                                  defaultValue: verticalOffset,
                                  conditionalValues: [
                                    const Condition.smallerThan(name: MOBILE, value: verticalOffset * 0.8),
                                    const Condition.largerThan(name: MOBILE, value: verticalOffset * 1.2),
                                  ],
                                ).value)), // Provide a default value
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: TextWithShadow(
                                    text: SplashLocalization.translate('subtitle', _selectedLanguage),
                                    fontSize: (ResponsiveValue<double>(
                                      context,
                                      defaultValue: subtitleFontSize,
                                      conditionalValues: [
                                        const Condition.smallerThan(name: MOBILE, value: subtitleFontSize * 0.8),
                                        const Condition.largerThan(name: MOBILE, value: subtitleFontSize * 1.2),
                                      ],
                                    ).value), // Provide a default value
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 0),
                      SizedBox(
                        width: (ResponsiveValue<double>(
                          context,
                          defaultValue: MediaQuery.of(context).size.width * buttonWidthFactor,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                            Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * buttonWidthFactor),
                          ],
                        ).value), // Provide a default value
                        height: (ResponsiveValue<double>(
                          context,
                          defaultValue: buttonHeight,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                            const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                          ],
                        ).value), // Provide a default value
                        child: CustomButton(
                          text: SplashLocalization.translate('login', _selectedLanguage),
                          color: const Color(0xFF351B61),
                          textColor: Colors.white,
                          width: (ResponsiveValue<double>(
                            context,
                            defaultValue: MediaQuery.of(context).size.width * buttonWidthFactor,
                            conditionalValues: [
                              Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                              Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * buttonWidthFactor),
                            ],
                          ).value), // Provide a default value
                          height: (ResponsiveValue<double>(
                            context,
                            defaultValue: buttonHeight,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                              const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                            ],
                          ).value), // Provide a default value
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage(selectedLanguage: _selectedLanguage)),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: (ResponsiveValue<double>(
                          context,
                          defaultValue: buttonSpacing,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: buttonSpacing * 0.8),
                            const Condition.largerThan(name: MOBILE, value: buttonSpacing * 1.2),
                          ],
                        ).value), // Provide a default value
                      ),
                      SizedBox(
                        width: (ResponsiveValue<double>(
                          context,
                          defaultValue: MediaQuery.of(context).size.width * buttonWidthFactor,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                            Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * buttonWidthFactor),
                          ],
                        ).value), // Provide a default value
                        height: (ResponsiveValue<double>(
                          context,
                          defaultValue: buttonHeight,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                            const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                          ],
                        ).value), // Provide a default value
                        child: CustomButton(
                          text: SplashLocalization.translate('play_now', _selectedLanguage),
                          color: const Color(0xFFF1B33A),
                          textColor: Colors.black,
                          width: (ResponsiveValue<double>(
                            context,
                            defaultValue: MediaQuery.of(context).size.width * buttonWidthFactor,
                            conditionalValues: [
                              Condition.smallerThan(name: MOBILE, value: MediaQuery.of(context).size.width * 0.9),
                              Condition.largerThan(name: MOBILE, value: MediaQuery.of(context).size.width * buttonWidthFactor),
                            ],
                          ).value), // Provide a default value
                          height: (ResponsiveValue<double>(
                            context,
                            defaultValue: buttonHeight,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: buttonHeight * 0.8),
                              const Condition.largerThan(name: MOBILE, value: buttonHeight * 1.2),
                            ],
                          ).value), // Provide a default value
                          onTap: () {
                            _checkSignInStatus(context);
                          },
                        ),
                      ),
                      SizedBox(
                        height: (ResponsiveValue<double>(
                          context,
                          defaultValue: bottomPadding,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: bottomPadding * 0.8),
                            const Condition.largerThan(name: MOBILE, value: bottomPadding * 1.2),
                          ],
                        ).value), // Provide a default value
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          SplashLocalization.translate('copyright', _selectedLanguage),
                          style: GoogleFonts.vt323(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
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