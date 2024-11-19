import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/pages/splash_page.dart';
import 'package:handabatamae/pages/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handabatamae/pages/play_page.dart';

class MenuDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final String selectedLanguage;

  const MenuDrawer({
    super.key,
    required this.onClose,
    required this.selectedLanguage,
  });

  @override
  MenuDrawerState createState() => MenuDrawerState();
}

class MenuDrawerState extends State<MenuDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String _userRole = 'guest';

  @override
  void initState() {
    super.initState();
    _initializeUserRole();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  Future<void> _initializeUserRole() async {
    final authService = AuthService();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await authService.getUserRole(user.uid);
      if (mounted) {
        setState(() {
          _userRole = role ?? 'guest';
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _closeDrawer() async {
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _logout() async {
    try {
      AuthService authService = AuthService();
      await authService.signOut();
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SplashPage(selectedLanguage: widget.selectedLanguage)),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationPage(selectedLanguage: widget.selectedLanguage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final headerHeight = statusBarHeight + 60;

    return Material(
      type: MaterialType.transparency,
      child: WillPopScope(
        onWillPop: () async {
          await _closeDrawer();
          return false;
        },
        child: GestureDetector(
          onTap: _closeDrawer,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Stack(
              children: [
                Positioned(
                  top: headerHeight,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {},
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.75,
                        color: const Color(0xFF241242),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMenuItem('Play', onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayPage(
                                      title: 'Play',
                                      selectedLanguage: widget.selectedLanguage,
                                    ),
                                  ),
                                );
                                _closeDrawer();
                              }),
                              _buildExpandableMenuItem('Learn', [
                                'Earthquake',
                                'Storm',
                                'Flood',
                                'Tsunami',
                                'Volcano',
                                'Drought',
                              ]),
                              _buildExpandableMenuItem('Resources', [
                                'Resource 1',
                                'Resource 2',
                                'Resource 3',
                              ]),
                              _buildMenuItem('Hotlines', onTap: () {}),
                              _buildMenuItem('About', onTap: () {}),
                              const SizedBox(height: 8),
                              _buildMenuItem(
                                _userRole == 'guest' ? 'Register' : 'Log out',
                                onTap: _userRole == 'guest' ? _navigateToRegister : _logout,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Text(
          title,
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableMenuItem(String title, List<String> items) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: _buildMenuItem(
              item,
              onTap: () {
                // Handle submenu item tap
              },
            ),
          );
        }).toList(),
      ),
    );
  }
} 