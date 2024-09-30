import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

class IdentificationQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final TextEditingController controller;
  final bool isCorrect;
  final Function(String) onAnswerSubmitted;

  const IdentificationQuestion({
    super.key,
    required this.questionData,
    required this.controller,
    required this.isCorrect,
    required this.onAnswerSubmitted,
  });

  @override
  _IdentificationQuestionState createState() => _IdentificationQuestionState();
}

class _IdentificationQuestionState extends State<IdentificationQuestion> {
  bool showInput = false;
  Timer? _timer; // Timer to handle the delay

  @override
  void initState() {
    super.initState();
    _showIntroduction();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer if it exists
    super.dispose();
  }

  void _showIntroduction() {
    setState(() {
      showInput = false;
    });
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showInput = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!showInput)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TextWithShadow(
                  text: 'Identification',
                  fontSize: 40, // Adjusted font size to 40
                ),
                const SizedBox(height: 16),
                Text(
                  widget.questionData['question'] ?? 'No question available',
                  style: GoogleFonts.vt323(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        if (showInput)
          Column(
            children: [
              Center(
                child: Text(
                  widget.questionData['question'] ?? 'No question available',
                  style: GoogleFonts.vt323(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: widget.controller,
                decoration: const InputDecoration(
                  hintText: 'Type your answer here',
                  border: OutlineInputBorder(),
                ),
                style: GoogleFonts.vt323(fontSize: 24),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => widget.onAnswerSubmitted(widget.controller.text),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: widget.isCorrect ? Colors.green : Colors.red,
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
          ),
      ],
    );
  }
}