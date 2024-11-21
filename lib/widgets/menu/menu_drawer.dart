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
    print('🚪 Closing drawer');
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
                            _buildMenuItem('Play', onTap: () async {
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
                            }),
                            _buildDivider(),
                            _buildExpandableMenuItem(
                              'Learn',
                              items: [],
                              isLearn: true,
                            ),
                            _buildDivider(),
                            _buildExpandableMenuItem(
                              'Resources',
                              expandedNotifier: _resourcesExpanded,
                            ),
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
        
        // Then navigate, removing the loading overlay
        if (mounted) {
          Navigator.of(context).pop(); // Remove loading overlay
          
          // Handle navigation based on title
          switch (title) {
            case 'Hotlines':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HotlinesPage(
                    selectedLanguage: widget.selectedLanguage,
                  ),
                ),
              );
              break;
            case 'About':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutPage(
                    selectedLanguage: widget.selectedLanguage,
                  ),
                ),
              );
              break;
            default:
              onTap();
          }
        }
      },
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

  Widget _buildExpandableMenuItem(String title, {
    bool isLearn = false,
    List<String>? items,
    ValueNotifier<bool>? expandedNotifier,
    List<Widget>? children,
  }) {
    final notifier = expandedNotifier ?? (title == 'Learn' ? _learnExpanded : _resourcesExpanded);
    
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
            // Earthquakes section
            _buildExpandableMenuItem(
              'Earthquakes',
              expandedNotifier: _earthquakesExpanded,
              children: [
                _buildSubmenuItem('About Earthquakes'),
                _buildSubmenuItem('Disastrous Earthquakes in the Philippines'),
                _buildSubmenuItem('Preparing for Earthquakes'),
                _buildSubmenuItem('Earthquake Intensity Scale'),
              ],
            ),
            // Typhoons section
            _buildExpandableMenuItem(
              'Typhoons',
              expandedNotifier: _typhoonsExpanded,
              children: [
                _buildSubmenuItem('About Typhoons'),
                _buildSubmenuItem('Disastrous Typhoons in the Philippines'),
                _buildSubmenuItem('Preparing for Typhoons'),
                _buildSubmenuItem('Tropical Cyclone Warning Systems'),
                _buildSubmenuItem('Rainfall Warning System'),
              ],
            ),
            // Other Information section
            _buildExpandableMenuItem(
              'Other Information',
              expandedNotifier: _otherInfoExpanded,
              children: [
                _buildSubmenuItem('Guidelines on the Cancellation or Suspension of Classes'),
                _buildSubmenuItem('Emergency Go Bag'),
              ],
            ),
          ] else if (title == 'Resources') ...[
            // Resources submenu items
            _buildSubmenuItem(
              'Infographics',
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
              'Videos',
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
            ...items.map((item) => _buildSubmenuItem(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmenuItem(String title, {VoidCallback? onTap}) {
    String getCategory(String title) {
      // First, map the display title to the JSON key
      // ignore: unused_local_variable
      String jsonTitle = title;
      switch (title) {
        case 'Earthquake Intensity Scale':
          jsonTitle = 'Other Information/Earthquake Intensity Scale';
          return 'Other Information';
        case 'Rainfall Warning System':
          jsonTitle = 'Other Information/Rainfall Warning System';
          return 'Other Information';
        case 'Tropical Cyclone Warning Systems':
          jsonTitle = 'Other Information/Tropical Cyclone Warning Systems';
          return 'Other Information';
        case 'About Earthquakes':
        case 'Disastrous Earthquakes in the Philippines':
        case 'Preparing for Earthquakes':
          return 'Earthquakes';
        case 'About Typhoons':
        case 'Disastrous Typhoons in the Philippines':
        case 'Preparing for Typhoons':
          return 'Typhoons';
        case 'Guidelines on the Cancellation or Suspension of Classes':
        case 'Emergency Go Bag':
          return 'Other Information';
        default:
          print('⚠️ Warning: No category mapping for title: $title');
          return 'Other Information';
      }
    }

    return InkWell(
      onTap: onTap ?? () async {
        final category = getCategory(title);
        print('🔍 Selected learn item: $title in category: $category');
        
        // Store navigation data
        final navigationData = {
          'category': category,
          'title': title,
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LearnPage(
                selectedLanguage: widget.selectedLanguage,
                category: navigationData['category']!,
                title: navigationData['title']!,
                onBack: () {
                  print('↩️ Navigating back from Learn');
                  Navigator.pop(context);
                },
                onLanguageChange: (String newLanguage) {
                  print('🌐 Language changed to: $newLanguage');
                },
              ),
            ),
          );
        }
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