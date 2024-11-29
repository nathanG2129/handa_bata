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
    const url = 'https://firebasestorage.googleapis.com/v0/b/handabatamae.appspot.com/o/HBMobile_ReleaseV6.apk?alt=media&token=f9f2d1c3-c3c8-48cb-b281-42e3646af8e7';
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
                        tablet: const EdgeInsets.symmetric(horizontal: 20),
                        desktop: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: ResponsiveBuilder(
                        builder: (context, sizingInformation) {
                          final isTabletOrMobile = sizingInformation.deviceScreenType == DeviceScreenType.tablet || 
                                                 sizingInformation.deviceScreenType == DeviceScreenType.mobile;
                          final isMobile = sizingInformation.deviceScreenType == DeviceScreenType.mobile;

                          if (isTabletOrMobile) {
                            // Mobile/Tablet Layout (Vertical)
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Kladis and Kloud SVG with responsive size
                                SvgPicture.asset(
                                  'assets/characters/KladisandKloud.svg',
                                  width: ResponsiveUtils.valueByDevice<double>(
                                    context: context,
                                    mobile: 200,
                                    tablet: 300,
                                  ),
                                  height: ResponsiveUtils.valueByDevice<double>(
                                    context: context,
                                    mobile: 200,
                                    tablet: 300,
                                  ),
                                ),
                                SizedBox(height: isMobile ? 20 : 40),
                                _buildContent(isMobile, context),
                              ],
                            );
                          }

                          // Desktop Layout (Horizontal) with responsive constraints
                          return Center(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: ResponsiveUtils.valueByDevice<double>(
                                  context: context,
                                  mobile: 600,
                                  tablet: 900,
                                  desktop: 1200,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildContent(false, context),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 2,
                                    child: SvgPicture.asset(
                                      'assets/characters/KladisandKloud.svg',
                                      width: 350,
                                      height: 350,
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

  Widget _buildContent(bool isMobile, BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title with responsive font size
        TextWithShadow(
          text: 'Download the App',
          fontSize: ResponsiveUtils.valueByDevice<double>(
            context: context,
            mobile: 32,
            tablet: 40,
            desktop: 48,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 20),
        // Description with responsive constraints and font size
        Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 300,
              tablet: 400,
              desktop: 500,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 12,
              tablet: 20,
              desktop: 20,
            ),
          ),
          child: Text(
            'Experience Handa Bata on your mobile device! Download the latest version of our app and start your disaster preparedness journey with Kladis and Kloud.',
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(
              fontSize: ResponsiveUtils.valueByDevice<double>(
                context: context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 24 : 40),
        // Download Button with responsive width
        Stack(
          children: [
            Button3D(
              width: ResponsiveUtils.valueByDevice<double>(
                context: context,
                mobile: 200,
                tablet: 220,
                desktop: 250,
              ),
              backgroundColor: const Color(0xFFF1B33A),
              borderColor: const Color(0xFF8B5A00),
              onPressed: _downloadAPK,
              child: Text(
                'Download APK',
                style: GoogleFonts.rubik(
                  fontSize: ResponsiveUtils.valueByDevice<double>(
                    context: context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12 : 20),
        // Version Info with responsive font size
        Text(
          'Version 1.0.0',
          style: GoogleFonts.rubik(
            fontSize: ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 12,
              tablet: 13,
              desktop: 14,
            ),
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}