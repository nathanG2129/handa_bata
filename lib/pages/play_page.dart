import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handabatamae/pages/login_page.dart';
import '../models/user_model.dart';
import '/services/auth_service.dart';
import 'user_profile.dart';

class PlayPage extends StatefulWidget {
  final String title;

  const PlayPage({super.key, required this.title});

  @override
  _PlayPageState createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  bool _isUserProfileVisible = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserModel? userModel = await AuthService().fetchUserData(user.uid);
      setState(() {
        _user = userModel;
      });
    }
  }

  void _toggleUserProfile() {
    setState(() {
      _isUserProfileVisible = !_isUserProfileVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_user != null)
                  Text('Welcome, ${_user!.username}'),
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
          if (_isUserProfileVisible)
            UserProfile(onClose: _toggleUserProfile),
        ],
      ),
    );
  }
}