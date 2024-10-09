// lib/widgets/register_buttons.dart
import 'package:flutter/material.dart';
import '../pages/login_page.dart';

class RegisterButtons extends StatelessWidget {
  final VoidCallback onRegister;
  final String selectedLanguage; // Add this line

  const RegisterButtons({super.key, required this.onRegister, required this.selectedLanguage}); // Update constructor

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onRegister,
          child: const Text('Join'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginPage(selectedLanguage: selectedLanguage)), // Pass selectedLanguage
            );
          },
          child: const Text('Have an account? Login instead'),
        ),
      ],
    );
  }
}