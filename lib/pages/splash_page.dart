import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the login_page.dart file
import 'play_page.dart'; // Import the home_page.dart file

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

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
                // Navigate to the home page as a guest
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage(title: 'Handa Bata')),
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