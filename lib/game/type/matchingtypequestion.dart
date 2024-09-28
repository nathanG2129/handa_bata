import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchingTypeQuestion extends StatelessWidget {
  final Map<String, dynamic> questionData;
  final Function(Map<String, String>) onMatchingCompleted;

  const MatchingTypeQuestion({
    Key? key,
    required this.questionData,
    required this.onMatchingCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implement the UI for matching type question
    return Center(
      child: Text(
        'Matching Type Question',
        style: GoogleFonts.vt323(fontSize: 24),
      ),
    );
  }
}