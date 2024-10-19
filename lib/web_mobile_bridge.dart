import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:handabatamae/admin/admin_login_page.dart';
import 'package:handabatamae/pages/splash_page.dart';

class WebMobileBridge extends StatelessWidget {
  const WebMobileBridge({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const AdminLoginPage();
    } else {
      return const SplashPage(selectedLanguage: 'en'); // Pass default language
    }
  }
}

  // Widget build(BuildContext context) {
  //     return const AdminHomePage();
  //   }
  