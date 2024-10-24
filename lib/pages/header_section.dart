import 'package:flutter/material.dart';
import 'package:handabatamae/pages/splash_page.dart';
import 'package:handabatamae/widgets/header_footer/header_widget.dart';

class HeaderSection extends StatelessWidget {
  final String selectedLanguage;
  final VoidCallback onToggleUserProfile;
  final ValueChanged<String> onChangeLanguage;

  const HeaderSection({
    super.key,
    required this.selectedLanguage,
    required this.onToggleUserProfile,
    required this.onChangeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return HeaderWidget(
      selectedLanguage: selectedLanguage,
      onBack: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SplashPage(selectedLanguage: selectedLanguage)),
        );
      },
      onToggleUserProfile: onToggleUserProfile,
      onChangeLanguage: onChangeLanguage,
    );
  }
}