import 'package:flutter/material.dart';
import 'admin_session.dart';
import '../admin_login_page.dart';

class SecureRoute extends StatelessWidget {
  final Widget child;
  
  const SecureRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    print('\n🔒 SECURE ROUTE BUILD');
    return StreamBuilder<bool>(
      stream: AdminSession().sessionState,
      initialData: false,
      builder: (context, snapshot) {
        print('📊 StreamBuilder update:');
        print('  - Has error: ${snapshot.hasError}');
        print('  - Connection state: ${snapshot.connectionState}');
        print('  - Data: ${snapshot.data}');

        if (snapshot.hasError) {
          print('❌ StreamBuilder error: ${snapshot.error}');
          return const AdminLoginPage();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ Waiting for session state...');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          print('✅ Session valid - showing protected content');
          return child;
        }

        print('❌ Session invalid - redirecting to login');
        return const AdminLoginPage();
      },
    );
  }
} 