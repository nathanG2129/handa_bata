// lib/styles/input_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InputStyles {
  static InputDecoration inputDecoration(String labelText) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF191919), // Changed fill color to #191919
      labelText: labelText,
      labelStyle: GoogleFonts.rubik(color: Colors.white), // Changed label color to white
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0.0),
        borderSide: const BorderSide(color: Colors.white), // Added white border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0.0),
        borderSide: const BorderSide(color: Colors.white), // Added white border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0.0),
        borderSide: const BorderSide(color: Colors.white), // Added white border
      ),
      errorStyle: GoogleFonts.rubik(
        color: const Color(0xFFc82c2c),  // Brighter red for better visibility
        fontSize: 14,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0.0),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0.0),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
      ),
    );
  }
}