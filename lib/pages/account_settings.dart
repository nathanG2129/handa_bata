import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:handabatamae/widgets/dialogs/change_nickname_dialog.dart';
import 'splash_page.dart'; // Import SplashPage
import '../localization/play/localization.dart'; // Import the localization file
import 'package:handabatamae/widgets/user_profile/user_profile_header.dart'; // Import UserProfileHeader
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework
import 'account_settings_content.dart'; // Import the new file
// Import FavoriteBadges
import 'package:handabatamae/services/user_profile_service.dart';

class AccountSettings extends StatefulWidget {
  final VoidCallback onClose;
  final String selectedLanguage; // Add this line

  const AccountSettings({super.key, required this.onClose, required this.selectedLanguage});

  @override
  AccountSettingsState createState() => AccountSettingsState();
}

class AccountSettingsState extends State<AccountSettings> with TickerProviderStateMixin {
  final UserProfileService _userProfileService = UserProfileService();
  bool _isLoading = true;
  UserProfile? _userProfile;
  String _userRole = 'user';

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late StreamSubscription<UserProfile> _profileSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    
    // Listen to profile updates
    _profileSubscription = _userProfileService.profileUpdates.listen((profile) {
      if (mounted) {
        setState(() {
          _userProfile = profile;
          // Keep role unchanged as it's managed separately
        });
      }
    });

    _fetchUserProfileAndRole();
  }

  @override
  void dispose() {
    _profileSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
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
  }

  Future<void> _fetchUserProfileAndRole() async {
    try {
      print('\n🔍 FETCHING USER PROFILE AND ROLE');
      
      // 1. Get profile first
      UserProfile? profile = await _userProfileService.fetchUserProfile();
      if (profile == null) {
        throw Exception('No profile found');
      }
      print('✅ Profile fetched - ID: ${profile.profileId}');

      // 2. Then get role using the profile's ID
      AuthService authService = AuthService();
      String? role = await authService.getUserRole(profile.profileId);
      print('👤 User role: ${role ?? 'guest'}');
      
      if (!mounted) return;
      setState(() {
        _userProfile = profile;
        _userRole = role ?? 'guest';
        _isLoading = false;
        _animationController.forward();
      });
      
      print('✅ Profile and role fetch completed\n');
    } catch (e) {
      print('❌ Error fetching profile and role: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${PlayLocalization.translate('errorFetchingProfile', widget.selectedLanguage)} $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNickname(String newNickname) async {
    try {
      print('\n🔄 UPDATING NICKNAME');
      await _userProfileService.updateProfileWithIntegration('nickname', newNickname);
      print('✅ Nickname update completed\n');
    } catch (e) {
      print('❌ Error updating nickname: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          '${PlayLocalization.translate('errorUpdatingNickname', widget.selectedLanguage)} $e'
        )),
      );
    }
  }

  void _showChangeNicknameDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return ChangeNicknameDialog(
          currentNickname: _userProfile?.nickname ?? '',
          selectedLanguage: widget.selectedLanguage,
          onNicknameChanged: _updateNickname,
          darkenColor: _darkenColor,
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    AuthService authService = AuthService();
    try {
      print('\n🗑️ DELETING ACCOUNT');
      setState(() => _isLoading = true);

      // Delete account
      await authService.deleteUserAccount();
      print('✅ Account deleted successfully');

      if (!mounted) return;

      // Navigate to splash page and clear navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => SplashPage(selectedLanguage: widget.selectedLanguage)
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('❌ Error deleting account: $e');
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('reauthenticate') 
              ? PlayLocalization.translate('reauthRequired', widget.selectedLanguage)
              : '${PlayLocalization.translate('errorDeletingAccount', widget.selectedLanguage)} $e'
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(PlayLocalization.translate(
            _userRole == 'guest' ? 'deleteGuestAccount' : 'deleteAccount', 
            widget.selectedLanguage
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(PlayLocalization.translate(
                _userRole == 'guest' ? 'deleteGuestAccountConfirmation' : 'deleteAccountConfirmation', 
                widget.selectedLanguage
              )),
              const SizedBox(height: 10),
              Text(
                PlayLocalization.translate('deleteAccountWarning', widget.selectedLanguage),
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(PlayLocalization.translate('cancel', widget.selectedLanguage)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(PlayLocalization.translate('delete', widget.selectedLanguage)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      AuthService authService = AuthService();
      await authService.signOut();
      
      if (!mounted) return;
      
      // Navigate to splash page and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => SplashPage(selectedLanguage: widget.selectedLanguage,)),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${PlayLocalization.translate('errorLoggingOut', widget.selectedLanguage)} $e')),
      );
    }
  }

  void _onNicknameChanged() {
    _fetchUserProfileAndRole();
  }

  Color _darkenColor(Color color, [double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  String _redactEmail(String email) {
    try {
      print('\n🔒 REDACTING EMAIL');
      List<String> parts = email.split('@');
      if (parts.length != 2) {
        print('⚠️ Invalid email format');
        return email;
      }

      String username = parts[0];
      String domain = parts[1];

      // Keep first 3 letters, add fixed number of asterisks (5)
      String redactedUsername = username.length > 3 
        ? '${username.substring(0, 3)}***********'
        : username;
      
      print('✅ Email redacted successfully\n');
      return '$redactedUsername@$domain';
    } catch (e) {
      print('❌ Error redacting email: $e');
      return email;
    }
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 110),
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          color: const Color(0xFF760a6b),
                          child: _userProfile != null
                              ? UserProfileHeader(
                                  nickname: _userProfile!.nickname,
                                  username: _userProfile!.username,
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
                                  ),
                                  selectedLanguage: widget.selectedLanguage,
                                  bannerId: _userProfile!.bannerId,
                                  badgeShowcase: _userProfile!.badgeShowcase,
                                )
                              : const SizedBox.shrink(),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(
                                ResponsiveValue<double>(
                                  context,
                                  defaultValue: 10.0,
                                  conditionalValues: [
                                    const Condition.smallerThan(name: MOBILE, value: 16.0),
                                    const Condition.largerThan(name: MOBILE, value: 24.0),
                                  ],
                                ).value,
                              ),
                              child: AccountSettingsContent(
                                userProfile: _userProfile ?? UserProfile.guestProfile,
                                onShowChangeNicknameDialog: _showChangeNicknameDialog,
                                onLogout: _logout,
                                onShowDeleteAccountDialog: _showDeleteAccountDialog,
                                selectedLanguage: widget.selectedLanguage,
                                darkenColor: _darkenColor,
                                redactEmail: _redactEmail,
                                userRole: _userRole,
                              ),
                            ),
                          ),
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
}