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
import 'package:handabatamae/pages/learn_page.dart';
import 'package:handabatamae/pages/resources_page.dart';
import 'package:handabatamae/widgets/loading_widget.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

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
  final ValueNotifier<bool> _earthquakesExpanded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _typhoonsExpanded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _otherInfoExpanded = ValueNotifier<bool>(false);

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
    _earthquakesExpanded.dispose();
    _typhoonsExpanded.dispose();
    _otherInfoExpanded.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _closeDrawer() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onClose();
    }
  }

  Future<void> _logout() async {
    try {
      await _closeDrawer();
      if (!mounted) return;

      AuthService authService = AuthService();
      await authService.signOut();
      
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

  void _navigateToRegister() async {
    await _closeDrawer();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationPage(selectedLanguage: widget.selectedLanguage),
        ),
      );
    }
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
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final drawerWidth = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: MediaQuery.of(context).size.width * 0.75,  // 75% width for mobile
          tablet: MediaQuery.of(context).size.width * 0.5,   // 50% width for tablet
          desktop: MediaQuery.of(context).size.width * 0.4,  // 40% width for desktop
        );

        final menuFontSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 20.0,
          tablet: 22.0,
          desktop: 24.0,
        );

        final submenuFontSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 18.0,
          tablet: 20.0,
          desktop: 22.0,
        );

        final menuPadding = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        );

        final submenuPadding = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 36.0,
          tablet: 40.0,
          desktop: 44.0,
        );

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
                          width: drawerWidth,
                          color: const Color(0xFF241242),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMenuItem(
                                  widget.selectedLanguage == 'en' ? 'Play' : 'Maglaro',
                                  fontSize: menuFontSize,
                                  padding: menuPadding,
                                  onTap: () async {
                                    // Show loading overlay
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return WillPopScope(
                                          onWillPop: () async => false,
                                          child: const LoadingWidget(),
                                        );
                                      },
                                    );

                                    // Close drawer first
                                    await _closeDrawer();
                                    
                                    if (mounted) {
                                      // Remove loading overlay
                                      Navigator.of(context).pop();
                                      
                                      // Use pushReplacement to navigate to PlayPage
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PlayPage(
                                            title: 'Play',
                                            selectedLanguage: widget.selectedLanguage,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                _buildDivider(),
                                _buildExpandableMenuItem(
                                  widget.selectedLanguage == 'en' ? 'Learn' : 'Matuto',
                                  fontSize: menuFontSize,
                                  padding: menuPadding,
                                  submenuPadding: submenuPadding,
                                  submenuFontSize: submenuFontSize,
                                  items: [],
                                  isLearn: true,
                                ),
                                _buildDivider(),
                                _buildExpandableMenuItem(
                                  widget.selectedLanguage == 'en' ? 'Resources' : 'Mga Resources',
                                  expandedNotifier: _resourcesExpanded,
                                  fontSize: menuFontSize,
                                  padding: menuPadding,
                                  submenuPadding: submenuPadding,
                                  submenuFontSize: submenuFontSize,
                                ),
                                _buildDivider(),
                                _buildMenuItem(
                                  widget.selectedLanguage == 'en' ? 'Hotlines' : 'Mga Hotline',
                                  fontSize: menuFontSize,
                                  padding: menuPadding,
                                  onTap: () async {
                                    // Show loading overlay
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return WillPopScope(
                                          onWillPop: () async => false,
                                          child: const LoadingWidget(),
                                        );
                                      },
                                    );

                                    // Close drawer first
                                    await _closeDrawer();
                                    
                                    if (mounted) {
                                      // Remove loading overlay
                                      Navigator.of(context).pop();
                                      
                                      // Navigate to Hotlines page
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HotlinesPage(
                                            selectedLanguage: widget.selectedLanguage,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                ),
                                _buildDivider(),
                                _buildMenuItem(
                                  widget.selectedLanguage == 'en' ? 'About' : 'Tungkol Sa',
                                  fontSize: menuFontSize,
                                  padding: menuPadding,
                                  onTap: () async {
                                    // Show loading overlay
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return WillPopScope(
                                          onWillPop: () async => false,
                                          child: const LoadingWidget(),
                                        );
                                      },
                                    );

                                    // Close drawer first
                                    await _closeDrawer();
                                    
                                    if (mounted) {
                                      // Remove loading overlay
                                      Navigator.of(context).pop();
                                      
                                      // Navigate to About page
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AboutPage(
                                            selectedLanguage: widget.selectedLanguage,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                ),
                                _buildDivider(),
                                const SizedBox(height: 8),
                                _buildMenuItem(
                                  _userRole == 'guest' 
                                    ? (widget.selectedLanguage == 'en' ? 'Register' : 'Magparehistro')
                                    : (widget.selectedLanguage == 'en' ? 'Log out' : 'Mag-log out'),
                                  fontSize: menuFontSize,
                                  padding: menuPadding,
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
      },
    );
  }

  Widget _buildMenuItem(String title, {
    required VoidCallback onTap,
    required double fontSize,
    required double padding,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.75),
        child: Text(
          title,
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableMenuItem(
    String title, {
    bool isLearn = false,
    List<String>? items,
    ValueNotifier<bool>? expandedNotifier,
    List<Widget>? children,
    required double fontSize,
    required double padding,
    required double submenuPadding,
    required double submenuFontSize,
  }) {
    final notifier = expandedNotifier ?? (title == 'Learn' || title == 'Matuto' ? _learnExpanded : _resourcesExpanded);
    
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
        trailing: ValueListenableBuilder<bool>(
          valueListenable: notifier,
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
          notifier.value = expanded;
        },
        children: children ?? [
          if (isLearn) ...[
            _buildExpandableMenuItem(
              widget.selectedLanguage == 'en' ? 'Earthquakes' : 'Lindol',
              expandedNotifier: _earthquakesExpanded,
              fontSize: fontSize,
              padding: padding,
              submenuPadding: submenuPadding,
              submenuFontSize: submenuFontSize,
              children: [
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'About Earthquakes' : 'Tungkol sa Lindol',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'Disastrous Earthquakes in the Philippines' : 'Mga Mapaminsalang Lindol sa Pilipinas',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'Preparing for Earthquakes' : 'Paghahanda para sa Lindol',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'Earthquake Intensity Scale' : 'Panukat ng Lakas ng Lindol',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
              ],
            ),
            _buildExpandableMenuItem(
              widget.selectedLanguage == 'en' ? 'Typhoons' : 'Bagyo',
              expandedNotifier: _typhoonsExpanded,
              fontSize: fontSize,
              padding: padding,
              submenuPadding: submenuPadding,
              submenuFontSize: submenuFontSize,
              children: [
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'About Typhoons' : 'Tungkol sa Bagyo',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'Disastrous Typhoons in the Philippines' : 'Mga Mapaminsalang Bagyo sa Pilipinas',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'Preparing for Typhoons' : 'Paghahanda para sa Bagyo',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'Tropical Cyclone Warning Systems' : 'Tropical Cyclone Warning System',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'Rainfall Warning System' : 'Rainfall Warning System',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
              ],
            ),
            _buildExpandableMenuItem(
              widget.selectedLanguage == 'en' ? 'Other Information' : 'Iba Pang Impormasyon',
              expandedNotifier: _otherInfoExpanded,
              fontSize: fontSize,
              padding: padding,
              submenuPadding: submenuPadding,
              submenuFontSize: submenuFontSize,
              children: [
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'Guidelines on the Cancellation or Suspension of Classes' : 'Mga Alituntunin sa Pagkansela or Pagsuspinde ng Klase',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
                _buildSubmenuItem(
                  widget.selectedLanguage == 'en' ? 'Emergency Go Bag' : 'Emergency Go Bag',
                  fontSize: submenuFontSize,
                  padding: submenuPadding,
                ),
              ],
            ),
          ] else if (title == 'Resources' || title == 'Mga Resources') ...[
            _buildSubmenuItem(
              widget.selectedLanguage == 'en' ? 'Infographics' : 'Mga Infographic',
              fontSize: submenuFontSize,
              padding: submenuPadding,
              onTap: () async {
                // Show loading overlay
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: const LoadingWidget(),
                    );
                  },
                );

                // Close drawer first
                await _closeDrawer();
                
                if (mounted) {
                  // Remove loading overlay
                  Navigator.of(context).pop();
                  
                  // Use pushReplacement instead of push to prevent going back
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResourcesPage(
                        selectedLanguage: widget.selectedLanguage,
                        category: 'Infographics',
                      ),
                    ),
                  );
                }
              },
            ),
            _buildSubmenuItem(
              widget.selectedLanguage == 'en' ? 'Videos' : 'Mga Video',
              fontSize: submenuFontSize,
              padding: submenuPadding,
              onTap: () async {
                // Show loading overlay
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: const LoadingWidget(),
                    );
                  },
                );

                // Close drawer first
                await _closeDrawer();
                
                if (mounted) {
                  // Remove loading overlay
                  Navigator.of(context).pop();
                  
                  // Use pushReplacement instead of push to prevent going back
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResourcesPage(
                        selectedLanguage: widget.selectedLanguage,
                        category: 'Videos',
                      ),
                    ),
                  );
                }
              },
            ),
          ] else if (items != null) ...[
            ...items.map((item) => _buildSubmenuItem(item, fontSize: submenuFontSize, padding: submenuPadding)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmenuItem(
    String title, {
    VoidCallback? onTap,
    required double fontSize,
    required double padding,
  }) {
    String getCategory(String title) {
      // Get the English category title regardless of display language
      switch (title) {
        case 'Earthquake Intensity Scale':
        case 'Panukat ng Lakas ng Lindol':
          return 'Other Information';
        case 'Rainfall Warning System':
        case 'Sistema ng Babala sa Pag-ulan':
          return 'Other Information';
        case 'Tropical Cyclone Warning Systems':
        case 'Sistema ng Babala sa mga Bagyo':
          return 'Other Information';
        case 'About Earthquakes':
        case 'Tungkol sa Lindol':
        case 'Disastrous Earthquakes in the Philippines':
        case 'Mga Mapaminsalang Lindol sa Pilipinas':
        case 'Preparing for Earthquakes':
        case 'Paghahanda para sa Lindol':
          return 'Earthquakes';
        case 'About Typhoons':
        case 'Tungkol sa Bagyo':
        case 'Disastrous Typhoons in the Philippines':
        case 'Mga Mapaminsalang Bagyo sa Pilipinas':
        case 'Preparing for Typhoons':
        case 'Paghahanda para sa Bagyo':
          return 'Typhoons';
        case 'Guidelines on the Cancellation or Suspension of Classes':
        case 'Mga Alituntunin sa Pagkansela or Pagsuspinde ng Klase':
        case 'Emergency Go Bag':
          return 'Other Information';
        default:
          return 'Other Information';
      }
    }

    String getEnglishTitle(String title) {
      // Map Filipino titles back to English for JSON keys
      switch (title) {
        case 'Tungkol sa Lindol':
          return 'About Earthquakes';
        case 'Mga Mapaminsalang Lindol sa Pilipinas':
          return 'Disastrous Earthquakes in the Philippines';
        case 'Paghahanda para sa Lindol':
          return 'Preparing for Earthquakes';
        case 'Panukat ng Lakas ng Lindol':
          return 'Earthquake Intensity Scale';
        case 'Tungkol sa Bagyo':
          return 'About Typhoons';
        case 'Mga Mapaminsalang Bagyo sa Pilipinas':
          return 'Disastrous Typhoons in the Philippines';
        case 'Paghahanda para sa Bagyo':
          return 'Preparing for Typhoons';
        case 'Tropical Cyclone Warning System':
          return 'Tropical Cyclone Warning Systems';
        case 'Rainfall Warning System':
          return 'Rainfall Warning System';
        case 'Mga Alituntunin sa Pagkansela or Pagsuspinde ng Klase':
          return 'Guidelines on the Cancellation or Suspension of Classes';
        case 'Emergency Go Bag':
          return 'Emergency Go Bag';
        default:
          return title;
      }
    }

    return InkWell(
      onTap: onTap ?? () async {
        final category = getCategory(title);
        final englishTitle = getEnglishTitle(title);
        
        // Store navigation data using English titles for JSON keys
        final navigationData = {
          'category': category,
          'title': englishTitle,
        };

        // Show loading overlay
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => false,
              child: const LoadingWidget(),
            );
          },
        );

        // Close drawer first
        if (mounted) {
          await _closeDrawer();
        }

        // Then navigate, removing the loading overlay
        if (mounted) {
          Navigator.of(context).pop(); // Remove loading overlay
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LearnPage(
                selectedLanguage: widget.selectedLanguage,
                category: navigationData['category']!,
                title: navigationData['title']!,
                onBack: () {
                  Navigator.pop(context);
                },
                onLanguageChange: (String newLanguage) {
                },
              ),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: padding,
          right: padding * 0.6,
          top: padding * 0.6,
          bottom: padding * 0.6,
        ),
        child: Text(
          title,
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
} 