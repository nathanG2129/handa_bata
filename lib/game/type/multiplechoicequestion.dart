import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/text_with_shadow.dart';

class MultipleChoiceQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final int? selectedOptionIndex; // Allow null values
  final Function(int, bool) onOptionSelected; // Update the callback to include correctness
  final VoidCallback onOptionsShown; // Callback to notify when options are shown

  const MultipleChoiceQuestion({
    super.key,
    required this.questionData,
    required this.selectedOptionIndex,
    required this.onOptionSelected,
    required this.onOptionsShown,
  });

  @override
  MultipleChoiceQuestionState createState() => MultipleChoiceQuestionState();
}

class MultipleChoiceQuestionState extends State<MultipleChoiceQuestion> {
  String? resultMessage;
  bool showOptions = false;
  bool showSelectedAnswer = false;
  bool showAllAnswers = false;
  bool showAllRed = false; // New state variable to show all options as red
  Timer? _timer; // Timer to handle the delay

  @override
  void initState() {
    super.initState();
    resetState();
  }
  
  @override
  void didUpdateWidget(covariant MultipleChoiceQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionData != widget.questionData) {
      resetState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer if it exists
    super.dispose();
  }

  void _handleOptionSelected(int index) {
    bool isCorrect = index == int.parse(widget.questionData['answer'].toString());
    widget.onOptionSelected(index, isCorrect);
  
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showSelectedAnswer = true;
      });
  
      Future.delayed(const Duration(seconds: 1, milliseconds: 250), () {
        setState(() {
          showAllAnswers = true;
        });
      });
    });
  }

  // Add a method to force check the answer
void forceCheckAnswer() {
  setState(() {
    showAllRed = true; // Show all options as red
  });

  // Call the onOptionSelected callback with null index and false correctness
  widget.onOptionSelected(-1, false);

  Future.delayed(const Duration(seconds: 1), () {
    setState(() {
      showAllRed = false;
      showAllAnswers = true;
    });

    // Reset state after showing answers
    Future.delayed(const Duration(seconds: 3), () {
      resetState();
    });
  });
}

  void resetState() {
    setState(() {
      resultMessage = null;
      showOptions = false;
      showSelectedAnswer = false;
      showAllAnswers = false;
      showAllRed = false;
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            showOptions = true;
            widget.onOptionsShown(); // Notify that options are shown
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> options = List<String>.from(widget.questionData['options'] ?? []);
    int? correctOptionIndex;

    try {
      correctOptionIndex = int.parse(widget.questionData['answer'].toString());
    } catch (e) {
      correctOptionIndex = null;
    }

    if (correctOptionIndex == null || correctOptionIndex < 0 || correctOptionIndex >= options.length) {
      return Center(
        child: Text(
          'Error: Correct option index is null or out of range',
          style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        if (!showOptions)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TextWithShadow(
                  text: 'Multiple Choice',
                  fontSize: 40, // Adjusted font size to 40
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    widget.questionData['question'] ?? '',
                    style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        if (showOptions)
          Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    widget.questionData['question'] ?? '',
                    style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  Color buttonColor = Colors.white;
                  Color textColor = Colors.black;
                  if (showAllRed) {
                    buttonColor = Colors.red;
                    textColor = Colors.white;
                  } else if (showSelectedAnswer && index == widget.selectedOptionIndex) {
                    buttonColor = widget.selectedOptionIndex == correctOptionIndex ? Colors.green : Colors.red;
                    textColor = Colors.white;
                  } else if (showAllAnswers) {
                    if (index == widget.selectedOptionIndex) {
                      buttonColor = widget.selectedOptionIndex == correctOptionIndex ? Colors.green : Colors.red;
                      textColor = Colors.white;
                    } else {
                      buttonColor = index == correctOptionIndex ? Colors.green : Colors.red;
                      textColor = Colors.white;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: widget.selectedOptionIndex == null
                          ? () {
                              _handleOptionSelected(index);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: textColor,
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        disabledBackgroundColor: buttonColor, // Ensure the background color is not transparent when disabled
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D, etc.
                                style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              options[index],
                              style: GoogleFonts.rubik(fontSize: 18, color: Colors.black), // Smaller font size for options
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (resultMessage != null)
                Center(
                  child: Text(
                    resultMessage!,
                    style: GoogleFonts.rubik(fontSize: 24, color: resultMessage == 'Correct' ? Colors.green : Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}