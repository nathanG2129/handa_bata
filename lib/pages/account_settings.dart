import 'package:flutter/material.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:responsive_framework/responsive_framework.dart'; // Import Responsive Framework
import 'splash_page.dart'; // Import SplashPage

class AccountSettings extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onNicknameChanged; // Add this callback

  const AccountSettings({super.key, required this.onClose, required this.onNicknameChanged});

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
        SnackBar(content: Text('Error fetching user profile: $e')),
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
        SnackBar(content: Text('Error updating nickname: $e')),
      );
    }
  }

  void _showChangeNicknameDialog() {
    final TextEditingController controller = TextEditingController(text: _userProfile?.nickname ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Nickname'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'New Nickname',
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateNickname(controller.text);
              },
              child: const Text('Save'),
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
      // Navigate back or show a success message
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
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
          MaterialPageRoute(builder: (context) => const SplashPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfile == null) {
      return const Center(child: Text('Failed to load user data'));
    }

    return Container(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldContainer('Nickname', _userProfile!.nickname, true),
            _buildFieldContainer('Birthday', _userProfile!.birthday, false),
            _buildFieldContainer('Email', _showEmail ? _userProfile!.email : _redactEmail(_userProfile!.email), false), // Redact the email
            _buildFieldContainer('Password', '********', true),
            _buildFieldContainer('Logout', '', false), // Add the Logout button here
            const Divider(
              color: Colors.black,
              thickness: 1,
              indent: 10,
              endIndent: 10,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveValue<double>(
                      context,
                      defaultValue: 10.0,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 8.0),
                        const Condition.largerThan(name: MOBILE, value: 12.0),
                      ],
                    ).value,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Removal',
                        style: GoogleFonts.rubik(
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 18,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 16),
                              const Condition.largerThan(name: MOBILE, value: 20),
                            ],
                          ).value,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveValue<double>(
                          context,
                          defaultValue: 10,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 8),
                            const Condition.largerThan(name: MOBILE, value: 12),
                          ],
                        ).value,
                      ),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                        style: GoogleFonts.rubik(
                          fontSize: ResponsiveValue<double>(
                            context,
                            defaultValue: 16,
                            conditionalValues: [
                              const Condition.smallerThan(name: MOBILE, value: 14),
                              const Condition.largerThan(name: MOBILE, value: 18),
                            ],
                          ).value,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveValue<double>(
                          context,
                          defaultValue: 10,
                          conditionalValues: [
                            const Condition.smallerThan(name: MOBILE, value: 8),
                            const Condition.largerThan(name: MOBILE, value: 12),
                          ],
                        ).value,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: _showDeleteAccountDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveValue<double>(
                                context,
                                defaultValue: 20,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 16),
                                  const Condition.largerThan(name: MOBILE, value: 24),
                                ],
                              ).value,
                              vertical: ResponsiveValue<double>(
                                context,
                                defaultValue: 10,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 8),
                                  const Condition.largerThan(name: MOBILE, value: 12),
                                ],
                              ).value,
                            ),
                            textStyle: TextStyle(
                              fontSize: ResponsiveValue<double>(
                                context,
                                defaultValue: 16,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 14),
                                  const Condition.largerThan(name: MOBILE, value: 18),
                                ],
                              ).value,
                            ),
                            minimumSize: Size(
                              ResponsiveValue<double>(
                                context,
                                defaultValue: 150,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 120),
                                  const Condition.largerThan(name: MOBILE, value: 180),
                                ],
                              ).value,
                              ResponsiveValue<double>(
                                context,
                                defaultValue: 40,
                                conditionalValues: [
                                  const Condition.smallerThan(name: MOBILE, value: 30),
                                  const Condition.largerThan(name: MOBILE, value: 50),
                                ],
                              ).value,
                            ), // Set minimum size to constrain the button
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // Rectangular shape
                              side: BorderSide(color: Colors.black, width: 3), // Black border
                            ),
                          ),
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.white), // Ensure text color is set to white
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

  String _redactEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email; // Return the original email if it's not valid
    final redacted = '*' * (parts[0].length > 9 ? 9 : parts[0].length);
    return '$redacted@${parts[1]}';
  }

  Widget _buildFieldContainer(String title, String details, bool showChangeButton) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveValue<double>(
          context,
          defaultValue: 10.0,
          conditionalValues: [
            const Condition.smallerThan(name: MOBILE, value: 8.0),
            const Condition.largerThan(name: MOBILE, value: 12.0),
          ],
        ).value,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: ResponsiveValue<double>(
                      context,
                      defaultValue: 18,
                      conditionalValues: [
                        const Condition.smallerThan(name: MOBILE, value: 16),
                        const Condition.largerThan(name: MOBILE, value: 20),
                      ],
                    ).value,
                    fontWeight: FontWeight.bold,
                  ), // Use Rubik font
                ),
                SizedBox(
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: 5,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 4),
                      const Condition.largerThan(name: MOBILE, value: 6),
                    ],
                  ).value,
                ),
                if (title != 'Logout') // Hide details for Logout
                  Text(
                    details,
                    style: GoogleFonts.rubik(
                      fontSize: ResponsiveValue<double>(
                        context,
                        defaultValue: 16,
                        conditionalValues: [
                          const Condition.smallerThan(name: MOBILE, value: 14),
                          const Condition.largerThan(name: MOBILE, value: 18),
                        ],
                      ).value,
                    ), // Use Rubik font
                  ),
              ],
            ),
          ),
          if (showChangeButton && title != 'Email' && title != 'Logout') // Conditionally show the button
            ElevatedButton(
              onPressed: () {
                _showChangeNicknameDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4d278f), // Color of the button
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveValue<double>(
                    context,
                    defaultValue: 20,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 16),
                      const Condition.largerThan(name: MOBILE, value: 24),
                    ],
                  ).value,
                  vertical: ResponsiveValue<double>(
                    context,
                    defaultValue: 10,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 8),
                      const Condition.largerThan(name: MOBILE, value: 12),
                    ],
                  ).value,
                ),
                textStyle: TextStyle(
                  fontSize: ResponsiveValue<double>(
                    context,
                    defaultValue: 16,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 14),
                      const Condition.largerThan(name: MOBILE, value: 18),
                    ],
                  ).value,
                ),
                minimumSize: Size(
                  ResponsiveValue<double>(
                    context,
                    defaultValue: 100,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 80),
                      const Condition.largerThan(name: MOBILE, value: 120),
                    ],
                  ).value,
                  ResponsiveValue<double>(
                    context,
                    defaultValue: 40,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 30),
                      const Condition.largerThan(name: MOBILE, value: 50),
                    ],
                  ).value,
                ), // Set minimum size to constrain the button
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Rectangular shape
                  side: BorderSide(color: Colors.black, width: 3), // Black border
                ),
              ),
              child: const Text(
                'Change',
                style: TextStyle(color: Colors.white), // Ensure text color is set to white
              ),
            ),
          if (title == 'Email') // Conditionally show the Show button for Email
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showEmail = !_showEmail;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // White background
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveValue<double>(
                    context,
                    defaultValue: 20,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 16),
                      const Condition.largerThan(name: MOBILE, value: 24),
                    ],
                  ).value,
                  vertical: ResponsiveValue<double>(
                    context,
                    defaultValue: 10,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 8),
                      const Condition.largerThan(name: MOBILE, value: 12),
                    ],
                  ).value,
                ),
                textStyle: TextStyle(
                  fontSize: ResponsiveValue<double>(
                    context,
                    defaultValue: 16,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 14),
                      const Condition.largerThan(name: MOBILE, value: 18),
                    ],
                  ).value,
                ),
                minimumSize: Size(
                  ResponsiveValue<double>(
                    context,
                    defaultValue: 100,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 80),
                      const Condition.largerThan(name: MOBILE, value: 120),
                    ],
                  ).value,
                  ResponsiveValue<double>(
                    context,
                    defaultValue: 40,
                    conditionalValues: [
                      const Condition.smallerThan(name: MOBILE, value: 30),
                      const Condition.largerThan(name: MOBILE, value: 50),
                    ],
                  ).value,
                ), // Set minimum size to constrain the button
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Rectangular shape
                  side: BorderSide(color: Colors.black, width: 3), // Black border
                ),
              ),
              child: Text(
                _showEmail ? 'Hide' : 'Show',
                style: const TextStyle(color: Colors.black), // Ensure text color is set to black
              ),
            ),
        ],
      ),
    );
  }
}