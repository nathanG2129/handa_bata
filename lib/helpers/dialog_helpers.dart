// lib/helpers/dialog_helpers.dart
import 'package:flutter/material.dart';
import '../pages/login_page.dart';

void showEmailVerificationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Verify your email'),
        content: const Text('A verification link has been sent to your email. Please check your email to verify your account.'),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      );
    },
  );
}