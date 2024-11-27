// lib/widgets/privacy_policy_error.dart
import 'package:flutter/material.dart';

class PrivacyPolicyError extends StatelessWidget {
  final bool showError;
  final String selectedLanguage;

  const PrivacyPolicyError({
    super.key, 
    required this.showError,
    required this.selectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    if (!showError) return Container();
    return Text(
      selectedLanguage == 'en' 
        ? 'You must accept the privacy policy and terms of service to create an account.'
        : 'Dapat kang sumang-ayon sa Patakaran sa Privacy at Mga Tuntunin ng Serbisyo upang gumawa ng account.',
      style: const TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    );
  }
}