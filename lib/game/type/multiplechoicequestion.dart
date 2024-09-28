import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/text_with_shadow.dart';

class MultipleChoiceQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final int? selectedOptionIndex; // Allow null values
  final Function(int) onOptionSelected;
  final VoidCallback onOptionsShown; // Callback to notify when options are shown

  const MultipleChoiceQuestion({
    Key? key,
    required this.questionData,
    required this.selectedOptionIndex,
    required this.onOptionSelected,
    required this.onOptionsShown,
  }) : super(key: key);

  @override
  _MultipleChoiceQuestionState createState() => _MultipleChoiceQuestionState();
}

class _MultipleChoiceQuestionState extends State<MultipleChoiceQuestion> {
  String? resultMessage;
  bool showOptions = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        showOptions = true;
        widget.onOptionsShown(); // Notify that options are shown
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> options = List<String>.from(widget.questionData['options'] ?? []);
    int? correctOptionIndex = widget.questionData['answer'];

    if (correctOptionIndex == null || correctOptionIndex < 0 || correctOptionIndex >= options.length) {
      return Center(
        child: Text(
          'Error: Correct option index is null or out of range',
          style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(
          children: [
            if (!showOptions)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const TextWithShadow(
                      text: 'Multiple Choice',
                      fontSize: 48, // Increased font size
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.questionData['question'] ?? 'No question available',
                      style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            if (showOptions)
              Column(
                children: [
                  Center(
                    child: Text(
                      widget.questionData['question'] ?? 'No question available',
                      style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
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
                      if (widget.selectedOptionIndex != null) {
                        if (index == widget.selectedOptionIndex) {
                          buttonColor = widget.selectedOptionIndex == correctOptionIndex ? Colors.green : Colors.red;
                          textColor = Colors.white;
                        } else if (index == correctOptionIndex) {
                          buttonColor = Colors.green;
                          textColor = Colors.white;
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          onPressed: widget.selectedOptionIndex == null
                              ? () {
                                  widget.onOptionSelected(index);
                                  setState(() {
                                    resultMessage = index == correctOptionIndex ? 'Correct' : 'Wrong';
                                  });
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
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Correct Answer: ${options[correctOptionIndex]}',
                      style: GoogleFonts.rubik(fontSize: 24, color: Colors.blue),
                      textAlign: TextAlign.center,
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