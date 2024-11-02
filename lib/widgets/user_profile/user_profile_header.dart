import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/character_page.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework
import '../../localization/play/localization.dart'; // Import the localization file
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:handabatamae/services/avatar_service.dart'; // Import Avatar Service
import 'package:handabatamae/pages/banner_page.dart'; // Import BannerPage

class UserProfileHeader extends StatelessWidget {
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
  });

  void _handleMenuSelection(String result, BuildContext context) {
    switch (result) {
      case 'Change Avatar':
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return CharacterPage(
              selectionMode: true,
              currentAvatarId: avatarId,
              onAvatarSelected: (newAvatarId) async {
                // Close the dialog first
                Navigator.of(context).pop();
                // Trigger the refresh
                onUpdateProfile?.call(username, selectedLanguage);
              },
              onClose: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
        break;
      case 'Change Nickname':
        // Handle Change Nickname
        break;
      case 'Change Banner':
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return BannerPage(
              selectionMode: true,
              currentBannerId: bannerId,
              onBannerSelected: (newBannerId) async {
                Navigator.of(context).pop();
                onUpdateProfile?.call(username, selectedLanguage);
              },
              onClose: () {
                Navigator.of(context).pop();
              },
            );
          },
        );
        break;
      case 'Change Favorite Badges':
        // Handle Change Favorite Badges
        break;
    }
  }

  Future<String?> _getAvatarImage() async {
    try {
      final avatars = await AvatarService().fetchAvatars();
      final avatar = avatars.firstWhere(
        (avatar) => avatar['id'] == avatarId,
        orElse: () => {'img': 'Kladis.png'}, // Provide a default avatar
      );
      return avatar['img'];
    } catch (e) {
      return 'Kladis.png'; // Return default avatar on error
    }
  }

  Future<String?> _getBannerImage() async {
    try {
      final banners = await BannerService().fetchBanners();
      final banner = banners.firstWhere(
        (banner) => banner['id'] == bannerId,
        orElse: () => {'img': 'Level01.svg'}, // Provide a default banner
      );
      return banner['img'];
    } catch (e) {
      return 'Level01.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    double progressPercentage = maxExp > 0 ? currentExp / maxExp : 0;

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
                              nickname,
                              style: textStyle.copyWith(
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
                              '@$username',
                              style: textStyle.copyWith(
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
                                    '${PlayLocalization.translate('level', selectedLanguage)}: $level',
                                    style: textStyle.copyWith(
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
                                    '$currentExp / $maxExp',
                                    style: textStyle.copyWith(
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
                    if (showMenuIcon)
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
                                  PlayLocalization.translate('changeAvatar', selectedLanguage),
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
                                  PlayLocalization.translate('changeNickname', selectedLanguage),
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
                                  PlayLocalization.translate('changeBanner', selectedLanguage),
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
                                  PlayLocalization.translate('changeFavoriteBadges', selectedLanguage),
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