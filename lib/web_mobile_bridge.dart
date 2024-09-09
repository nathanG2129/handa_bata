import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:handabatamae/admin/admin_login_page.dart';
import 'package:handabatamae/pages/splash_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return AdminLoginPage();
    } else {
      return SplashPage();
    }
  }
}