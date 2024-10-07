import 'package:flutter/material.dart';
import 'dart:ui';
import 'account_settings.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/widgets/user_profile_header.dart'; // Import UserProfileHeader
import 'package:handabatamae/widgets/user_profile_stats.dart'; // Import UserProfileStats
import 'package:handabatamae/widgets/favorite_badges.dart'; // Import FavoriteBadges
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class UserProfilePage extends StatefulWidget {
  final VoidCallback onClose;

  const UserProfilePage({super.key, required this.onClose});

  @override
  // ignore: library_private_types_in_public_api
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

    try {
      UserProfile? userProfile = await _userProfileService.fetchUserProfile();

      if (!mounted) return;

      setState(() {
        _userProfile = userProfile ?? UserProfile.guestProfile;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNicknameChanged() {
    _fetchUserProfile();
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
                                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 1), // Black border for the dialog
                  borderRadius: BorderRadius.zero, // Purely rectangular
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          color: const Color(0xFF760a6b), // Background color for username, level, and profile picture
                          padding: const EdgeInsets.all(20.0),
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _userProfile != null
                                  ? UserProfileHeader(
                                      nickname: _userProfile!.nickname, // Pass nickname
                                      username: _userProfile!.username, // Pass username
                                      avatarId: _userProfile!.avatarId,
                                      level: _userProfile!.level,
                                      currentExp: _userProfile!.exp, 
                                      maxExp: _userProfile!.expCap,
                                      textStyle: GoogleFonts.rubik(color: Colors.white),  // White font color for username and level
                                    )
                                  : const SizedBox.shrink(),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, size: 30, color: Colors.white), // White ellipses
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
                      child: showAccountSettings
                          ? AccountSettings(
                              onClose: () {
                                setState(() {
                                  showAccountSettings = false;
                                });
                                _fetchUserProfile(); // Refresh user profile after closing account settings
                              },
                              onNicknameChanged: _onNicknameChanged, // Pass the callback
                            )
                          : _buildUserProfile(),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfile == null) {
      return const Center(child: Text('Failed to load user profile.'));
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
      ],
    );
  }
}