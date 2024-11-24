import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/pages/account_settings.dart';
import 'package:handabatamae/pages/character_page.dart'; // Import CharacterPage
import 'package:handabatamae/pages/banner_page.dart'; // Import BannerPage
import 'package:handabatamae/pages/badge_page.dart'; // Import BadgePage
import 'package:handabatamae/services/avatar_service.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/shared/connection_quality.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/widgets/menu/menu_drawer.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

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
  final UserProfileService _userProfileService = UserProfileService();
  int? _currentAvatarId;

  String? _cachedAvatarPath;

  final AvatarService _avatarService = AvatarService();

  late StreamSubscription<UserProfile> _profileSubscription;

  late StreamSubscription<Map<int, String>> _avatarSubscription;

  late StreamSubscription<ConnectionQuality> _connectionSubscription;

  // ignore: unused_field
  ConnectionQuality _currentQuality = ConnectionQuality.GOOD;

  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    
    // Initial profile fetch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = await _userProfileService.fetchUserProfile();
      if (mounted && profile != null) {
        setState(() {
          _currentAvatarId = profile.avatarId;
          // Try to get cached avatar immediately
          _updateAvatarImage(profile.avatarId);
        });
      }
    });

    // Listen to profile updates
    _profileSubscription = _userProfileService.profileUpdates.listen((profile) {
      print('📱 HeaderWidget received profile update');
      print('New Avatar ID: ${profile.avatarId}');
      
      if (mounted && profile.avatarId != _currentAvatarId) {
        setState(() {
          _currentAvatarId = profile.avatarId;
          _cachedAvatarPath = null; // Clear cached path to force refresh
        });
        _updateAvatarImage(profile.avatarId);
      }
    });

    // Listen to avatar updates
    _avatarSubscription = _avatarService.avatarUpdates.listen((updates) {
      print('📱 HeaderWidget received avatar update');
      if (mounted && _currentAvatarId != null && updates.containsKey(_currentAvatarId)) {
        setState(() {
          _cachedAvatarPath = updates[_currentAvatarId];
        });
      }
    });

    // Add connection quality listener
    _connectionSubscription = _avatarService.connectionQuality.listen((quality) {
      if (mounted) {
        setState(() => _currentQuality = quality);
      }
    });
  }

  Future<void> _updateAvatarImage(int avatarId) async {
    try {
      // Strong cache check
      if (_cachedAvatarPath != null && _currentAvatarId == avatarId) {
        print('📦 Using cached avatar image');
        return;
      }

      print('🔄 Updating avatar image for ID: $avatarId');
      
      // Get from service with cache
      final avatar = await _avatarService.getAvatarDetails(
        avatarId,
        priority: LoadPriority.HIGH,
      );
      
      if (mounted && avatar != null) {
        print('✅ Got new avatar image: ${avatar['img']}');
        setState(() {
          _cachedAvatarPath = avatar['img'];
          _currentAvatarId = avatarId;
        });
      }
    } catch (e) {
      print('❌ Error updating avatar image: $e');
    }
  }

  @override
  void dispose() {
    _profileSubscription.cancel();
    _avatarSubscription.cancel();
    _connectionSubscription.cancel();
    super.dispose();
  }

  String _getCloseMenuSvg() {
    return '''
      <svg
        width="100%"
        height="100%"
        fill="white"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
      >
        <path
          d="M5 5h2v2H5V5zm4 4H7V7h2v2zm2 2H9V9h2v2zm2 0h-2v2H9v2H7v2H5v2h2v-2h2v-2h2v-2h2v2h2v2h2v2h2v-2h-2v-2h-2v-2h-2v-2zm2-2v2h-2V9h2zm2-2v2h-2V7h2zm0 0V5h2v2h-2z"
          fill="currentColor"
        />
      </svg>
    ''';
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
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CharacterPage(
          selectionMode: false,
          currentAvatarId: _currentAvatarId,
          onAvatarSelected: (newAvatarId) async {
            try {
              // Use UserProfileService for consistent updates
              await _userProfileService.updateProfileWithIntegration('avatarId', newAvatarId);
              Navigator.of(context).pop();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update avatar: $e')),
                );
              }
            }
          },
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

  Widget _buildAvatarButton() {
    final double avatarRadius = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: 20,  // Smaller for mobile
      tablet: 24,
      desktop: 24,
    );

    return PopupMenuButton<String>(
      color: const Color(0xFF241242),
      offset: const Offset(0, 64),
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
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: Colors.white,
        child: _cachedAvatarPath != null 
          ? Container(
              width: avatarRadius * 1.5,  // Adjusted proportionally
              height: avatarRadius * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                image: DecorationImage(
                  image: AssetImage('assets/avatars/$_cachedAvatarPath'),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                ),
              ),
            )
          : const CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final bool isMobileLargeOrSmaller = sizingInformation.deviceScreenType == DeviceScreenType.mobile &&
            MediaQuery.of(context).size.width <= 414;  // mobileLarge breakpoint

        return Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 4,  // Reduced padding for mobile
              tablet: 12,
              desktop: 16,
            ),
            left: ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 12,  // Reduced padding for mobile
              tablet: 20,
              desktop: 24,
            ),
            right: ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 12,  // Reduced padding for mobile
              tablet: 20,
              desktop: 24,
            ),
            bottom: ResponsiveUtils.valueByDevice(
              context: context,
              mobile: 8,  // Reduced padding for mobile
              tablet: 14,
              desktop: 16,
            ),
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF351B61),
            border: Border(
              bottom: BorderSide(color: Colors.white, width: 2.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, 2),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    size: isMobileLargeOrSmaller ? 24 : 32,  // Smaller icon for mobile
                    color: Colors.white
                  ),
                  onPressed: widget.onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 2),
                    child: _buildAvatarButton(),
                  ),
                  SizedBox(width: isMobileLargeOrSmaller ? 12 : 18),  // Reduced spacing
                  Transform.translate(
                    offset: const Offset(0, 2),
                    child: PopupMenuButton<String>(
                      icon: SvgPicture.asset(
                        'assets/icons/language_switcher.svg',
                        width: isMobileLargeOrSmaller ? 24 : 32,  // Smaller for mobile
                        height: isMobileLargeOrSmaller ? 24 : 32,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      offset: const Offset(0, 65),
                      color: const Color(0xFF241242),
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
                                style: GoogleFonts.vt323(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (widget.selectedLanguage == 'en') 
                                SvgPicture.asset(
                                  'assets/icons/check.svg',
                                  width: 24,
                                  height: 24,
                                  color: Colors.white,
                                ),
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
                                style: GoogleFonts.vt323(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (widget.selectedLanguage == 'fil') 
                                SvgPicture.asset(
                                  'assets/icons/check.svg',
                                  width: 24,
                                  height: 24,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Transform.translate(
                    offset: const Offset(0, 2),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: SvgPicture.string(
                        _isMenuOpen ? _getCloseMenuSvg() : '''
                          <svg
                            width="32"
                            height="32"
                            fill="white"
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                          >
                            <path
                              d="M4 6h16v2H4V6zm0 5h16v2H4v-2zm16 5H4v2h16v-2z"
                              fill="white"
                            />
                          </svg>
                        ''',
                        width: 40,
                        height: 40,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isMenuOpen = true;
                        });
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return MenuDrawer(
                              onClose: () {
                                setState(() {
                                  _isMenuOpen = false;
                                });
                                Navigator.of(context).pop();
                              },
                              selectedLanguage: widget.selectedLanguage,
                            );
                          },
                        ).then((_) {
                          // This ensures the icon changes back when dialog is dismissed by tapping outside
                          setState(() {
                            _isMenuOpen = false;
                          });
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}