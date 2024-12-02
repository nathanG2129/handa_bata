import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/admin/admin_login_page.dart';
import 'package:handabatamae/admin/security/admin_session.dart';
import 'package:handabatamae/services/badge_service.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'admin_pages/stage/admin_stage_page.dart';
import 'admin_pages/avatar/admin_avatar_page.dart';
import 'admin_pages/badge/admin_badge_page.dart';
import 'admin_pages/banner/admin_banner_page.dart';
import 'security/secure_route.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  AdminHomePageState createState() => AdminHomePageState();
}

class AdminHomePageState extends State<AdminHomePage> {
  @override
  void dispose() {
    AdminSession().dispose();
    super.dispose();
  }

  void _navigateToStagePage(BuildContext context) {
    AdminSession().updateActivity();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecureRoute(child: AdminStagePage())),
    );
  }

  void _navigateToAvatarPage(BuildContext context) {
    AdminSession().updateActivity();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecureRoute(child: AdminAvatarPage())),
    );
  }

  void _navigateToBadgePage(BuildContext context) async {
    AdminSession().updateActivity();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecureRoute(child: AdminBadgePage())),
    );
    
    final badgeService = BadgeService();
    await badgeService.fetchBadges(isAdmin: true);
  }

  void _navigateToBannerPage(BuildContext context) {
    AdminSession().updateActivity();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecureRoute(child: AdminBannerPage())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SecureRoute(
      child: Scaffold(
        backgroundColor: const Color(0xFF381c64),
        body: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/backgrounds/background.svg',
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                const NavBar(),
                Expanded(
                  child: ResponsiveBuilder(
                    builder: (context, sizingInformation) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final screenHeight = MediaQuery.of(context).size.height;
                      final isTabletOrMobile = sizingInformation.deviceScreenType == DeviceScreenType.tablet || 
                                             sizingInformation.deviceScreenType == DeviceScreenType.mobile;

                      final buttonSpacing = screenHeight * 0.025;
                      final contentPadding = screenWidth * (isTabletOrMobile ? 0.05 : 0.1);
                      final maxContentWidth = screenWidth * (isTabletOrMobile ? 0.9 : 0.6);

                      final buttons = [
                        {
                          'text': 'Manage Avatars',
                          'onPressed': () => _navigateToAvatarPage(context),
                        },
                        {
                          'text': 'Manage Badges',
                          'onPressed': () => _navigateToBadgePage(context),
                        },
                        {
                          'text': 'Manage Banners',
                          'onPressed': () => _navigateToBannerPage(context),
                        },
                        {
                          'text': 'Manage Stages',
                          'onPressed': () => _navigateToStagePage(context),
                        },
                      ];

                      if (isTabletOrMobile) {
                        // Vertical layout for mobile and tablet
                        return Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(contentPadding),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxContentWidth),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < buttons.length; i++) ...[
                                    if (i > 0) SizedBox(height: buttonSpacing),
                                    AdminButton(
                                      text: buttons[i]['text'] as String,
                                      onPressed: buttons[i]['onPressed'] as VoidCallback,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Grid layout for desktop
                      return Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(contentPadding),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxContentWidth),
                            child: Wrap(
                              spacing: buttonSpacing,
                              runSpacing: buttonSpacing,
                              alignment: WrapAlignment.center,
                              children: buttons.map((button) => SizedBox(
                                width: (maxContentWidth - buttonSpacing) / 2,
                                child: AdminButton(
                                  text: button['text'] as String,
                                  onPressed: button['onPressed'] as VoidCallback,
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await AdminSession().endSession();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isTabletOrMobile = sizingInformation.deviceScreenType == DeviceScreenType.tablet || 
                               sizingInformation.deviceScreenType == DeviceScreenType.mobile;

        final navHeight = screenHeight * (isTabletOrMobile ? 0.08 : 0.1);
        final horizontalPadding = MediaQuery.of(context).size.width * (isTabletOrMobile ? 0.04 : 0.06);
        final titleFontSize = screenHeight * (isTabletOrMobile ? 0.03 : 0.04);
        final iconSize = screenHeight * (isTabletOrMobile ? 0.025 : 0.03);

        return Container(
          height: navHeight,
          color: const Color(0xFF381c64),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: navHeight * 0.2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Admin Panel',
                style: GoogleFonts.vt323(
                  color: Colors.white,
                  fontSize: titleFontSize,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.logout,
                  size: iconSize,
                  color: Colors.white,
                ),
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AdminButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isTabletOrMobile = sizingInformation.deviceScreenType == DeviceScreenType.tablet || 
                               sizingInformation.deviceScreenType == DeviceScreenType.mobile;

        final buttonHeight = screenHeight * (isTabletOrMobile ? 0.08 : 0.1);
        final fontSize = screenHeight * (isTabletOrMobile ? 0.025 : 0.03);
        final padding = EdgeInsets.symmetric(
          vertical: buttonHeight * 0.2,
          horizontal: buttonHeight * 0.4,
        );

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF381c64),
            borderRadius: BorderRadius.circular(buttonHeight * 0.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: buttonHeight * 0.1,
                offset: Offset(0, buttonHeight * 0.05),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF381c64),
              shadowColor: Colors.transparent,
              padding: padding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonHeight * 0.1),
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}