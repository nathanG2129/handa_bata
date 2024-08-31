import 'package:flutter/material.dart';
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'splash_page.dart';

class PlayPage extends StatefulWidget {
  final String title;

  const PlayPage({super.key, required this.title});

  @override
  _PlayPageState createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  bool _isUserProfileVisible = false;

  void _toggleUserProfile() {
    setState(() {
      _isUserProfileVisible = !_isUserProfileVisible;
    });
  }

  Future<void> _logout() async {
    AuthService authService = AuthService();
    await authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SplashPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 50), // Adjust the top padding as needed
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _toggleUserProfile,
                    style: ElevatedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      textStyle: const TextStyle(fontSize: 24),
                    ),
                    child: const Text('User Profile'),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Adventure mode
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 100),
                      textStyle: const TextStyle(fontSize: 24),
                    ),
                    child: const Text('Adventure'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Arcade mode
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 100),
                      textStyle: const TextStyle(fontSize: 24),
                    ),
                    child: const Text('Arcade'),
                  ),
                ],
              ),
            ),
          ),
          if (_isUserProfileVisible)
            UserProfilePage(onClose: _toggleUserProfile),
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 100, // Adjust the width as needed
                maxHeight: 100, // Adjust the height as needed
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, size: 33), // Adjust the icon size as needed
                onPressed: _logout,
              ),
            ),
          ),
        ],
      ),
    );
  }
}