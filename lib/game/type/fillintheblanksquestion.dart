import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FillInTheBlanksQuestion extends StatelessWidget {
  final Map<String, dynamic> questionData;
  final TextEditingController controller;
  final bool isCorrect;
  final Function(String) onAnswerSubmitted;

  const FillInTheBlanksQuestion({
    super.key,
    required this.questionData,
    required this.controller,
    required this.isCorrect,
    required this.onAnswerSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Text(
            questionData['question'] ?? 'No question available',
            style: GoogleFonts.vt323(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Type your answer here',
            border: OutlineInputBorder(),
          ),
          style: GoogleFonts.vt323(fontSize: 24),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => onAnswerSubmitted(controller.text),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: isCorrect ? Colors.green : Colors.red,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
          child: Text(
            'Submit',
            style: GoogleFonts.vt323(fontSize: 24),
          ),
        ),
      ],
    );
  }
}