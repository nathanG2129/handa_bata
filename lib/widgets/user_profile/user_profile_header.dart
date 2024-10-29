import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/character_page.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework
import '../../localization/play/localization.dart'; // Import the localization file
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:handabatamae/services/avatar_service.dart'; // Import Avatar Service

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
  final VoidCallback? onProfileUpdate; // Add this

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
    this.showMenuIcon = false, // Default to false
    this.onProfileUpdate, // Add this
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
                onProfileUpdate?.call();
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
        // Handle Change Banner
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
        orElse: () => {'img': 'default_avatar.png'}, // Provide a default avatar
      );
      return avatar['img'];
    } catch (e) {
      print('Error fetching avatar image: $e');
      return 'default_avatar.png'; // Return default avatar on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                            defaultValue: 50,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 50),
                              const Condition.largerThan(name: MOBILE, value: 80),
                            ],
                          ).value,
                          height: ResponsiveValue<double>(
                            context,
                            defaultValue: 50,
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
                          color: Colors.grey,
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
                  username,
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
                  nickname,
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
                Text(
                  '${PlayLocalization.translate('level', selectedLanguage)}: $level',
                  style: textStyle.copyWith(
                    fontSize: ResponsiveValue<double>(
                      context,
                      defaultValue: 12.8, // Scale down font size
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 9.6),
                        const Condition.largerThan(name: MOBILE, value: 16),
                      ],
                    ).value,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: 3.2, // Scale down spacing
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 2.4),
                      const Condition.largerThan(name: MOBILE, value: 4),
                    ],
                  ).value,
                ),
                Stack(
                  children: [
                    Container(
                      width: ResponsiveValue<double>(
                        context,
                        defaultValue: 120, // Scale down width
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 96),
                          const Condition.largerThan(name: MOBILE, value: 144),
                        ],
                      ).value,
                      height: 16, // Height of the XP bar
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // Background color of the XP bar
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(color: Colors.black, width: 3), // Black border
                      ),
                    ),
                    Container(
                      width: ResponsiveValue<double>(
                        context,
                        defaultValue: 120 * (currentExp / maxExp), // Scale down width
                        conditionalValues: [
                          Condition.smallerThan(name: MOBILE, value: 96 * (currentExp / maxExp)),
                          Condition.largerThan(name: MOBILE, value: 144 * (currentExp / maxExp)),
                        ],
                      ).value,
                      height: 16, // Match the height of the XP bar
                      decoration: BoxDecoration(
                        color: Colors.green, // Fill color of the XP bar
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        if (showMenuIcon)
          Positioned(
            top: -10,
            right: -10,
            child: PopupMenuButton<String>(
              offset: const Offset(-7, 40),
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
                width: 24,
                height: 24,
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
    );
  }
}