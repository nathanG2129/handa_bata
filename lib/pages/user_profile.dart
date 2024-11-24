import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/widgets/user_profile/user_profile_header.dart'; // Import UserProfileHeader
import 'package:handabatamae/widgets/user_profile/user_profile_stats.dart'; // Import UserProfileStats
import 'package:handabatamae/widgets/user_profile/favorite_badges.dart'; // Import FavoriteBadges
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:responsive_builder/responsive_builder.dart';

class UserProfilePage extends StatefulWidget {
  final VoidCallback onClose;
  final String selectedLanguage; // Add selectedLanguage

  const UserProfilePage({super.key, required this.onClose, required this.selectedLanguage});

  @override
  UserProfilePageState createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  final UserProfileService _userProfileService = UserProfileService();
  late StreamSubscription<UserProfile> _profileSubscription;
  bool _isLoading = true;
  UserProfile? _userProfile;
  late String _selectedLanguage; // Add this line

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

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
    // Listen to real-time profile updates
    _profileSubscription = _userProfileService.profileUpdates.listen((profile) {
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    });
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _profileSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      UserProfile? profile = await _userProfileService.fetchUserProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = profile ?? UserProfile.guestProfile;
        _isLoading = false;
        _animationController.forward();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _handleProfileUpdate(String username, String selectedLanguage) async {
    // Refresh the user profile data
    await _fetchUserProfile();
    
    // Update the state to trigger a rebuild
    if (mounted) {
      setState(() {
        _selectedLanguage = selectedLanguage;
      });
    }
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
                  child: ResponsiveBuilder(
                    builder: (context, sizingInformation) {
                      // Calculate the maximum width based on device type
                      double maxWidth = ResponsiveUtils.valueByDevice(
                        context: context,
                        mobile: MediaQuery.of(context).size.width * 0.9,
                        tablet: MediaQuery.of(context).size.width * 0.4,
                        desktop: 800,
                      );

                      // Calculate padding based on device type
                      double padding = ResponsiveUtils.valueByDevice(
                        context: context,
                        mobile: 16,
                        tablet: 24,
                        desktop: 32,
                      );

                      return Container(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth,
                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                        ),
                        margin: EdgeInsets.all(padding),
                        child: Card(
                          shape: const RoundedRectangleBorder(
                            side: BorderSide(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                color: const Color(0xFF760a6b),
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : _userProfile != null
                                        ? UserProfileHeader(
                                            nickname: _userProfile!.nickname,
                                            username: _userProfile!.username,
                                            avatarId: _userProfile!.avatarId,
                                            level: _userProfile!.level,
                                            currentExp: _userProfile!.exp,
                                            maxExp: _userProfile!.expCap,
                                            textStyle: GoogleFonts.rubik(
                                              color: Colors.white,
                                              fontSize: ResponsiveUtils.valueByDevice(
                                                context: context,
                                                mobile: 14,
                                                tablet: 16,
                                                desktop: 18,
                                              ),
                                            ),
                                            selectedLanguage: _selectedLanguage,
                                            showMenuIcon: true,
                                            onUpdateProfile: _handleProfileUpdate,
                                            bannerId: _userProfile!.bannerId,
                                            badgeShowcase: _userProfile!.badgeShowcase,
                                          )
                                        : const SizedBox.shrink(),
                              ),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      ResponsiveUtils.valueByDevice(
                                        context: context,
                                        mobile: 16,
                                        tablet: 20,
                                        desktop: 24,
                                      ),
                                    ),
                                    child: _buildUserProfile(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
          selectedLanguage: _selectedLanguage,
        ),
        Divider(
          color: Colors.black,
          thickness: 1.5,
          height: ResponsiveUtils.valueByDevice(
            context: context,
            mobile: 24,
            tablet: 28,
            desktop: 32,
          ),
        ),
        FavoriteBadges(
          selectedLanguage: _selectedLanguage,
          badgeShowcase: _userProfile!.badgeShowcase,
        ),
      ],
    );
  }
}