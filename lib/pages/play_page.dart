import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:handabatamae/pages/user_profile.dart';
import 'package:handabatamae/services/auth_service.dart';
import 'package:handabatamae/widgets/adventure_button.dart';
import 'package:handabatamae/widgets/arcade_button.dart';
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
    try {
      AuthService authService = AuthService();
      await authService.logout();
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
    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/backgrounds/background.svg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 50), // Adjust the top padding as needed
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _toggleUserProfile,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF241242), // Text color
                      backgroundColor: Colors.white, // Background color
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // Purely rectangular with sharp edges
                        side: BorderSide(color: Color(0xFF241242), width: 1.0), // Border color and width
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), // Adjusted padding for smaller size
                      textStyle: GoogleFonts.rubik(fontSize: 20), // Using Rubik font
                    ),
                    child: const Text('User Profile'),
                  ),
                  const SizedBox(height: 50),
                  AdventureButton(
                    onPressed: () {
                      // Navigate to Adventure mode
                    },
                  ),
                  const SizedBox(height: 20),
                  ArcadeButton(
                    onPressed: () {
                      // Navigate to Arcade mode
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 100, // Adjust the width as needed
                maxHeight: 100, // Adjust the height as needed
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, size: 33, color: Colors.white), // Adjust the icon size and color as needed
                onPressed: _logout,
              ),
            ),
          ),
          if (_isUserProfileVisible)
            UserProfilePage(onClose: _toggleUserProfile),
        ],
      ),
    );
  }
}