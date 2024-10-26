import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'splash_page.dart'; // Import SplashPage
import '../localization/play/localization.dart'; // Import the localization file
import 'package:handabatamae/widgets/user_profile/user_profile_header.dart'; // Import UserProfileHeader
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework

class AccountSettings extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onNicknameChanged; // Add this callback
  final String selectedLanguage; // Add this line

  const AccountSettings({super.key, required this.onClose, required this.onNicknameChanged, required this.selectedLanguage});

  @override
  AccountSettingsState createState() => AccountSettingsState();
}

class AccountSettingsState extends State<AccountSettings> {
  bool _isLoading = true;
  UserProfile? _userProfile;
  bool _showEmail = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    AuthService authService = AuthService();
    try {
      UserProfile? userProfile = await authService.getUserProfile();
      if (!mounted) return;
      setState(() {
        _userProfile = userProfile ?? UserProfile.guestProfile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Handle error
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
      await _fetchUserProfile(); // Refresh the user profile
      widget.onNicknameChanged(); // Call the callback
    } catch (e) {
      if (!mounted) return;
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${PlayLocalization.translate('errorUpdatingNickname', widget.selectedLanguage)} $e')),
      );
    }
  }

  void _showChangeNicknameDialog() {
    final TextEditingController controller = TextEditingController(text: _userProfile?.nickname ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(PlayLocalization.translate('changeNickname', widget.selectedLanguage)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: PlayLocalization.translate('newNickname', widget.selectedLanguage),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
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
                await _updateNickname(controller.text);
              },
              child: Text(PlayLocalization.translate('save', widget.selectedLanguage)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    AuthService authService = AuthService();
    try {
      await authService.deleteUserAccount();
      await authService.clearLocalGuestProfile(); // Clear local guest profile
      await authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SplashPage(selectedLanguage: widget.selectedLanguage)),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      // Handle error
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
          title: Text(PlayLocalization.translate('confirmAccountDeletion', widget.selectedLanguage)),
          content: Text(PlayLocalization.translate('accountDeletionWarning', widget.selectedLanguage)),
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
      await authService.logout();
      await authService.clearLocalGuestProfile(); // Clear local guest profile
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SplashPage(selectedLanguage: widget.selectedLanguage)),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${PlayLocalization.translate('error', widget.selectedLanguage)} $e')),
        );
      }
    }
  }

  void _onNicknameChanged() {
    _fetchUserProfile();
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
        widget.onClose();
        return false;
      },
      child: GestureDetector(
        onTap: widget.onClose,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: GestureDetector(
                onTap: () {},
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
                          selectedLanguage: widget.selectedLanguage, // White font color for username and level
                          scaleFactor: 0.8, // Adjust the scale factor for AccountSettings
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
                            child: _buildAccountSettings(),
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
    );
  }

  Widget _buildAccountSettings() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PlayLocalization.translate('nickname', widget.selectedLanguage),
                      style: GoogleFonts.rubik(
                        fontSize: 16, // Scale down font size
                        fontWeight: FontWeight.bold,
                      ), // Use Rubik font
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _userProfile!.nickname,
                      style: GoogleFonts.rubik(
                        fontSize: 14, // Scale down font size
                      ), // Use Rubik font
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showChangeNicknameDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4d278f), // Color of the button
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14), // Scale down font size
                  minimumSize: const Size(80, 35), // Set minimum size to constrain the button
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Rectangular shape
                    side: BorderSide(color: Colors.black, width: 3), // Black border
                  ),
                ),
                child: Text(
                  PlayLocalization.translate('changeNickname', widget.selectedLanguage),
                  style: const TextStyle(color: Colors.white), // Ensure text color is set to white
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PlayLocalization.translate('birthday', widget.selectedLanguage),
                      style: GoogleFonts.rubik(
                        fontSize: 16, // Scale down font size
                        fontWeight: FontWeight.bold,
                      ), // Use Rubik font
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _userProfile!.birthday,
                      style: GoogleFonts.rubik(
                        fontSize: 14, // Scale down font size
                      ), // Use Rubik font
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PlayLocalization.translate('email', widget.selectedLanguage),
                      style: GoogleFonts.rubik(
                        fontSize: 16, // Scale down font size
                        fontWeight: FontWeight.bold,
                      ), // Use Rubik font
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _showEmail ? _userProfile!.email : _redactEmail(_userProfile!.email),
                      style: GoogleFonts.rubik(
                        fontSize: 14, // Scale down font size
                      ), // Use Rubik font
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showEmail = !_showEmail;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White background
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14), // Scale down font size
                  minimumSize: const Size(80, 35), // Set minimum size to constrain the button
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Rectangular shape
                    side: BorderSide(color: Colors.black, width: 3), // Black border
                  ),
                ),
                child: Text(
                  _showEmail ? PlayLocalization.translate('hide', widget.selectedLanguage) : PlayLocalization.translate('show', widget.selectedLanguage),
                  style: const TextStyle(color: Colors.black), // Ensure text color is set to black
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PlayLocalization.translate('password', widget.selectedLanguage),
                      style: GoogleFonts.rubik(
                        fontSize: 16, // Scale down font size
                        fontWeight: FontWeight.bold,
                      ), // Use Rubik font
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '********',
                      style: GoogleFonts.rubik(
                        fontSize: 14, // Scale down font size
                      ), // Use Rubik font
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle password change
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4d278f), // Color of the button
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14), // Scale down font size
                  minimumSize: const Size(80, 35), // Set minimum size to constrain the button
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Rectangular shape
                    side: BorderSide(color: Colors.black, width: 3), // Black border
                  ),
                ),
                child: Text(
                  PlayLocalization.translate('changePassword', widget.selectedLanguage),
                  style: const TextStyle(color: Colors.white), // Ensure text color is set to white
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PlayLocalization.translate('logout', widget.selectedLanguage),
                      style: GoogleFonts.rubik(
                        fontSize: 16, // Scale down font size
                        fontWeight: FontWeight.bold,
                      ), // Use Rubik font
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Red background for logout
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14), // Scale down font size
                  minimumSize: const Size(80, 35), // Set minimum size to constrain the button
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Rectangular shape
                    side: BorderSide(color: Colors.black, width: 3), // Black border
                  ),
                ),
                child: Text(
                  PlayLocalization.translate('logoutButton', widget.selectedLanguage),
                  style: const TextStyle(color: Colors.white), // Ensure text color is set to white
                ),
              ),
            ],
          ),
        ),
        const Divider(
          color: Colors.black,
          thickness: 1,
          indent: 10,
          endIndent: 10,
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PlayLocalization.translate('accountRemoval', widget.selectedLanguage),
                    style: GoogleFonts.rubik(
                      fontSize: 16, // Scale down font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    PlayLocalization.translate('accountRemovalDescription', widget.selectedLanguage),
                    style: GoogleFonts.rubik(
                      fontSize: 14, // Scale down font size
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: _showDeleteAccountDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        textStyle: const TextStyle(fontSize: 14), // Scale down font size
                        minimumSize: const Size(80, 35), // Set minimum size to constrain the button
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // Rectangular shape
                          side: BorderSide(color: Colors.black, width: 3), // Black border
                        ),
                      ),
                      child: Text(
                        PlayLocalization.translate('delete', widget.selectedLanguage),
                        style: const TextStyle(color: Colors.white), // Ensure text color is set to white
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}