import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminBadgePage extends StatelessWidget {
  const AdminBadgePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.vt323TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Manage Badges', style: GoogleFonts.vt323(color: Colors.white, fontSize: 30)),
          backgroundColor: const Color(0xFF381c64),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: const Color(0xFF381c64),
        body: Center(
          child: Text('Badge Management Page', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
        ),
      ),
    );
  }
}