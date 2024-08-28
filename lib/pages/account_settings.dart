import 'package:flutter/material.dart';
import 'dart:ui';

class AccountSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldContainer('Username', 'user123', true),
        _buildFieldContainer('Birthday', '01/01/1990', false),
        _buildFieldContainer('Email', 'user@example.com', true),
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
              // Handle delete account button press
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
                  style: const TextStyle(fontSize: 18),
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