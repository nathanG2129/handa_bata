import 'package:flutter/material.dart';
import 'admin_session.dart';
import '../admin_login_page.dart';

class SecureRoute extends StatelessWidget {
  final Widget child;
  
  const SecureRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AdminSession().sessionState,
      initialData: false,
      builder: (context, snapshot) {

        if (snapshot.hasError) {
          return const AdminLoginPage();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return const AdminLoginPage();
      },
    );
  }
} 