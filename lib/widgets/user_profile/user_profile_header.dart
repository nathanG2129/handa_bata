import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/character_page.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:handabatamae/widgets/dialogs/change_nickname_dialog.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework
import '../../localization/play/localization.dart'; // Import the localization file
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:handabatamae/services/avatar_service.dart'; // Import Avatar Service
import 'package:handabatamae/pages/banner_page.dart'; // Import BannerPage
import 'package:handabatamae/pages/badge_page.dart'; // Import BadgePage
import 'package:handabatamae/services/user_profile_service.dart';

class UserProfileHeader extends StatefulWidget {
  final String username;
  final String nickname;
  final int avatarId;
  final int level;
  final int currentExp; // Current experience points
  final int maxExp; // Maximum experience points for the current level
  final TextStyle textStyle;
  final String selectedLanguage; // Add selectedLanguage
  final bool showMenuIcon; // Add showMenuIcon
  final Function(String, String)? onUpdateProfile; // Add this
  final int bannerId;
  final List<int> badgeShowcase; // Add badgeShowcase to UserProfileHeader constructor

  const UserProfileHeader({
    super.key,
    required this.username,
    required this.nickname,
    required this.avatarId,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    required this.textStyle,
    required this.selectedLanguage, // Add selectedLanguage
    required this.bannerId,
    this.showMenuIcon = false, // Default to false
    this.onUpdateProfile, // Add this
    required this.badgeShowcase, // Add badgeShowcase to UserProfileHeader constructor
  });

  @override
  UserProfileHeaderState createState() => UserProfileHeaderState();
}

class UserProfileHeaderState extends State<UserProfileHeader> {
  final UserProfileService _userProfileService = UserProfileService();
  final AvatarService _avatarService = AvatarService();
  String? _cachedAvatarPath;
  late StreamSubscription<Map<int, String>> _avatarSubscription;
  late StreamSubscription<ConnectionQuality> _connectionSubscription;
  ConnectionQuality _currentQuality = ConnectionQuality.GOOD;

  @override
  void initState() {
    super.initState();
    // Listen to avatar updates
    _avatarSubscription = _avatarService.avatarUpdates.listen((updates) {
      if (mounted && updates.containsKey(widget.avatarId)) {
        setState(() {
          _cachedAvatarPath = updates[widget.avatarId];
        });
      }
    });

    // Add connection quality listener
    _connectionSubscription = _avatarService.connectionQuality.listen((quality) {
      if (mounted) {
        setState(() => _currentQuality = quality);
      }
    });

    _getAvatarImage();
  }

  @override
  void dispose() {
    _avatarSubscription.cancel();
    _connectionSubscription.cancel();
    super.dispose();
  }

