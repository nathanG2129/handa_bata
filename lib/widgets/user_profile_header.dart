import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework

class UserProfileHeader extends StatelessWidget {
  final String username;
  final String nickname;
  final int avatarId;
  final int level;
  final int currentExp; // Current experience points
  final int maxExp; // Maximum experience points for the current level
  final TextStyle textStyle;

  const UserProfileHeader({
    super.key,
    required this.username,
    required this.nickname,
    required this.avatarId,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: ResponsiveValue<double>(
            context,
            defaultValue: 50,
            conditionalValues: [
              const Condition.smallerThan(name: MOBILE, value: 50),
              const Condition.largerThan(name: MOBILE, value: 80),
            ],
          ).value,
          backgroundColor: Colors.grey,
          child: Icon(
            Icons.person,
            size: ResponsiveValue<double>(
              context,
              defaultValue: 40,
              conditionalValues: [
                const Condition.smallerThan(name: MOBILE, value: 30),
                const Condition.largerThan(name: MOBILE, value: 50),
              ],
            ).value,
            color: Colors.white,
          ),
        ),
        SizedBox(
          width: ResponsiveValue<double>(
            context,
            defaultValue: 20,
            conditionalValues: [
              const Condition.smallerThan(name: MOBILE, value: 15),
              const Condition.largerThan(name: MOBILE, value: 25),
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
                  defaultValue: 23,
                  conditionalValues: [
                    const Condition.smallerThan(name: MOBILE, value: 18),
                    const Condition.largerThan(name: MOBILE, value: 28),
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
                  defaultValue: 16,
                  conditionalValues: [
                    const Condition.smallerThan(name: MOBILE, value: 12),
                    const Condition.largerThan(name: MOBILE, value: 20),
                  ],
                ).value,
                color: Colors.white,
              ),
            ),
            SizedBox(
              height: ResponsiveValue<double>(
                context,
                defaultValue: 8,
                conditionalValues: [
                  const Condition.smallerThan(name: MOBILE, value: 6),
                  const Condition.largerThan(name: MOBILE, value: 10),
                ],
              ).value,
            ),
            Text(
              'Level: $level',
              style: textStyle.copyWith(
                fontSize: ResponsiveValue<double>(
                  context,
                  defaultValue: 16,
                  conditionalValues: [
                    const Condition.smallerThan(name: MOBILE, value: 12),
                    const Condition.largerThan(name: MOBILE, value: 20),
                  ],
                ).value,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(
              height: ResponsiveValue<double>(
                context,
                defaultValue: 4,
                conditionalValues: [
                  const Condition.smallerThan(name: MOBILE, value: 3),
                  const Condition.largerThan(name: MOBILE, value: 5),
                ],
              ).value,
            ),
            Stack(
              children: [
                Container(
                  width: ResponsiveValue<double>(
                    context,
                    defaultValue: 150,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 120),
                      const Condition.largerThan(name: MOBILE, value: 180),
                    ],
                  ).value,
                  height: 20, // Height of the XP bar
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Background color of the XP bar
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(color: Colors.black, width: 3), // Black border
                  ),
                ),
                Container(
                  width: ResponsiveValue<double>(
                    context,
                    defaultValue: 150 * (currentExp / maxExp),
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 120 * (currentExp / maxExp)),
                      Condition.largerThan(name: MOBILE, value: 180 * (currentExp / maxExp)),
                    ],
                  ).value,
                  height: 20, // Match the height of the XP bar
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