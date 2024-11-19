import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/pages/splash_page.dart';
import 'package:handabatamae/pages/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handabatamae/pages/play_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/hotlines_page.dart';
import 'package:handabatamae/pages/about_page.dart';

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
  
  // Add these ValueNotifiers to track expansion state
  final ValueNotifier<bool> _learnExpanded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _resourcesExpanded = ValueNotifier<bool>(false);

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
    // Clean up the notifiers
    _learnExpanded.dispose();
    _resourcesExpanded.dispose();
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 1,
        color: Colors.white,
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
                            _buildDivider(),
                            _buildExpandableMenuItem('Learn', [
                              'About Earthquakes',
                              'Disastrous Earthquakes in the Philippines',
                              'Preparing for Earthquakes',
                            ], isEarthquakes: true),
                            _buildDivider(),
                            _buildExpandableMenuItem('Resources', [
                              'Resource 1',
                              'Resource 2',
                              'Resource 3',
                            ]),
                            _buildDivider(),
                            _buildMenuItem('Hotlines', onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HotlinesPage(
                                    selectedLanguage: widget.selectedLanguage,
                                  ),
                                ),
                              );
                              _closeDrawer();
                            }),
                            _buildDivider(),
                            _buildMenuItem('About', onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AboutPage(
                                    selectedLanguage: widget.selectedLanguage,
                                  ),
                                ),
                              );
                              _closeDrawer();
                            }),
                            _buildDivider(),
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

  Widget _buildExpandableMenuItem(String title, List<String> items, {bool isEarthquakes = false}) {
    // Use the appropriate ValueNotifier based on the title
    final expandedNotifier = title == 'Learn' ? _learnExpanded : _resourcesExpanded;
    
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
        trailing: ValueListenableBuilder<bool>(
          valueListenable: expandedNotifier,
          builder: (context, isExpanded, _) {
            return SvgPicture.asset(
              isExpanded ? 'assets/icons/minus.svg' : 'assets/icons/plus.svg',
              width: 24,
              height: 24,
              color: Colors.white,
            );
          },
        ),
        onExpansionChanged: (expanded) {
          expandedNotifier.value = expanded;
        },
        children: [
          if (isEarthquakes) ...[
            _buildSubmenuItem('About Earthquakes'),
            _buildSubmenuItem('Disastrous Earthquakes in the Philippines'),
            _buildSubmenuItem('Preparing for Earthquakes'),
          ] else ...[
            ...items.map((item) => _buildSubmenuItem(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmenuItem(String title) {
    return InkWell(
      onTap: () {
        // Handle submenu item tap
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 36, right: 20, top: 12, bottom: 12),
        child: Text(
          title,
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
} 