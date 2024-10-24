import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/main_page.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/widgets/buttons/adventure_button.dart';
import 'package:handabatamae/widgets/buttons/arcade_button.dart';
import 'adventure_page.dart'; // Import AdventurePage
import 'arcade_page.dart'; // Import ArcadePage
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework
import '../widgets/header_footer/header_widget.dart'; // Import HeaderWidget
import '../widgets/header_footer/footer_widget.dart'; // Import FooterWidget

class PlayPage extends StatefulWidget {
  final String title;
  final String selectedLanguage;

  const PlayPage({super.key, required this.title, required this.selectedLanguage});

  @override
  PlayPageState createState() => PlayPageState();
}

class PlayPageState extends State<PlayPage> {
  bool _isUserProfileVisible = false;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage; // Initialize with the passed language
  }

  void _toggleUserProfile() {
    setState(() {
      _isUserProfileVisible = !_isUserProfileVisible;
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }  

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isUserProfileVisible) {
          setState(() {
            _isUserProfileVisible = false;
          });
          return false;
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
          );
          return false;
        }
      },
      child: Scaffold(
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
                    'assets/backgrounds/background.svg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Column(
                    children: [
                      HeaderWidget(
                        selectedLanguage: _selectedLanguage,
                        onBack: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MainPage(selectedLanguage: _selectedLanguage)),
                          );
                        },
                        onToggleUserProfile: _toggleUserProfile,
                        onChangeLanguage: _changeLanguage,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40), // Adjust the top padding as needed
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const SizedBox(height: 0),
                                  AdventureButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => AdventurePage(selectedLanguage: _selectedLanguage)),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ArcadeButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => ArcadePage(selectedLanguage: _selectedLanguage)),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const FooterWidget(),
                    ],
                  ),
                  if (_isUserProfileVisible)
                    UserProfilePage(onClose: _toggleUserProfile, selectedLanguage: _selectedLanguage),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}