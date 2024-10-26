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
  final double scaleFactor; // Add scaleFactor

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
    this.scaleFactor = 1.0, // Default scaleFactor to 1.0
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: ResponsiveValue<double>(
            context,
            defaultValue: 50 * scaleFactor, // Scale down avatar size
            conditionalValues: [
              Condition.smallerThan(name: MOBILE, value: 50 * scaleFactor),
              Condition.largerThan(name: MOBILE, value: 80 * scaleFactor),
            ],
          ).value,
          backgroundColor: Colors.grey,
          child: Icon(
            Icons.person,
            size: ResponsiveValue<double>(
              context,
              defaultValue: 40 * scaleFactor, // Scale down icon size
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 30 * scaleFactor),
                Condition.largerThan(name: MOBILE, value: 50 * scaleFactor),
              ],
            ).value,
            color: Colors.white,
          ),
        ),
        SizedBox(
          width: ResponsiveValue<double>(
            context,
            defaultValue: 20 * scaleFactor, // Scale down spacing
            conditionalValues: [
              Condition.smallerThan(name: MOBILE, value: 15 * scaleFactor),
              Condition.largerThan(name: MOBILE, value: 25 * scaleFactor),
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
                  defaultValue: 23 * scaleFactor, // Scale down font size
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 18 * scaleFactor),
                    Condition.largerThan(name: MOBILE, value: 28 * scaleFactor),
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
                  defaultValue: 16 * scaleFactor, // Scale down font size
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 12 * scaleFactor),
                    Condition.largerThan(name: MOBILE, value: 20 * scaleFactor),
                  ],
                ).value,
                color: Colors.white,
              ),
            ),
            SizedBox(
              height: ResponsiveValue<double>(
                context,
                defaultValue: 8 * scaleFactor, // Scale down spacing
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 6 * scaleFactor),
                  Condition.largerThan(name: MOBILE, value: 10 * scaleFactor),
                ],
              ).value,
            ),
            Text(
              '${PlayLocalization.translate('level', selectedLanguage)}: $level',
              style: textStyle.copyWith(
                fontSize: ResponsiveValue<double>(
                  context,
                  defaultValue: 16 * scaleFactor, // Scale down font size
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 12 * scaleFactor),
                    Condition.largerThan(name: MOBILE, value: 20 * scaleFactor),
                  ],
                ).value,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(
              height: ResponsiveValue<double>(
                context,
                defaultValue: 4 * scaleFactor, // Scale down spacing
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 3 * scaleFactor),
                  Condition.largerThan(name: MOBILE, value: 5 * scaleFactor),
                ],
              ).value,
            ),
            Stack(
              children: [
                Container(
                  width: ResponsiveValue<double>(
                    context,
                    defaultValue: 150 * scaleFactor, // Scale down width
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 120 * scaleFactor),
                      Condition.largerThan(name: MOBILE, value: 180 * scaleFactor),
                    ],
                  ).value,
                  height: 20 * scaleFactor, // Height of the XP bar
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Background color of the XP bar
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(color: Colors.black, width: 3), // Black border
                  ),
                ),
                Container(
                  width: ResponsiveValue<double>(
                    context,
                    defaultValue: 150 * (currentExp / maxExp) * scaleFactor, // Scale down width
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 120 * (currentExp / maxExp) * scaleFactor),
                      Condition.largerThan(name: MOBILE, value: 180 * (currentExp / maxExp) * scaleFactor),
                    ],
                  ).value,
                  height: 20 * scaleFactor, // Match the height of the XP bar
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