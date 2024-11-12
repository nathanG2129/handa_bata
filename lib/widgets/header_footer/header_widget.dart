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
import 'package:handabatamae/services/badge_unlock_service.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:handabatamae/widgets/notifications/banner_unlock_notification.dart';
import 'package:handabatamae/services/avatar_service.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/widgets/notifications/badge_unlock_notification.dart';
import 'package:handabatamae/services/badge_service.dart';
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
  final AuthService _authService = AuthService();
  final BannerService _bannerService = BannerService();
  final BadgeService _badgeService = BadgeService();
  final UserProfileService _userProfileService = UserProfileService();
  OverlayEntry? _overlayEntry;
  int? _currentAvatarId;


  Queue<String> _pendingBannerNotifications = Queue<String>();
  bool _isShowingBannerNotification = false;

  Queue<int> _pendingBadgeNotifications = Queue<int>();
  bool _isShowingBadgeNotification = false;

  String? _cachedAvatarPath;

  final AvatarService _avatarService = AvatarService();

  // Add mutex for notifications
  bool _isProcessingNotification = false;

  Timer? _notificationTimer;

  late StreamSubscription<UserProfile> _profileSubscription;

  late StreamSubscription<Map<int, String>> _avatarSubscription;

  late StreamSubscription<ConnectionQuality> _connectionSubscription;
  ConnectionQuality _currentQuality = ConnectionQuality.GOOD;

  @override
  void initState() {
    super.initState();
    _checkForUnlockedBanners();
    _checkForUnlockedBadges();
    
    _notificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isShowingBadgeNotification && !_isShowingBannerNotification) {
        _showNextNotification();
      }
    });

    // Initial profile fetch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = await _userProfileService.fetchUserProfile();
      if (mounted && profile != null) {
        _currentAvatarId = profile.avatarId;
        if (_currentAvatarId != null) {
          final avatar = await _avatarService.getAvatarDetails(_currentAvatarId!);
          if (mounted && avatar != null) {
            setState(() {
              _cachedAvatarPath = avatar['img'];
            });
          }
        }
      }
    });

    // Listen to profile updates
    _profileSubscription = _userProfileService.profileUpdates.listen((profile) {
      if (mounted && profile.avatarId != _currentAvatarId) {
        _currentAvatarId = profile.avatarId;
        _avatarService.getAvatarDetails(profile.avatarId).then((avatar) {
          if (mounted && avatar != null) {
            setState(() {
              _cachedAvatarPath = avatar['img'];
            });
          }
        });
      }
    });

    // Listen to avatar updates
    _avatarSubscription = _avatarService.avatarUpdates.listen((updates) {
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

  Future<void> _updateAvatar(int avatarId) async {
    if (!mounted) return;
    setState(() => _currentAvatarId = avatarId);
    
    try {
      final avatar = await _avatarService.getAvatarDetails(avatarId);
      if (mounted && avatar != null) {
        setState(() => _cachedAvatarPath = avatar['img']);
      }
    } catch (e) {
      print('Error updating avatar: $e');
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _profileSubscription.cancel();
    _removeOverlay();
    _avatarSubscription.cancel();
    _connectionSubscription.cancel();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowingBannerNotification = false;
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
            _isShowingBannerNotification = false;
            Future.delayed(const Duration(milliseconds: 300), () {
              _showNextBannerNotification();
            });
          },
          onViewBanner: () {
            _removeOverlay();
            _isShowingBannerNotification = false;
            _showBanners();
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

  Future<String?> _getAvatarImage(int avatarId) async {
    try {
      switch (_currentQuality) {
        case ConnectionQuality.OFFLINE:
          // Use cached data only
          if (_cachedAvatarPath != null) {
            return _cachedAvatarPath;
          }
          break;
          
        case ConnectionQuality.POOR:
          // Use cached first, update in background
          if (_cachedAvatarPath != null) {
            _avatarService.getAvatarDetails(
              avatarId,
              priority: LoadPriority.HIGH
            );
            return _cachedAvatarPath;
          }
          break;
          
        default:
          // Normal behavior for GOOD and EXCELLENT
          final avatar = await _avatarService.getAvatarDetails(
            avatarId,
            priority: LoadPriority.HIGH
          );
          if (mounted && avatar != null && avatar['img'] != _cachedAvatarPath) {
            setState(() => _cachedAvatarPath = avatar['img']);
          }
      }
      return _cachedAvatarPath ?? 'Kladis.png';
    } catch (e) {
      print('Error getting avatar image: $e');
      return _cachedAvatarPath ?? 'Kladis.png';
    }
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

  void _checkForUnlockedBadges() {
    print('🔍 Checking for unlocked badges...');
    print('🔍 Current showing state - Badge: $_isShowingBadgeNotification, Banner: $_isShowingBannerNotification');
    print('🔍 Pending notifications in service: ${BadgeUnlockService.pendingNotifications.toList()}');
    
    if (!_isShowingBadgeNotification && BadgeUnlockService.hasNotifications) {
      print('🔍 Adding pending notifications to local queue');
      _pendingBadgeNotifications.addAll(BadgeUnlockService.pendingNotifications);
      // Clear the service's queue after adding to local queue
      BadgeUnlockService.pendingNotifications.clear();
      print('🔍 Local queue after adding: ${_pendingBadgeNotifications.toList()}');
      _showNextBadgeNotification();
    }
  }

  Future<void> _showBadgeUnlockNotification(int badgeId, {int retryCount = 0}) async {
    try {
      final badge = await _badgeService.getBadgeDetails(badgeId);
      if (badge != null) {
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
              onRetry: retryCount < 3 ? () {
                _showBadgeUnlockNotification(badgeId, retryCount: retryCount + 1);
              } : null,
            ),
          ),
        );

        Overlay.of(context).insert(_overlayEntry!);
        _isShowingBadgeNotification = true;
      } else {
        // Handle missing badge data
        print('Badge data not found for ID: $badgeId');
        _isShowingBadgeNotification = false;
        _showNextBadgeNotification();
      }
    } catch (e) {
      print('Error showing badge notification: $e');
      if (retryCount < 3) {
        // Retry after delay
        await Future.delayed(Duration(seconds: retryCount + 1));
        _showBadgeUnlockNotification(badgeId, retryCount: retryCount + 1);
      } else {
        // Give up after 3 retries
        _isShowingBadgeNotification = false;
        _showNextBadgeNotification();
      }
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

  Future<void> _showNextNotification() async {
    if (_isProcessingNotification) return;
    
    try {
      _isProcessingNotification = true;
      
      if (!_isShowingBadgeNotification && !_isShowingBannerNotification) {
        if (_pendingBadgeNotifications.isNotEmpty) {
          int nextBadgeId = _pendingBadgeNotifications.removeFirst();
          await _showBadgeUnlockNotification(nextBadgeId);
        } else if (_pendingBannerNotifications.isNotEmpty) {
          String nextBannerTitle = _pendingBannerNotifications.removeFirst();
          _showBannerUnlockNotification(nextBannerTitle);
        }
      }
    } finally {
      _isProcessingNotification = false;
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