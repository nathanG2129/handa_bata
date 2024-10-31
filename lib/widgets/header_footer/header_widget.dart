import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/pages/account_settings.dart';
import 'package:handabatamae/pages/character_page.dart'; // Import CharacterPage
import 'package:handabatamae/pages/banner_page.dart'; // Import BannerPage
import 'package:handabatamae/pages/badge_page.dart'; // Import BadgePage
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:handabatamae/widgets/notifications/banner_unlock_notification.dart';

class HeaderWidget extends StatefulWidget {
  final String selectedLanguage;
  final VoidCallback onBack;
  final ValueChanged<String> onChangeLanguage;

  const HeaderWidget({
    super.key,
    required this.selectedLanguage,
    required this.onBack,
    required this.onChangeLanguage,
  });

  @override
  HeaderWidgetState createState() => HeaderWidgetState();
}

class HeaderWidgetState extends State<HeaderWidget> {
  final AuthService _authService = AuthService();
  final BannerService _bannerService = BannerService();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _checkForUnlockedBanners();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _checkForUnlockedBanners() async {
    try {
      final userProfile = await _authService.getUserProfile();
      if (userProfile == null) return;

      final int currentLevel = userProfile.level;
      final List<Map<String, dynamic>> banners = await _bannerService.fetchBanners();
      final List<int> unlockedBanners = userProfile.unlockedBanner;
      
      // Get all newly unlocked banners
      List<Map<String, dynamic>> newlyUnlockedBanners = [];
      for (int level = 1; level <= currentLevel; level++) {
        if (level <= banners.length && unlockedBanners[level - 1] != 1) {
          newlyUnlockedBanners.add(banners[level - 1]);
          unlockedBanners[level - 1] = 1;
        }
      }

      // Update unlocked banners in one go if there are any changes
      if (newlyUnlockedBanners.isNotEmpty) {
        await _authService.updateUserProfile('unlockedBanner', unlockedBanners);
        
        // Show all notifications at once
        if (mounted) {
          for (int i = 0; i < newlyUnlockedBanners.length; i++) {
            _showBannerUnlockNotification(
              newlyUnlockedBanners[i]['title'],
            );
          }
        }
      }
    } catch (e) {
      print('Error checking for unlocked banners: $e');
    }
  }

  void _showBannerUnlockNotification(String bannerTitle) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width,
        child: BannerUnlockNotification(
          bannerTitle: bannerTitle,
          onDismiss: _removeOverlay,
          onViewBanner: () {
            _removeOverlay();
            _showBanners();
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UserProfilePage(
          onClose: () {
            Navigator.of(context).pop();
          },
          selectedLanguage: widget.selectedLanguage,
        );
      },
    );
  }

  void _showAccountSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AccountSettings(
          onClose: () {
            Navigator.of(context).pop();
          },
          selectedLanguage: widget.selectedLanguage,
        );
      },
    );
  }

  void _showCharacters() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CharacterPage(
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showBanners() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BannerPage(
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showBadges() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BadgePage(
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 2, // Add padding to avoid the status bar
        left: 20,
        right: 20,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF351B61),
        border: Border(
          bottom: BorderSide(color: Colors.white, width: 2.0), // Add white border to the bottom
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 33, color: Colors.white),
            onPressed: widget.onBack,
          ),
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: const Offset(0, 0), // Adjust the horizontal offset to center the popup menu
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.person, size: 33, color: Colors.white),
                color: const Color(0xFF241242), // Set the popup menu background color
                offset: const Offset(0, 64), // Position the popup menu a bit lower
                onSelected: (String result) {
                  switch (result) {
                    case 'My Profile':
                      _showUserProfile();
                      break;
                    case 'Account Settings':
                      _showAccountSettings();
                      break;
                    case 'Characters':
                      _showCharacters();
                      break;
                    case 'Banners':
                      _showBanners();
                      break;
                    case 'Badges':
                      _showBadges();
                      break;
                    // Add cases for other menu items if needed
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'My Profile',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'My Profile',
                          style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'Characters',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Characters',
                          style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'Badges',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Badges',
                          style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'Banners',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Banners',
                          style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'Account Settings',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Account Settings',
                          style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white, size: 40),
            color: const Color(0xFF241242), // Set the popup menu background color
            offset: const Offset(0, 68), // Position the popup menu a bit lower
            onSelected: (String newValue) {
              widget.onChangeLanguage(newValue);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.selectedLanguage == 'en' ? 'English' : 'Ingles',
                      style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                    ),
                    const SizedBox(width: 8), // Add some space between text and icon
                    if (widget.selectedLanguage == 'en') const Icon(Icons.check, color: Colors.white),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'fil',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Filipino',
                      style: GoogleFonts.vt323(color: Colors.white, fontSize: 18), // Increased font size
                    ),
                    const SizedBox(width: 8), // Add some space between text and icon
                    if (widget.selectedLanguage == 'fil') const Icon(Icons.check, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}