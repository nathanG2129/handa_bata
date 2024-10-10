import 'package:flutter/material.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'splash_page.dart'; // Import SplashPage
import '../localization/play/localization.dart'; // Import the localization file

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

    return Container(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ), // Use Rubik font
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _userProfile!.nickname,
                          style: GoogleFonts.rubik(
                            fontSize: 16,
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
                      textStyle: const TextStyle(fontSize: 16),
                      minimumSize: const Size(100, 40), // Set minimum size to constrain the button
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
            Container(
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ), // Use Rubik font
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _userProfile!.birthday,
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                          ), // Use Rubik font
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ), // Use Rubik font
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _showEmail ? _userProfile!.email : _redactEmail(_userProfile!.email),
                          style: GoogleFonts.rubik(
                            fontSize: 16,
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
                      textStyle: const TextStyle(fontSize: 16),
                      minimumSize: const Size(100, 40), // Set minimum size to constrain the button
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
            Container(
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ), // Use Rubik font
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '********',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
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
                      textStyle: const TextStyle(fontSize: 16),
                      minimumSize: const Size(100, 40), // Set minimum size to constrain the button
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
            Container(
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
                            fontSize: 18,
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
                      textStyle: const TextStyle(fontSize: 16),
                      minimumSize: const Size(100, 40), // Set minimum size to constrain the button
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        PlayLocalization.translate('accountRemovalDescription', widget.selectedLanguage),
                        style: GoogleFonts.rubik(
                          fontSize: 16,
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
                            textStyle: const TextStyle(fontSize: 16),
                            minimumSize: const Size(100, 40), // Set minimum size to constrain the button
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
        ),
      ),
    );
  }
}