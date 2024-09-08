import 'package:flutter/material.dart';
import '/services/auth_service.dart';
import '/models/user_model.dart';

class AccountSettings extends StatefulWidget {
  final VoidCallback onClose;

  const AccountSettings({super.key, required this.onClose});

  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    AuthService authService = AuthService();
    UserProfile? userProfile = await authService.getUserProfile();
    setState(() {
      _userProfile = userProfile ?? UserProfile.guestProfile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProfile == null) {
      return const Center(child: Text('Failed to load user data'));
    }

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldContainer('Nickname', _userProfile!.nickname, true),
              _buildFieldContainer('Birthday', _userProfile!.birthday, false),
              _buildFieldContainer('Email', _userProfile!.email, true),
              _buildFieldContainer('Password', '********', true),
              const SizedBox(height: 20),
              const Text(
                'Account Removal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle account removal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    textStyle: const TextStyle(fontSize: 16),
                    minimumSize: const Size(150, 40), // Set minimum size to constrain the button
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
    );
  }

  Widget _buildFieldContainer(String title, String details, bool showChangeButton) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  details,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          if (showChangeButton)
            TextButton(
              onPressed: () {
                // Handle change button press
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Change'),
            ),
        ],
      ),
    );
  }
}