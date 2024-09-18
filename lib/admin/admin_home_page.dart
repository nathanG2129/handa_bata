import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_pages/avatar/stage/admin_stage_page.dart';
import 'admin_pages/avatar/admin_avatar_page.dart';
import 'admin_pages/badge/admin_badge_page.dart';
import 'admin_banner_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  void _navigateToStagePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminStagePage()),
    );
  }

  void _navigateToAvatarPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminAvatarPage()),
    );
  }

  void _navigateToBadgePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminBadgePage()),
    );
  }

  void _navigateToBannerPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminBannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.vt323TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: Scaffold(
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
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AdminButton(
                            text: 'Manage Avatars',
                            onPressed: () => _navigateToAvatarPage(context),
                          ),
                          const SizedBox(height: 20),
                          AdminButton(
                            text: 'Manage Badges',
                            onPressed: () => _navigateToBadgePage(context),
                          ),
                          const SizedBox(height: 20),
                          AdminButton(
                            text: 'Manage Banners',
                            onPressed: () => _navigateToBannerPage(context),
                          ),
                          const SizedBox(height: 20),
                          AdminButton(
                            text: 'Manage Stages',
                            onPressed: () => _navigateToStagePage(context),
                          ),
                        ],
                      ),
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF381c64),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Admin Panel', style: GoogleFonts.vt323(color: Colors.white, fontSize: 35)),
      ),
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
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF381c64),
        shadowColor: Colors.transparent, // Remove button highlight
      ),
      child: Text(
        text,
        style: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
      ),
    );
  }
}