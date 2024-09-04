import 'package:flutter/material.dart';
import 'dart:ui';
import 'account_settings.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/widgets/user_profile_widgets.dart';

class UserProfilePage extends StatefulWidget {
  final VoidCallback onClose;

  const UserProfilePage({super.key, required this.onClose});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool showAccountSettings = false;
  bool _isLoading = true;
  UserProfile? _userProfile;

  final UserProfileService _userProfileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    UserProfile? userProfile = await _userProfileService.fetchUserProfile();

    if (!mounted) return;

    setState(() {
      _userProfile = userProfile ?? UserProfile.guestProfile;
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
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : _userProfile != null
                                  ? UserProfileHeader(
                                      nickname: _userProfile!.nickname,
                                      avatarId: _userProfile!.avatarId,
                                      level: _userProfile!.level,
                                    )
                                  : const SizedBox.shrink(),
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

    if (_userProfile == null) {
      return Center(child: Text('Failed to load user profile.'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserProfileStats(
          totalBadges: _userProfile!.totalBadgeUnlocked,
          totalStagesCleared: _userProfile!.totalStageCleared,
        ),
        const SizedBox(height: 20),
        const FavoriteBadges(),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.onClose,
          child: const Text('Close'),
        ),
      ],
    );
  }
}