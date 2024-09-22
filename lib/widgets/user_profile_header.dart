import 'package:flutter/material.dart';
// Import Google Fonts

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
        const CircleAvatar(
          radius: 65,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username,
              style: textStyle.copyWith(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              nickname,
              style: textStyle.copyWith(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Level: $level',
              style: textStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4), // Space between level and XP bar
            Stack(
              children: [
                Container(
                  width: 150, // Width of the XP bar
                  height: 20, // Height of the XP bar
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Background color of the XP bar
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(color: Colors.black, width: 3), // Black border
                  ),
                ),
                Container(
                  width: 150 * (currentExp / maxExp), // Fill width based on current experience
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