// lib/widgets/privacy_policy_error.dart
import 'package:flutter/material.dart';

class PrivacyPolicyError extends StatelessWidget {
  final bool showError;

  const PrivacyPolicyError({super.key, required this.showError});

  @override
  Widget build(BuildContext context) {
    if (!showError) return Container();
    return const Text(
      'You must accept the privacy policy to register.',
      style: TextStyle(color: Colors.red),
    );
  }
}