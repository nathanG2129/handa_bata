import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildQuestionButtons(Function addQuestion) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton(
        onPressed: () => addQuestion('Multiple Choice'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF381c64),
          shadowColor: Colors.transparent,
        ),
        child: Text('Add Multiple Choice', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
      ),
      const SizedBox(width: 10),
      ElevatedButton(
        onPressed: () => addQuestion('Fill in the Blanks'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF381c64),
          shadowColor: Colors.transparent,
        ),
        child: Text('Add Fill in the Blanks', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
      ),
      const SizedBox(width: 10),
      ElevatedButton(
        onPressed: () => addQuestion('Matching Type'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF381c64),
          shadowColor: Colors.transparent,
        ),
        child: Text('Add Matching Type', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
      ),
      const SizedBox(width: 10),
      ElevatedButton(
        onPressed: () => addQuestion('Identification'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF381c64),
          shadowColor: Colors.transparent,
        ),
        child: Text('Add Identification', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
      ),
    ],
  );
}