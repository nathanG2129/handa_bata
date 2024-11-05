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

class AccountSettings extends StatefulWidget {
  final VoidCallback onClose;
  final String selectedLanguage; // Add this line

  const AccountSettings({super.key, required this.onClose, required this.selectedLanguage});

  @override
  AccountSettingsState createState() => AccountSettingsState();
}

class AccountSettingsState extends State<AccountSettings> with TickerProviderStateMixin {
  bool _isLoading = true;
  UserProfile? _userProfile;
  bool _showEmail = false;
  String _userRole = 'user';

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
    _fetchUserProfileAndRole();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _fetchUserProfileAndRole() async {
    AuthService authService = AuthService();
    try {
      UserProfile? userProfile = await authService.getUserProfile();
      String? role = await authService.getUserRole(userProfile?.profileId ?? '');
      
      if (!mounted) return;
      setState(() {
        _userProfile = userProfile ?? UserProfile.guestProfile;
        _userRole = role ?? 'guest';
        _isLoading = false;
        _animationController.forward();
      });
    } catch (e) {
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
    AuthService authService = AuthService();
    try {
      await authService.updateUserProfile('nickname', newNickname);
      await _fetchUserProfileAndRole(); // Refresh the user profile
      _onNicknameChanged(); // Call the callback
    } catch (e) {
      if (!mounted) return;
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${PlayLocalization.translate('errorUpdatingNickname', widget.selectedLanguage)} $e')),
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
      await authService.deleteUserAccount();
      await authService.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SplashPage(selectedLanguage: widget.selectedLanguage)),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${PlayLocalization.translate('errorDeletingAccount', widget.selectedLanguage)} $e')),
      );
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
          content: Text(PlayLocalization.translate(
            _userRole == 'guest' ? 'deleteGuestAccountConfirmation' : 'deleteAccountConfirmation', 
            widget.selectedLanguage
          )),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
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
    List<String> parts = email.split('@');
    if (parts.length != 2) return email;
    String username = parts[0];
    String domain = parts[1];
    String redactedUsername = username.length > 2 ? username[0] + '*' * (username.length - 2) + username[username.length - 1] : username;
    return '$redactedUsername@$domain';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfile == null) {
      return Center(child: Text(PlayLocalization.translate('errorFetchingProfile', widget.selectedLanguage)));
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
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 110), // Update this line
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black, width: 1), // Black border for the dialog
                      borderRadius: BorderRadius.zero, // Purely rectangular
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          color: const Color(0xFF760a6b), // Background color for username, level, and profile picture
                          child: UserProfileHeader(
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
                            ),
                            selectedLanguage: widget.selectedLanguage, bannerId: _userProfile!.bannerId, // White font color for username and level
                            badgeShowcase: _userProfile!.badgeShowcase,
                          ),
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
                                userProfile: _userProfile!,
                                showEmail: _showEmail,
                                onToggleEmailVisibility: () {
                                  setState(() {
                                    _showEmail = !_showEmail;
                                  });
                                },
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