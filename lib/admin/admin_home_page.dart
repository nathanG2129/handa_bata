import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/admin/admin_login_page.dart';
import 'package:handabatamae/admin/security/admin_session.dart';
import 'package:handabatamae/services/badge_service.dart';
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
    print('\n🧹 DISPOSING ADMIN HOME PAGE');
    print('🔄 Cleaning up admin session...');
    AdminSession().dispose();
    print('✅ Admin session cleanup complete');
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
    print('\n🏠 BUILDING ADMIN HOME PAGE');
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
                NavBar(),
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
  Future<void> _handleLogout(BuildContext context) async {
    await AdminSession().endSession();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF381c64),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Admin Panel', style: GoogleFonts.vt323(color: Colors.white, fontSize: 35)),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
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