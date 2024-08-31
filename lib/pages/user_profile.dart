import 'package:flutter/material.dart';
import 'dart:ui';
import 'account_settings.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/models/user_model.dart';

class UserProfilePage extends StatefulWidget {
  final VoidCallback onClose;

  const UserProfilePage({super.key, required this.onClose});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool showAccountSettings = false;
  int totalBadges = 0;
  int totalStagesCleared = 0;
  bool _isLoading = true;
  String nickname = '';
  int avatarId = 0;
  int level = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    AuthService authService = AuthService();
    UserProfile? userProfile = await authService.getUserProfile();
    setState(() {
      if (userProfile != null) {
        nickname = userProfile.nickname;
        avatarId = userProfile.avatarId;
        level = userProfile.level;
        totalBadges = userProfile.totalBadgeUnlocked;
        totalStagesCleared = userProfile.totalStageCleared;
      } else {
        nickname = UserProfile.guestProfile.nickname;
        avatarId = UserProfile.guestProfile.avatarId;
        level = UserProfile.guestProfile.level;
        totalBadges = UserProfile.guestProfile.totalBadgeUnlocked;
        totalStagesCleared = UserProfile.guestProfile.totalStageCleared;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Card(
                margin: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          color: Colors.lightBlue[100],
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, size: 40, color: Colors.white),
                              ),
                              SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nickname,
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Level: $level',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz, size: 30),
                            onSelected: (String result) {
                              setState(() {
                                showAccountSettings = result == 'Account Settings';
                              });
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'User Profile',
                                child: Text('User Profile'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Account Settings',
                                child: Text('Account Settings'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: showAccountSettings ? AccountSettings(onClose: widget.onClose) : _buildUserProfile(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Column(
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
                          style: TextStyle(fontSize: 16),
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
                    Column(
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
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Favorite Badges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Row(
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
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.onClose,
          child: const Text('Close'),
        ),
      ],
    );
  }
}