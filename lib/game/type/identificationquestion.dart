import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

class IdentificationQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final TextEditingController controller;
  final Function(String) onAnswerSubmitted;
  final VoidCallback onOptionsShown; // Add the callback to start the timer

  const IdentificationQuestion({
    super.key,
    required this.questionData,
    required this.controller,
    required this.onAnswerSubmitted,
    required this.onOptionsShown, // Add the callback to the constructor
  });

  @override
  IdentificationQuestionState createState() => IdentificationQuestionState();
}

class IdentificationQuestionState extends State<IdentificationQuestion> {
  bool showInput = false;
  Timer? _timer; // Timer to handle the delay
  List<String?> selectedOptions = [];
  List<bool> optionSelected = [];
  List<String> uniqueOptions = [];
  bool isCorrect = false;
  bool isCheckingAnswer = false; // Flag to indicate when the answer is being checked
  bool showCorrectAnswer = false; // Flag to indicate when to show the correct answer

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    _showIntroduction();
    _debugQuestionData();
    _resetState(); // Add debug statements
  }
  
  @override
  void didUpdateWidget(covariant IdentificationQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionData != widget.questionData) {
      _resetState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer if it exists
    super.dispose();
  }

  void _initializeOptions() {
    setState(() {
      int answerLength = widget.questionData['answerLength'];
      selectedOptions = List<String?>.filled(answerLength, null);
      optionSelected = List<bool>.filled(widget.questionData['options'].length, false);
      uniqueOptions = _generateUniqueOptions(widget.questionData['options']);
    });
  }

  List<String> _generateUniqueOptions(List<dynamic> options) {
    List<String> uniqueOptions = [];
    for (int i = 0; i < options.length; i++) {
      uniqueOptions.add('${options[i]}_$i');
    }
    return uniqueOptions;
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
        widget.onOptionsShown(); // Call the callback to start the timer
      }
    });
  }

  void _debugQuestionData() {
    print('Debugging questionData:');
    print('Question: ${widget.questionData['question']}');
    print('Answer Length: ${widget.questionData['answerLength']}');
    print('Options: ${widget.questionData['options']}');
    print('Correct Answer: ${widget.questionData['answer']}');
    print('Spaces: ${widget.questionData['space']}');
  }

  void _handleOptionSelection(int index, String option) {
    setState(() {
      if (index < 0 || index >= optionSelected.length) {
        print('Index out of range: $index');
        return;
      }

      if (optionSelected[index]) {
        // Deselect the option
        int selectedIndex = selectedOptions.indexOf(option);
        if (selectedIndex != -1) {
          selectedOptions[selectedIndex] = null;
        }
        optionSelected[index] = false;
      } else {
        // Select the option
        int emptyIndex = selectedOptions.indexOf(null);
        if (emptyIndex != -1) {
          selectedOptions[emptyIndex] = option;
          optionSelected[index] = true;
        }
      }
    });

    // Check if all slots are filled before checking the answer
    if (!selectedOptions.contains(null)) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    setState(() {
      isCheckingAnswer = true; // Set the flag to true when checking the answer
    });

    String userAnswer = '';
    for (int i = 0; i < widget.questionData['answerLength']; i++) {
      userAnswer += selectedOptions[i]?.split('_')[0] ?? '_';
    }

    // Trim spaces from userAnswer
    userAnswer = userAnswer.trim();

    // Debug printing the constructed answer
    print('Constructed Answer: $userAnswer');

    setState(() {
      isCorrect = userAnswer == widget.questionData['answer'];
    });

    // Call the callback regardless of whether the answer is correct or not
    widget.onAnswerSubmitted(userAnswer);

    // Add a delay before showing the result
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showCorrectAnswer = true; // Show the correct answer after the delay
      });
    });
  }

  // Add a method to force check the answer
  void forceCheckAnswer() {
    _checkAnswer();
  }

  void _resetState() {
    setState(() {
      showInput = false;
      selectedOptions = [];
      optionSelected = [];
      uniqueOptions = [];
      isCorrect = false;
      isCheckingAnswer = false;
      showCorrectAnswer = false;
      _initializeOptions();
      _showIntroduction();
    });
  }

  @override
  Widget build(BuildContext context) {
    String questionText = widget.questionData['question'];
    List<int> spaces = List<int>.from(
        widget.questionData['space'].map((e) => int.parse(e.toString())));

    // Debug printing
    print('Question Text: $questionText');
    print('Options: $uniqueOptions');
    print('Spaces: $spaces');

    String answerText = '';
    int selectedIndex = 0;
    int currentWordLength = 0;
    for (int i = 0; i < widget.questionData['answerLength']; i++) {
      if (selectedIndex < spaces.length && currentWordLength == spaces[selectedIndex]) {
        answerText += ' ';
        currentWordLength = 0;
        selectedIndex++;
      }
      answerText += selectedOptions[i]?.split('_')[0] ?? '_';
      currentWordLength++;
    }

    // Show the correct answer if the flag is set
    if (showCorrectAnswer) {
      answerText = '';
      selectedIndex = 0;
      currentWordLength = 0;
      for (int i = 0; i < widget.questionData['answerLength']; i++) {
        if (selectedIndex < spaces.length && currentWordLength == spaces[selectedIndex]) {
          answerText += ' ';
          currentWordLength = 0;
          selectedIndex++;
        }
        answerText += widget.questionData['answer'][i];
        currentWordLength++;
      }
    }

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
                  questionText,
                  style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), // Updated font style
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
                  questionText,
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: showCorrectAnswer ? Colors.green : (isCheckingAnswer ? (isCorrect ? Colors.green : Colors.red) : Colors.white), // Change color based on correctness
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  answerText,
                  style: GoogleFonts.vt323(fontSize: 32, color: Colors.black), // Updated font style
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                children: uniqueOptions.asMap().entries.map((entry) {
                  int index = entry.key;
                  String option = entry.value;
                  String optionValue = option.split('_')[0];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _handleOptionSelection(index, option);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: optionSelected[index] ? Colors.white : Colors.black,
                        backgroundColor: optionSelected[index] ? Colors.blue : Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: Text(
                        optionValue,
                        style: GoogleFonts.vt323(fontSize: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
      ],
    );
  }
}