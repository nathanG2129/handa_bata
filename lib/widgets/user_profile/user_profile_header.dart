import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/character_page.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:handabatamae/widgets/dialogs/change_nickname_dialog.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import '../../localization/play/localization.dart'; // Import the localization file
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:handabatamae/services/avatar_service.dart'; // Import Avatar Service
import 'package:handabatamae/pages/banner_page.dart'; // Import BannerPage
import 'package:handabatamae/pages/badge_page.dart'; // Import BadgePage
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/shared/connection_quality.dart';

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
  final BannerService _bannerService = BannerService();
  String? _cachedAvatarPath;
  late StreamSubscription<Map<int, String>> _avatarSubscription;
  late StreamSubscription<ConnectionQuality> _connectionSubscription;
  String? _cachedBannerPath;
  late StreamSubscription<List<Map<String, dynamic>>> _bannerSubscription;
  int _currentAvatarId = 0;
  ConnectionQuality _currentQuality = ConnectionQuality.EXCELLENT;

  @override
  void initState() {
    super.initState();
    _currentAvatarId = widget.avatarId;

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
      if (mounted && quality != _currentQuality) {
        setState(() {
          _currentQuality = quality;
        });
      }
    });

    // Initial avatar load
    _loadAvatar();

    // Add banner subscription
    _bannerSubscription = _bannerService.bannerUpdates.listen((banners) {
      final currentBanner = banners.firstWhere(
        (b) => b['id'] == widget.bannerId,
        orElse: () => {'img': 'Level01.svg'},
      );
      if (mounted && currentBanner['img'] != _cachedBannerPath) {
        setState(() => _cachedBannerPath = currentBanner['img']);
      }
    });

    _getBannerImage();
  }

  Future<void> _loadAvatar() async {
    if (!mounted) return;
    
    final avatar = await _getAvatarImage();
    
    if (mounted && avatar != null) {
      setState(() {
        _cachedAvatarPath = avatar;
        _currentAvatarId = widget.avatarId;
      });
    }
  }

  @override
  void dispose() {
    _avatarSubscription.cancel();
    _connectionSubscription.cancel();
    _bannerSubscription.cancel();
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

  Future<String?> _getAvatarImage() async {
    try {

      // Strong cache check
      if (_cachedAvatarPath != null && widget.avatarId == _currentAvatarId) {
        return _cachedAvatarPath;
      }

      final avatar = await _avatarService.getAvatarDetails(
        widget.avatarId,
        priority: LoadPriority.HIGH,
      );
      
      
      if (mounted && avatar != null) {
        setState(() {
          _cachedAvatarPath = avatar['img'];
          _currentAvatarId = widget.avatarId;
        });
      }
      return _cachedAvatarPath ?? 'Kladis.png';
    } catch (e) {
      // On error, use default avatar and update state
      if (mounted) {
        setState(() {
          _cachedAvatarPath = 'Kladis.png';
          _currentAvatarId = widget.avatarId;
        });
      }
      return 'Kladis.png';
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
              selectedLanguage: widget.selectedLanguage,
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
              selectedLanguage: widget.selectedLanguage,
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
              selectedLanguage: widget.selectedLanguage,
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
      final banner = await _bannerService.getBannerDetails(
        widget.bannerId,
        priority: BannerPriority.CRITICAL
      );
      
      if (mounted && banner != null && banner['img'] != _cachedBannerPath) {
        setState(() => _cachedBannerPath = banner['img']);
      }
      return _cachedBannerPath ?? 'Level01.svg';
    } catch (e) {
      return _cachedBannerPath ?? 'Level01.svg';
    }
  }

  @override
  void didUpdateWidget(UserProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarId != widget.avatarId) {
      _loadAvatar();
    }
    // Check if banner changed
    if (oldWidget.bannerId != widget.bannerId) {
      _getBannerImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    double progressPercentage = widget.maxExp > 0 ? widget.currentExp / widget.maxExp : 0;

    return FutureBuilder<String?>(
      future: _getBannerImage(),
      builder: (context, bannerSnapshot) {
        return ResponsiveBuilder(
          builder: (context, sizingInformation) {
            // Check for specific mobile breakpoints
            final screenWidth = MediaQuery.of(context).size.width;
            final bool isMobileSmall = screenWidth <= 375; // mobileNormal and below
            final bool isMobileLarge = screenWidth <= 414 && screenWidth > 375; // mobileLarge
            final bool isMobileExtraLarge = screenWidth <= 480 && screenWidth > 414; // mobileExtraLarge

            return Container(
              width: double.infinity,
              height: ResponsiveUtils.valueByDevice(
                context: context,
                mobile: isMobileSmall ? 100 : 130, // Taller for larger phones
                tablet: 140,
                desktop: 150,
              ),
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
                    padding: EdgeInsets.all(
                      ResponsiveUtils.valueByDevice(
                        context: context,
                        mobile: isMobileSmall ? 12 : 16,
                        tablet: 16,
                        desktop: 20,
                      ),
                    ),
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            FutureBuilder<String?>(
                              future: _getAvatarImage(),
                              builder: (context, snapshot) {
                                // Adjust avatar sizes based on mobile breakpoint
                                final double avatarRadius = isMobileSmall ? 35 : 
                                                         isMobileLarge ? 38 :
                                                         isMobileExtraLarge ? 40 : 45;

                                return CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: Colors.white,
                                  child: snapshot.hasData
                                    ? Container(
                                        width: avatarRadius * 1.5,
                                        height: avatarRadius * 1.5,
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
                                        size: avatarRadius * 0.8,
                                        color: const Color.fromARGB(255, 0, 0, 0),
                                      ),
                                );
                              },
                            ),
                            SizedBox(
                              width: isMobileSmall ? 12 : 16,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.nickname,
                                  style: widget.textStyle.copyWith(
                                    fontSize: isMobileSmall ? 16 : 
                                             isMobileLarge ? 18 :
                                             isMobileExtraLarge ? 18 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '@${widget.username}',
                                  style: widget.textStyle.copyWith(
                                    fontSize: isMobileSmall ? 12 : 
                                             isMobileLarge ? 14 :
                                             isMobileExtraLarge ? 15 : 16,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  height: isMobileSmall ? 4 : 6,
                                ),
                                SizedBox(
                                  width: isMobileSmall ? 150 : 
                                        isMobileLarge ? 175 :
                                        isMobileExtraLarge ? 200 : 250,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${PlayLocalization.translate('level', widget.selectedLanguage)}: ${widget.level}',
                                        style: widget.textStyle.copyWith(
                                          fontSize: isMobileSmall ? 10 : 
                                                   isMobileLarge ? 12 :
                                                   isMobileExtraLarge ? 13 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '${widget.currentExp} / ${widget.maxExp}',
                                        style: widget.textStyle.copyWith(
                                          fontSize: isMobileSmall ? 9 : 
                                                   isMobileLarge ? 11 :
                                                   isMobileExtraLarge ? 12 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: isMobileSmall ? 150 : 
                                        isMobileLarge ? 175 :
                                        isMobileExtraLarge ? 200 : 250,
                                  height: isMobileSmall ? 16 : 18,
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
      },
    );
  }
}