import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/pages/account_settings.dart';
import 'package:handabatamae/pages/character_page.dart'; // Import CharacterPage
import 'package:handabatamae/pages/banner_page.dart'; // Import BannerPage
import 'package:handabatamae/pages/badge_page.dart'; // Import BadgePage
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:handabatamae/widgets/notifications/banner_unlock_notification.dart';
import 'package:handabatamae/services/avatar_service.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/widgets/notifications/badge_unlock_notification.dart';
import 'package:handabatamae/services/badge_unlock_service.dart';
import 'package:handabatamae/services/badge_service.dart';

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
  final BadgeService _badgeService = BadgeService();
  final UserProfileService _userProfileService = UserProfileService();
  OverlayEntry? _overlayEntry;
  int? _currentAvatarId;

  late StreamSubscription<int> _avatarSubscription;

  Queue<String> _pendingBannerNotifications = Queue<String>();
  bool _isShowingBannerNotification = false;

  Queue<int> _pendingBadgeNotifications = Queue<int>();
  bool _isShowingBadgeNotification = false;

  @override
  void initState() {
    super.initState();
    _checkForUnlockedBanners();
    _checkForUnlockedBadges();
    _authService.getUserProfile().then((profile) {
      if (mounted && profile != null) {
        setState(() {
          _currentAvatarId = profile.avatarId;
        });
      }
    });

    // Listen to avatar updates
    _avatarSubscription = _userProfileService.avatarStream.listen((newAvatarId) {
      if (mounted) {
        setState(() {
          _currentAvatarId = newAvatarId;
        });
      }
    });
  }

  @override
  void dispose() {
    _avatarSubscription.cancel();
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
        
        // Queue up notifications instead of showing them immediately
        for (var banner in newlyUnlockedBanners) {
          _pendingBannerNotifications.add(banner['title']);
        }
        
        // Start showing notifications if not already showing
        if (!_isShowingBannerNotification) {
          _showNextBannerNotification();
        }
      }
    } catch (e) {
    }
  }

  void _showNextBannerNotification() {
    if (_pendingBannerNotifications.isEmpty) {
      _isShowingBannerNotification = false;
      if (!_isShowingBadgeNotification && _pendingBadgeNotifications.isNotEmpty) {
        _showNextBadgeNotification();
      }
      return;
    }

    if (!_isShowingBannerNotification && !_isShowingBadgeNotification) {
      _isShowingBannerNotification = true;
      String nextBanner = _pendingBannerNotifications.removeFirst();
      _showBannerUnlockNotification(nextBanner);
    }
  }

  void _showBannerUnlockNotification(String bannerTitle) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width,
        child: BannerUnlockNotification(
          bannerTitle: bannerTitle,
          onDismiss: () {
            _removeOverlay();
            // Show next notification after current one is dismissed
            Future.delayed(const Duration(milliseconds: 300), () {
              _showNextBannerNotification();
            });
          },
          onViewBanner: () {
            _removeOverlay();
            _showBanners();
            // Show next notification after a delay
            Future.delayed(const Duration(milliseconds: 300), () {
              _showNextBannerNotification();
            });
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
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CharacterPage(
          selectionMode: false,
          currentAvatarId: _currentAvatarId,
          onAvatarSelected: (newAvatarId) async {
            await _authService.updateAvatarId(newAvatarId);
            Navigator.of(context).pop();
            if (mounted) {
              setState(() {
                _currentAvatarId = newAvatarId;
              });
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

  Future<String?> _getAvatarImage(int avatarId) async {
    try {
      final avatars = await AvatarService().fetchAvatars();
      final avatar = avatars.firstWhere(
        (avatar) => avatar['id'] == avatarId,
        orElse: () => {'img': 'Kladis.png'},
      );
      return avatar['img'];
    } catch (e) {
      return 'Kladis.png';
    }
  }

  Widget _buildAvatarButton() {
    return FutureBuilder<UserProfile?>(
      future: _authService.getUserProfile(),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.hasData && profileSnapshot.data != null) {
          return FutureBuilder<String?>(
            future: _getAvatarImage(profileSnapshot.data!.avatarId),
            builder: (context, avatarSnapshot) {
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
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      image: DecorationImage(
                        image: AssetImage('assets/avatars/${avatarSnapshot.data ?? 'default_avatar.png'}'),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        return PopupMenuButton<String>(
          icon: const Icon(Icons.person, size: 33, color: Colors.white),
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
        );
      },
    );
  }

  void _checkForUnlockedBadges() {
    print('🔍 Checking for unlocked badges...');
    print('🔍 Current showing state - Badge: $_isShowingBadgeNotification, Banner: $_isShowingBannerNotification');
    print('🔍 Pending notifications in service: ${BadgeUnlockService.pendingNotifications.toList()}');
    
    if (!_isShowingBadgeNotification && BadgeUnlockService.pendingNotifications.isNotEmpty) {
      print('🔍 Adding pending notifications to local queue');
      _pendingBadgeNotifications.addAll(BadgeUnlockService.pendingNotifications);
      // Clear the service's queue after adding to local queue
      BadgeUnlockService.pendingNotifications.clear();
      print('🔍 Local queue after adding: ${_pendingBadgeNotifications.toList()}');
      print('🔍 Service queue after clearing: ${BadgeUnlockService.pendingNotifications.toList()}');
      _showNextBadgeNotification();
    }
  }

  void _showBadgeUnlockNotification(int badgeId) async {
    print('🎯 Showing badge unlock notification for ID: $badgeId');
    try {
      final badges = await _badgeService.fetchBadges();
      final badge = badges.firstWhere((b) => b['id'] == badgeId);
      print('🎯 Found badge: ${badge['title']}');
      
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: MediaQuery.of(context).size.width,
          child: BadgeUnlockNotification(
            badgeTitle: badge['title'],
            onDismiss: () {
              _overlayEntry?.remove();
              _overlayEntry = null;
              _isShowingBadgeNotification = false;
              _showNextBadgeNotification();
            },
            onViewBadge: () {
              _overlayEntry?.remove();
              _overlayEntry = null;
              _showBadges();
              _isShowingBadgeNotification = false;
              _showNextBadgeNotification();
            },
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
      _isShowingBadgeNotification = true;
    } catch (e) {
      print('🎯 Error showing badge notification: $e');
    }
  }

  void _showNextBadgeNotification() {
    print('📢 Attempting to show next badge notification');
    print('📢 Current queues - Badge: ${_pendingBadgeNotifications.toList()}, Banner: ${_pendingBannerNotifications.toList()}');
    print('📢 Current showing state - Badge: $_isShowingBadgeNotification, Banner: $_isShowingBannerNotification');

    if (_pendingBadgeNotifications.isEmpty) {
      print('📢 No more badge notifications to show');
      _isShowingBadgeNotification = false;
      if (!_isShowingBannerNotification && _pendingBannerNotifications.isNotEmpty) {
        print('📢 Switching to banner notifications');
        _showNextBannerNotification();
      }
      return;
    }

    if (!_isShowingBadgeNotification && !_isShowingBannerNotification) {
      int nextBadgeId = _pendingBadgeNotifications.removeFirst();
      print('📢 Showing notification for badge ID: $nextBadgeId');
      _showBadgeUnlockNotification(nextBadgeId);
    } else {
      print('📢 Skipping notification - already showing something');
    }
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