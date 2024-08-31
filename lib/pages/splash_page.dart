import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'play_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfile(title: 'Handa Bata', onClose: () {},)),
      );
    } catch (e) {
      // Handle error
      print('Failed to sign in anonymously: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 210.0), // Adjust this value to control the vertical position
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Handa Bata',
                      style: TextStyle(fontSize: 46, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Text(
                      'Mobile  App  Edition',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 0), // Adjust this value to control the space between the titles and the buttons
            InkWell(
              borderRadius: BorderRadius.circular(30), // Ensure ripple effect respects border radius
              onTap: () {
                // Navigate to the login page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(30), // Oblong shape
                ),
                child: Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    minHeight: 65,
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              borderRadius: BorderRadius.circular(30), // Ensure ripple effect respects border radius
              onTap: () {
                _signInAnonymously(context); // Sign in anonymously and navigate to PlayPage
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(30), // Oblong shape
                ),
                child: Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    minHeight: 65,
                  ),
                  child: const Text(
                    'Play Now',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 140), // Adjust this value to control the space between buttons and the bottom text
            const Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: Text(
                '© 2023 Handa Bata. All rights reserved.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}