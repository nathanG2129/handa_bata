import 'package:flutter/material.dart';

class UserProfileHeader extends StatelessWidget {
  final String username;
  final String nickname;
  final int avatarId;
  final int level;
  final TextStyle textStyle;

  const UserProfileHeader({
    Key? key,
    required this.username,
    required this.nickname,
    required this.avatarId,
    required this.level,
    required this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          username,
          style: textStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          nickname,
          style: textStyle.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 60,
          backgroundImage: AssetImage('assets/avatars/avatar_$avatarId.png'),
        ),
        const SizedBox(height: 8),
        Text(
          'Level $level',
          style: textStyle,
        ),
      ],
    );
  }
}