import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework
import '../../localization/play/localization.dart'; // Import the localization file

class UserProfileHeader extends StatelessWidget {
  final String username;
  final String nickname;
  final int avatarId;
  final int level;
  final int currentExp; // Current experience points
  final int maxExp; // Maximum experience points for the current level
  final TextStyle textStyle;
  final String selectedLanguage; // Add selectedLanguage

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
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: ResponsiveValue<double>(
            context,
            defaultValue: 40, // Scale down avatar size
            conditionalValues: [
              Condition.smallerThan(name: MOBILE, value: 40),
              Condition.largerThan(name: MOBILE, value: 64),
            ],
          ).value,
          backgroundColor: Colors.grey,
          child: Icon(
            Icons.person,
            size: ResponsiveValue<double>(
              context,
              defaultValue: 32, // Scale down icon size
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 24),
                Condition.largerThan(name: MOBILE, value: 40),
              ],
            ).value,
            color: Colors.white,
          ),
        ),
        SizedBox(
          width: ResponsiveValue<double>(
            context,
            defaultValue: 16, // Scale down spacing
            conditionalValues: [
              Condition.smallerThan(name: MOBILE, value: 12),
              Condition.largerThan(name: MOBILE, value: 20),
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
                    Condition.smallerThan(name: MOBILE, value: 14),
                    Condition.largerThan(name: MOBILE, value: 22),
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
                    Condition.smallerThan(name: MOBILE, value: 9.6),
                    Condition.largerThan(name: MOBILE, value: 16),
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
                  Condition.smallerThan(name: MOBILE, value: 4.8),
                  Condition.largerThan(name: MOBILE, value: 8),
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
                    Condition.smallerThan(name: MOBILE, value: 9.6),
                    Condition.largerThan(name: MOBILE, value: 16),
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
                  Condition.smallerThan(name: MOBILE, value: 2.4),
                  Condition.largerThan(name: MOBILE, value: 4),
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
                      Condition.smallerThan(name: MOBILE, value: 96),
                      Condition.largerThan(name: MOBILE, value: 144),
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
    );
  }
}