import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/main/main_page.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/widgets/buttons/adventure_button.dart';
import 'package:handabatamae/widgets/buttons/arcade_button.dart';
import 'adventure_page.dart';
import 'arcade_page.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import '../widgets/header_footer/header_widget.dart';
import '../widgets/header_footer/footer_widget.dart';

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
    _selectedLanguage = widget.selectedLanguage;
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
        body: ResponsiveBuilder(
          builder: (context, sizingInformation) {
            // Calculate screen width
            final screenWidth = MediaQuery.of(context).size.width;
            
            // Calculate content width based on device type
            final contentWidth = sizingInformation.deviceScreenType == DeviceScreenType.mobile
                ? screenWidth  // Full width for mobile
                : sizingInformation.deviceScreenType == DeviceScreenType.tablet
                    ? screenWidth  // Full width for tablet
                    : 1200.0;     // Max width for desktop

            // Calculate button spacing
            final buttonSpacing = ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 20.0,
              tablet: 30.0,
              desktop: 40.0,
            );

            // Calculate top padding
            final topPadding = ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 40.0,
              tablet: 60.0,
              desktop: 80.0,
            );

            return Stack(
              children: [
                // Background
                SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                
                // Main Content
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: contentWidth,
                    ),
                    child: Column(
                      children: [
                        // Header
                        HeaderWidget(
                          selectedLanguage: _selectedLanguage,
                          onBack: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainPage(selectedLanguage: _selectedLanguage),
                              ),
                            );
                          },
                          onChangeLanguage: _changeLanguage,
                        ),
                        
                        // Scrollable Content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: topPadding),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    AdventureButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AdventurePage(selectedLanguage: _selectedLanguage),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: buttonSpacing),
                                    ArcadeButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ArcadePage(selectedLanguage: _selectedLanguage),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Footer
                        FooterWidget(selectedLanguage: _selectedLanguage),
                      ],
                    ),
                  ),
                ),
                
                // User Profile Overlay
                if (_isUserProfileVisible)
                  UserProfilePage(
                    onClose: _toggleUserProfile,
                    selectedLanguage: _selectedLanguage,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}