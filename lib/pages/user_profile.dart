import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/widgets/user_profile/user_profile_header.dart'; // Import UserProfileHeader
import 'package:handabatamae/widgets/user_profile/user_profile_stats.dart'; // Import UserProfileStats
import 'package:handabatamae/widgets/user_profile/favorite_badges.dart'; // Import FavoriteBadges
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework

class UserProfilePage extends StatefulWidget {
  final VoidCallback onClose;
  final String selectedLanguage; // Add selectedLanguage

  const UserProfilePage({super.key, required this.onClose, required this.selectedLanguage});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  UserProfile? _userProfile;
  late String _selectedLanguage; // Add this line

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final UserProfileService _userProfileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage; // Initialize _selectedLanguage
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        _animationController.forward(); // Start the animation after loading
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

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _closeDialog();
        return false;
      },
      child: GestureDetector(
        onTap: _closeDialog,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: Container(
            color: Colors.black.withOpacity(0),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    margin: const EdgeInsets.all(20),
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black, width: 1), // Black border for the dialog
                      borderRadius: BorderRadius.zero, // Purely rectangular
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          color: const Color(0xFF760a6b), // Background color for username, level, and profile picture
                          padding: EdgeInsets.all(
                            ResponsiveValue<double>(
                              context,
                              defaultValue: 20.0,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: 16.0),
                                const Condition.largerThan(name: MOBILE, value: 24.0),
                              ],
                            ).value,
                          ),
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
                                      textStyle: GoogleFonts.rubik(
                                        color: Colors.white,
                                        fontSize: ResponsiveValue<double>(
                                          context,
                                          defaultValue: 16,
                                          conditionalValues: [
                                            const Condition.smallerThan(name: MOBILE, value: 14),
                                            const Condition.largerThan(name: MOBILE, value: 18),
                                          ],
                                        ).value,
                                      ), selectedLanguage: _selectedLanguage,  // White font color for username and level
                                      showMenuIcon: true, // Show menu icon
                                      onProfileUpdate: _fetchUserProfile, // Add this line
                                  )
                                  : const SizedBox.shrink(),
                        ),
                        Padding(
                          padding: EdgeInsets.all(
                            ResponsiveValue<double>(
                              context,
                              defaultValue: 20.0,
                              conditionalValues: [
                                const Condition.smallerThan(name: MOBILE, value: 16.0),
                                const Condition.largerThan(name: MOBILE, value: 24.0),
                              ],
                            ).value,
                          ),
                          child: _buildUserProfile(),
                        ),
                      ],
                    ),
                  ),
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
          selectedLanguage: _selectedLanguage, // Pass the selected language
        ),
        SizedBox(
          height: ResponsiveValue<double>(
            context,
            defaultValue: 20.0,
            conditionalValues: [
              const Condition.smallerThan(name: MOBILE, value: 16.0),
              const Condition.largerThan(name: MOBILE, value: 24.0),
            ],
          ).value,
        ),
        FavoriteBadges(selectedLanguage: _selectedLanguage,),
      ],
    );
  }
}