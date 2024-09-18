import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_stage_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  void _navigateToStagePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminStagePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.vt323TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF381c64),
        body: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/backgrounds/background.svg',
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                const NavBar(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AdminButton(
                            text: 'Button 1',
                            onPressed: () {
                              // Add your functionality here
                            },
                          ),
                          const SizedBox(height: 20),
                          AdminButton(
                            text: 'Button 2',
                            onPressed: () {
                              // Add your functionality here
                            },
                          ),
                          const SizedBox(height: 20),
                          AdminButton(
                            text: 'Button 3',
                            onPressed: () {
                              // Add your functionality here
                            },
                          ),
                          const SizedBox(height: 20),
                          AdminButton(
                            text: 'Manage Stages',
                            onPressed: () => _navigateToStagePage(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF381c64),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('Admin Panel', style: GoogleFonts.vt323(color: Colors.white, fontSize: 35)),
      ),
    );
  }
}

class AdminButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AdminButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF381c64),
        shadowColor: Colors.transparent, // Remove button highlight
      ),
      child: Text(
        text,
        style: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
      ),
    );
  }
}