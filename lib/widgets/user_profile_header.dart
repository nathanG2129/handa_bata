import 'package:flutter/material.dart';
// Import Google Fonts

class UserProfileHeader extends StatelessWidget {
  final String nickname;
  final int avatarId;
  final int level;
  final TextStyle textStyle;

  const UserProfileHeader({
    super.key,
    required this.nickname,
    required this.avatarId,
    required this.level,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nickname,
              style: textStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Level: $level',
              style: textStyle.copyWith(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}