// lib/widgets/user_profile_widgets.dart

import 'package:flutter/material.dart';

class UserProfileHeader extends StatelessWidget {
  final String nickname;
  final int avatarId;
  final int level;

  const UserProfileHeader({
    super.key,
    required this.nickname,
    required this.avatarId,
    required this.level,
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Level: $level',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}

class UserProfileStats extends StatelessWidget {
  final int totalBadges;
  final int totalStagesCleared;

  const UserProfileStats({
    super.key,
    required this.totalBadges,
    required this.totalStagesCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Badges',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Card(
                  color: Colors.lightBlue[100],
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: Text(
                      '$totalBadges',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stages',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Cleared',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Card(
                  color: Colors.lightBlue[100],
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: Text(
                      '$totalStagesCleared',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FavoriteBadges extends StatelessWidget {
  const FavoriteBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Favorite Badges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.star, size: 40, color: Colors.amber),
                    SizedBox(height: 10),
                    Text(
                      'Badge 1',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.star, size: 40, color: Colors.amber),
                    SizedBox(height: 10),
                    Text(
                      'Badge 2',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.star, size: 40, color: Colors.amber),
                    SizedBox(height: 10),
                    Text(
                      'Badge 3',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}