  Future<void> _updateNickname(String newNickname) async {
    try {
      await _userProfileService.updateProfileWithIntegration('nickname', newNickname);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating nickname: $e')),
      );
    }
  }

  Future<void> _handleAvatarUpdate(int avatarId) async {
    try {
      await _userProfileService.updateProfileWithIntegration('avatarId', avatarId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating avatar: $e')),
      );
    }
  }

  Future<String?> _getAvatarImage() async {
    try {
      // Adapt behavior based on connection quality
      switch (_currentQuality) {
        case ConnectionQuality.OFFLINE:
          // Only use cache in offline mode
          if (_cachedAvatarPath != null) {
            return _cachedAvatarPath;
          }
          break;
          
        case ConnectionQuality.POOR:
          // Use longer timeout, prioritize cache
          if (_cachedAvatarPath != null) {
            // Fetch in background but return cached immediately
            _avatarService.getAvatarDetails(
              widget.avatarId,
              priority: LoadPriority.CRITICAL
            );
            return _cachedAvatarPath;
          }
          break;
          
        default:
          // Normal behavior for GOOD and EXCELLENT
          final avatar = await _avatarService.getAvatarDetails(
            widget.avatarId,
            priority: LoadPriority.CRITICAL
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

  void _handleMenuSelection(String result, BuildContext context) {
    switch (result) {
      case 'Change Avatar':
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return CharacterPage(
              selectionMode: true,
              currentAvatarId: widget.avatarId,
              onAvatarSelected: (newAvatarId) async {
                Navigator.of(context).pop();
                widget.onUpdateProfile?.call(widget.username, widget.selectedLanguage);
              },
              onClose: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
        break;
      case 'Change Nickname':
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext dialogContext) {
            return ChangeNicknameDialog(
              currentNickname: widget.nickname,
              selectedLanguage: widget.selectedLanguage,
              onNicknameChanged: (newNickname) => _updateNickname(newNickname),
              darkenColor: (Color color, [double amount = 0.2]) {
                final hsl = HSLColor.fromColor(color);
                final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
                return hslDark.toColor();
              },
            );
          },
        );
        break;
      case 'Change Banner':
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return BannerPage(
              selectionMode: true,
              currentBannerId: widget.bannerId,
              onBannerSelected: (newBannerId) async {
                Navigator.of(context).pop();
                widget.onUpdateProfile?.call(widget.username, widget.selectedLanguage);
              },
              onClose: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
        break;
      case 'Change Favorite Badges':
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return BadgePage(
              selectionMode: true,
              currentBadgeShowcase: widget.badgeShowcase,
              onBadgesSelected: (newBadgeIds) async {
                Navigator.of(context).pop();
                widget.onUpdateProfile?.call(widget.username, widget.selectedLanguage);
              },
              onClose: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
        break;
    }
  }

  Future<String?> _getBannerImage() async {
    try {
      final banners = await BannerService().fetchBanners();
      final banner = banners.firstWhere(
        (banner) => banner['id'] == widget.bannerId,
        orElse: () => {'img': 'Level01.svg'}, // Provide a default banner
      );
      return banner['img'];
    } catch (e) {
      return 'Level01.svg';
    }
  }

  @override
  void didUpdateWidget(UserProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if avatar changed
    if (oldWidget.avatarId != widget.avatarId) {
      _getAvatarImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    double progressPercentage = widget.maxExp > 0 ? widget.currentExp / widget.maxExp : 0;

    return FutureBuilder<String?>(
      future: _getBannerImage(),
      builder: (context, bannerSnapshot) {
        return Container(
          width: double.infinity,
          height: 120,
          decoration: const BoxDecoration(
            color: Color(0xFF381c64),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bannerSnapshot.hasData)
                SvgPicture.asset(
                  'assets/banners/${bannerSnapshot.data}',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        FutureBuilder<String?>(
                          future: _getAvatarImage(),
                          builder: (context, snapshot) {
                            return CircleAvatar(
                              radius: ResponsiveValue<double>(
                                context,
                                defaultValue: 40,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 40),
                                  const Condition.largerThan(name: MOBILE, value: 64),
                                ],
                              ).value,
                              backgroundColor: Colors.white,
                              child: snapshot.hasData
                                  ? Container(
                                      width: ResponsiveValue<double>(
                                        context,
                                        defaultValue: 55,
                                        conditionalValues: [
                                          const Condition.smallerThan(name: MOBILE, value: 50),
                                          const Condition.largerThan(name: MOBILE, value: 80),
                                        ],
                                      ).value,
                                      height: ResponsiveValue<double>(
                                        context,
                                        defaultValue: 55,
                                        conditionalValues: [
                                          const Condition.smallerThan(name: MOBILE, value: 50),
                                          const Condition.largerThan(name: MOBILE, value: 80),
                                        ],
                                      ).value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        image: DecorationImage(
                                          image: AssetImage('assets/avatars/${snapshot.data}'),
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.none,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: ResponsiveValue<double>(
                                        context,
                                        defaultValue: 32,
                                        conditionalValues: [
                                          const Condition.smallerThan(name: MOBILE, value: 24),
                                          const Condition.largerThan(name: MOBILE, value: 40),
                                        ],
                                      ).value,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                    ),
                            );
                          },
                        ),
                        SizedBox(
                          width: ResponsiveValue<double>(
                            context,
                            defaultValue: 16, // Scale down spacing
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 12),
                              const Condition.largerThan(name: MOBILE, value: 20),
                            ],
                          ).value,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nickname,
                              style: widget.textStyle.copyWith(
                                fontSize: ResponsiveValue<double>(
                                  context,
                                  defaultValue: 18, // Scale down font size
                                  conditionalValues: [
                                    const Condition.smallerThan(name: MOBILE, value: 14),
                                    const Condition.largerThan(name: MOBILE, value: 22),
                                  ],
                                ).value,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '@${widget.username}',
                              style: widget.textStyle.copyWith(
                              fontSize: ResponsiveValue<double>(
                                context,
                                defaultValue: 12.8, // Scale down font size
                                conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: 9.6),
                                const Condition.largerThan(name: MOBILE, value: 16),
                                ],
                              ).value,
                              color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveValue<double>(
                                context,
                                defaultValue: 6.4, // Scale down spacing
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 4.8),
                                  const Condition.largerThan(name: MOBILE, value: 8),
                                ],
                              ).value,
                            ),
                            SizedBox(
                              width: ResponsiveValue<double>(
                                context,
                                defaultValue: 175,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 150),
                                  const Condition.largerThan(name: MOBILE, value: 250),
                                ],
                              ).value,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${PlayLocalization.translate('level', widget.selectedLanguage)}: ${widget.level}',
                                    style: widget.textStyle.copyWith(
                                      fontSize: ResponsiveValue<double>(
                                        context,
                                        defaultValue: 12.8,
                                        conditionalValues: [
                                          const Condition.smallerThan(name: MOBILE, value: 9.6),
                                          const Condition.largerThan(name: MOBILE, value: 16),
                                        ],
                                      ).value,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${widget.currentExp} / ${widget.maxExp}',
                                    style: widget.textStyle.copyWith(
                                      fontSize: ResponsiveValue<double>(
                                        context,
                                        defaultValue: 12.8,
                                        conditionalValues: [
                                          const Condition.smallerThan(name: MOBILE, value: 9),
                                          const Condition.largerThan(name: MOBILE, value: 14),
                                        ],
                                      ).value,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: ResponsiveValue<double>(
                                context,
                                defaultValue: 175,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 150),
                                  const Condition.largerThan(name: MOBILE, value: 250),
                                ],
                              ).value,
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(0),
                                child: LinearProgressIndicator(
                                  value: progressPercentage,
                                  backgroundColor: Colors.black,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF28e172)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.showMenuIcon)
                      Positioned(
                        top: -10,
                        right: 0,
                        child: PopupMenuButton<String>(
                          offset: const Offset(-0, 40),
                          icon: SvgPicture.string(
                            '''
                            <svg
                            width="24"
                            height="24"
                            fill="white"
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            >
                            <path
                            d="M18 2h-2v2h2V2zM4 4h6v2H4v14h14v-6h2v8H2V4h2zm4 8H6v6h6v-2h2v-2h-2v2H8v-4zm4-2h-2v2H8v-2h2V8h2V6h2v2h-2v2zm2-6h2v2h-2V4zm4 0h2v2h2v2h-2v2h-2v2h-2v-2h2V8h2V6h-2V4zm-4 8h2v2h-2v-2z"
                            fill="white"
                            />
                            </svg>
                            ''',
                            width: 28,
                            height: 28,
                          ),
                          color: const Color(0xFF241242), // Set the popup menu background color
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'Change Avatar',
                              child: Container(
                                width: double.infinity, // Span the entire width
                                height: 40, // Adjusted height
                                color: Colors.white,
                                alignment: Alignment.center, // Center the text
                                child: Text(
                                  PlayLocalization.translate('changeAvatar', widget.selectedLanguage),
                                  style: GoogleFonts.vt323(color: Colors.black, fontSize: 18),
                                ),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'Change Nickname',
                              child: Container(
                                width: double.infinity, // Span the entire width
                                height: 40, // Adjusted height
                                color: Colors.white,
                                alignment: Alignment.center, // Center the text
                                child: Text(
                                  PlayLocalization.translate('changeNickname', widget.selectedLanguage),
                                  style: GoogleFonts.vt323(color: Colors.black, fontSize: 18),
                                ),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'Change Banner',
                              child: Container(
                                width: double.infinity, // Span the entire width
                                height: 40, // Adjusted height
                                color: Colors.white,
                                alignment: Alignment.center, // Center the text
                                child: Text(
                                  PlayLocalization.translate('changeBanner', widget.selectedLanguage),
                                  style: GoogleFonts.vt323(color: Colors.black, fontSize: 18),
                                ),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'Change Favorite Badges',
                              child: Container(
                                width: double.infinity, // Span the entire width
                                height: 44, // Adjusted height
                                color: Colors.white,
                                alignment: Alignment.center, // Center the text
                                child: Text(
                                  PlayLocalization.translate('changeFavoriteBadges', widget.selectedLanguage),
                                  style: GoogleFonts.vt323(color: Colors.black, fontSize: 18),
                                  textAlign: TextAlign.center, // Add textAlign center
                                ),
                              ),
                            ),
                          ],
                          onSelected: (String result) => _handleMenuSelection(result, context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}