import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddStageButton extends StatelessWidget {
  final String selectedLanguage;
  final VoidCallback onPressed;

  const AddStageButton({
    super.key,
    required this.selectedLanguage,
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
        selectedLanguage == 'en' ? 'Add English Stage' : 'Add Filipino Stage',
        style: GoogleFonts.vt323(color: Colors.white, fontSize: 20),
      ),
    );
  }
}