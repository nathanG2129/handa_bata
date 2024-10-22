import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFF351B61),
        border: Border(
          top: BorderSide(color: Colors.white, width: 2.0), // Add white border to the top
        ),
      ),
      child: Column(
        children: [
        const SizedBox(width: 50),
          Text(
            'Handa Bata © 2023',
            style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Privacy Policy',
                  style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Terms of Service',
                  style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
                ),
              ),
            const SizedBox(height: 50),
            ],
          ),
        ],
      ),
    );
  }
}