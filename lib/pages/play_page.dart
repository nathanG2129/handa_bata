import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/widgets/adventure_button.dart';
import 'package:handabatamae/widgets/arcade_button.dart';
import 'adventure_page.dart'; // Import AdventurePage
import 'arcade_page.dart'; // Import ArcadePage
import 'splash_page.dart';
import '../localization/play/localization.dart'; // Import the localization file
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework

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
  
  void _navigateBack(BuildContext context) {
    Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => SplashPage(selectedLanguage: _selectedLanguage),
    ),
  );
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
        _navigateBack(context);
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
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50), // Adjust the top padding as needed
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: _toggleUserProfile,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color(0xFF241242), // Text color
                              backgroundColor: Colors.white, // Background color
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero, // Purely rectangular with sharp edges
                                side: BorderSide(color: Color(0xFF241242), width: 1.0), // Border color and width
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), // Adjusted padding for smaller size
                              textStyle: GoogleFonts.rubik(fontSize: 20), // Using Rubik font
                            ),
                            child: Text(PlayLocalization.translate('userProfile', _selectedLanguage)),
                          ),
                          const SizedBox(height: 50),
                          AdventureButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AdventurePage(selectedLanguage: _selectedLanguage,)),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          ArcadeButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ArcadePage(selectedLanguage: _selectedLanguage,)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 35,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 100, // Adjust the width as needed
                        maxHeight: 100, // Adjust the height as needed
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 33, color: Colors.white), // Adjust the icon size and color as needed
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => SplashPage(selectedLanguage: _selectedLanguage,)),
                          );
                        },
                      ),
                    ),
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
                  if (_isUserProfileVisible)
                    UserProfilePage(onClose: _toggleUserProfile, selectedLanguage: _selectedLanguage,),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}