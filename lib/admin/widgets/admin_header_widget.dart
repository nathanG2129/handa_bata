import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/admin/admin_home_page.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/admin/admin_login_dialog.dart';

class AdminHeaderWidget extends StatelessWidget {
  const AdminHeaderWidget({super.key});

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AdminLoginDialog(
          onLogin: (username, password) {
            if (username == 'admin' && password == 'password') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminHomePage(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid credentials'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isTabletOrMobile = sizingInformation.deviceScreenType == DeviceScreenType.tablet || 
                                sizingInformation.deviceScreenType == DeviceScreenType.mobile;

        return Container(
          height: isTabletOrMobile ? 60 : 80,
          color: const Color(0xFF351b61),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Text(
                'HANDA BATA MOBILE',
                style: GoogleFonts.vt323(
                  fontSize: isTabletOrMobile ? 20 : 24,
                  color: Colors.white,
                ),
              ),
              // Admin Login Text Button
              TextButton(
                onPressed: () => _showLoginDialog(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Admin Login',
                  style: GoogleFonts.vt323(
                    fontSize: isTabletOrMobile ? 16 : 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 