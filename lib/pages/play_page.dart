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
            final contentWidth = screenWidth;  // Always use full width for the container

            // Calculate button container width for tablet - reduced from 0.9 to 0.7
            final buttonContainerWidth = sizingInformation.deviceScreenType == DeviceScreenType.tablet
                ? screenWidth * 0.7  // 70% width for buttons container only (reduced from 90%)
                : contentWidth;

            // Calculate spacing - reduced for tablet
            final spacing = ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 20.0,
              tablet: 20.0,  // Reduced from 40.0 to bring buttons closer
              desktop: 60.0,
            );

            // Calculate vertical padding for buttons container
            final verticalPadding = ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 0.0,
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
                        // Header (full width)
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
                        
                        // Center content vertically in the remaining space
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: buttonContainerWidth,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                                child: sizingInformation.deviceScreenType == DeviceScreenType.mobile
                                    // Mobile layout (vertical)
                                    ? Column(
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
                                          SizedBox(height: spacing),
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
                                      )
                                    // Tablet/Desktop layout (horizontal)
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Expanded(
                                            child: AdventureButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => AdventurePage(selectedLanguage: _selectedLanguage),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          SizedBox(width: spacing),
                                          Expanded(
                                            child: ArcadeButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ArcadePage(selectedLanguage: _selectedLanguage),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Footer (full width)
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