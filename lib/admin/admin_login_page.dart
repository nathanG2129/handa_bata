import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/admin/widgets/admin_header_widget.dart';
import 'package:handabatamae/admin/widgets/admin_footer_widget.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:url_launcher/url_launcher.dart';

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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ResponsiveBuilder(
                        builder: (context, sizingInformation) {
                          final isTabletOrMobile = sizingInformation.deviceScreenType == DeviceScreenType.tablet || 
                                                 sizingInformation.deviceScreenType == DeviceScreenType.mobile;

                          if (isTabletOrMobile) {
                            // Mobile/Tablet Layout (Vertical)
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Kladis and Kloud SVG
                                SvgPicture.asset(
                                  'assets/characters/KladisandKloud.svg',
                                  width: 300,
                                  height: 300,
                                ),
                                const SizedBox(height: 40),
                                _buildContent(),
                              ],
                            );
                          }

                          // Desktop Layout (Horizontal)
                          return Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left side - Content
                                  Expanded(
                                    flex: 3,
                                    child: _buildContent(),
                                  ),
                                  const SizedBox(width: 20),
                                  // Right side - Kladis and Kloud SVG
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

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title
        const TextWithShadow(
          text: 'Download the App',
          fontSize: 48,
        ),
        const SizedBox(height: 20),
        // Description
        Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Experience Handa Bata on your mobile device! Download the latest version of our app and start your disaster preparedness journey with Kladis and Kloud.',
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(
              fontSize: 18,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Download Button with Stacked Icon
        Stack(
          children: [
            Button3D(
              width: 250,
              backgroundColor: const Color(0xFFF1B33A),
              borderColor: const Color(0xFF8B5A00),
              onPressed: _downloadAPK,
              child: Text(
                'Download APK',
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Version Info
        Text(
          'Version 1.0.0',
          style: GoogleFonts.rubik(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}