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
        radius: 24,
        backgroundColor: Colors.white,
        child: _cachedAvatarPath != null 
          ? Container(
              width: 32,
              height: 32,
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
              offset: const Offset(0, 0),
              child: _buildAvatarButton(),
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