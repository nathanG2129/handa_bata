import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/admin/widgets/admin_header_widget.dart';
import 'package:handabatamae/admin/widgets/admin_footer_widget.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  Future<void> _downloadAPK() async {
    // Replace this URL with your actual APK download URL
    const url = 'https://firebasestorage.googleapis.com/v0/b/handabatamae.appspot.com/o/Handa%20Bata%20Mobile.apk?alt=media&token=c62ef9a2-7b13-49a5-b935-add434896901';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/backgrounds/background.svg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              const AdminHeaderWidget(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: ResponsiveUtils.valueByDevice<EdgeInsets>(
                        context: context,
                        mobile: const EdgeInsets.symmetric(horizontal: 16),
                        tablet: const EdgeInsets.symmetric(horizontal: 32),
                        desktop: const EdgeInsets.symmetric(horizontal: 48),
                      ),
                      child: ResponsiveBuilder(
                        builder: (context, sizingInformation) {
                          final isTabletOrMobile = sizingInformation.deviceScreenType == DeviceScreenType.tablet || 
                                                 sizingInformation.deviceScreenType == DeviceScreenType.mobile;
                          final isMobile = sizingInformation.deviceScreenType == DeviceScreenType.mobile;

                          final characterSize = ResponsiveUtils.valueByDevice<double>(
                            context: context,
                            mobile: MediaQuery.of(context).size.width * 0.40,
                            tablet: MediaQuery.of(context).size.width * 0.30,
                            desktop: MediaQuery.of(context).size.width * 0.20,
                          );

                          final spacingMultiplier = ResponsiveUtils.valueByDevice<double>(
                            context: context,
                            mobile: 1.0,
                            tablet: 1.5,
                            desktop: 2.0,
                          );

                          if (isTabletOrMobile) {
                            // Mobile/Tablet Layout (Vertical)
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Kladis and Kloud SVG with responsive size
                                SvgPicture.asset(
                                  'assets/characters/KladisandKloud.svg',
                                  width: characterSize,
                                  height: characterSize,
                                ),
                                SizedBox(height: 20.0 * spacingMultiplier),
                                _buildContent(isMobile, context, spacingMultiplier),
                              ],
                            );
                          }

                          // Desktop Layout (Horizontal) with responsive constraints
                          return Center(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildContent(false, context, spacingMultiplier),
                                  ),
                                  SizedBox(width: 20.0 * spacingMultiplier),
                                  Expanded(
                                    flex: 2,
                                    child: SvgPicture.asset(
                                      'assets/characters/KladisandKloud.svg',
                                      width: characterSize,
                                      height: characterSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const AdminFooterWidget(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile, BuildContext context, double spacingMultiplier) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title with responsive font size
        TextWithShadow(
          text: 'Download the App',
          fontSize: screenHeight * (isMobile ? 0.04 : 0.05),
        ),
        SizedBox(height: 12.0 * spacingMultiplier),
        // Description with responsive constraints and font size
        Container(
          constraints: BoxConstraints(
            maxWidth: screenWidth * (isMobile ? 0.8 : 0.6),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 12.0 * spacingMultiplier,
          ),
          child: Text(
            'Experience Handa Bata on your mobile device! Download the latest version of our app and start your disaster preparedness journey with Kladis and Kloud.',
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(
              fontSize: screenHeight * (isMobile ? 0.018 : 0.022),
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: 24.0 * spacingMultiplier),
        // Download Button with responsive width
        Stack(
          children: [
            Button3D(
              width: screenWidth * (isMobile ? 0.5 : 0.2),
              backgroundColor: const Color(0xFFF1B33A),
              borderColor: const Color(0xFF8B5A00),
              onPressed: _downloadAPK,
              child: Text(
                'Download APK',
                style: GoogleFonts.rubik(
                  fontSize: screenHeight * (isMobile ? 0.02 : 0.025),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.0 * spacingMultiplier),
        // Version Info with responsive font size
        Text(
          'Version 1.0.1',
          style: GoogleFonts.rubik(
            fontSize: screenHeight * (isMobile ? 0.015 : 0.018),
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}