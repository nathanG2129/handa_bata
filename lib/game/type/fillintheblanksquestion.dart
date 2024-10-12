import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

class FillInTheBlanksQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final TextEditingController controller;
  final bool isCorrect;
  final Function(Map<String, dynamic>) onAnswerSubmitted; // Change the type here
  final VoidCallback onOptionsShown; // Add the callback to start the timer
  final VoidCallback nextQuestion; // Add the callback for the next question

  const FillInTheBlanksQuestion({
    super.key,
    required this.questionData,
    required this.controller,
    required this.isCorrect,
    required this.onAnswerSubmitted, // Change the type here
    required this.onOptionsShown,
    required this.nextQuestion, // Add the callback for the next question
  });

  @override
  FillInTheBlanksQuestionState createState() => FillInTheBlanksQuestionState();
}

class FillInTheBlanksQuestionState extends State<FillInTheBlanksQuestion> {
  List<String?> selectedOptions = [];
  List<bool> optionSelected = [];
  bool showOptions = false;
  bool showUserAnswers = false;
  bool showAllRed = false;
  bool isAnswerCorrect = false;
  bool isChecking = false; // Add this flag
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    _showIntroduction();
  }

  @override
  void didUpdateWidget(covariant FillInTheBlanksQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionData != widget.questionData) {
      resetState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeOptions() {
    setState(() {
      selectedOptions = List<String?>.filled(widget.questionData['answer'].length, null);
      optionSelected = List<bool>.filled(widget.questionData['options'].length, false);
    });
  }

  void _showIntroduction() {
    setState(() {
      showOptions = false;
    });
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showOptions = true;
        });
        widget.onOptionsShown(); // Call the callback to start the timer
      }
    });
  }

  void _handleOptionSelection(int index, String option) {
    setState(() {
      if (index < 0 || index >= optionSelected.length) {
        print('Index out of range: $index');
        return;
      }
  
      int optionIndex = selectedOptions.indexOf(option);
      if (optionIndex != -1) {
        selectedOptions[optionIndex] = null;
        optionSelected[index] = false;
      } else {
        int emptyIndex = selectedOptions.indexOf(null);
        if (emptyIndex != -1) {
          selectedOptions[emptyIndex] = option;
          optionSelected[index] = true;
        }
      }
  
      // Check if all input boxes are filled
      if (!selectedOptions.contains(null)) {
        _checkAnswer();
      }
    });
  }

  void _checkAnswer() {
    setState(() {
      isChecking = true; // Set the flag to true when checking starts
    });
  
    List<String> correctOptions = widget.questionData['answer']
        .map<String>((index) => widget.questionData['options'][index as int] as String)
        .toList();
    String userAnswer = selectedOptions.join(',');
    String correctAnswer = correctOptions.join(',');
  
    int correctCount = 0;
    int wrongCount = 0;
    bool isFullyCorrect = true;
  
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i] == correctOptions[i]) {
        correctCount++;
      } else {
        wrongCount++;
        isFullyCorrect = false; // If any answer is wrong, set this to false
      }
    }
  
    setState(() {
      isAnswerCorrect = userAnswer == correctAnswer;
    });
  
    // Stop the timer immediately
    widget.onAnswerSubmitted({
      'answer': userAnswer,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'isFullyCorrect': isFullyCorrect, // Add this to the answer data
    });
  
    // Show user answers after a delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showUserAnswers = true;
      });
  
      // Show the correct answers regardless of whether the user's answers are correct
      Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
        setState(() {
          selectedOptions = correctOptions;
          showOptions = false;
        });
  
        // Call nextQuestion after showing the correct answers
        Future.delayed(const Duration(seconds: 6), () {
          print('Going to next question...');
          widget.nextQuestion();
        });
      });
    });
  }

  // Add a method to force check the answer
  void forceCheckAnswer() {
    if (isChecking) return; // Prevent multiple calls to forceCheckAnswer

    setState(() {
      isChecking = true; // Set the flag to true when checking starts
    });
  
    List<String> correctOptions = widget.questionData['answer']
        .map<String>((index) => widget.questionData['options'][index as int] as String)
        .toList();
    String userAnswer = selectedOptions.join(',');
    String correctAnswer = correctOptions.join(',');
  
    int correctCount = 0;
    int wrongCount = 0;
    bool isFullyCorrect = true;
  
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i] == correctOptions[i]) {
        correctCount++;
      } else {
        wrongCount++;
        isFullyCorrect = false; // If any answer is wrong, set this to false
      }
    }
  
    setState(() {
      isAnswerCorrect = userAnswer == correctAnswer;
    });
  
    // Stop the timer immediately
    widget.onAnswerSubmitted({
      'answer': userAnswer,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'isFullyCorrect': isFullyCorrect, // Add this to the answer data
    });
  
    // Show user answers after a delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showUserAnswers = true;
      });
  
      // Show the correct answers regardless of whether the user's answers are correct
      Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
        setState(() {
          selectedOptions = correctOptions;
          showOptions = false;
        });
  
        // Call nextQuestion after showing the correct answers
        Future.delayed(const Duration(seconds: 6), () {
          print('Going to next question...');
          widget.nextQuestion();
        });
      });
    });
  }

  // Add a method to reset the state
  void resetState() {
    setState(() {
      showOptions = false;
      showUserAnswers = false;
      showAllRed = false;
      isChecking = false; // Reset the flag
      selectedOptions = List<String?>.filled(widget.questionData['answer'].length, null);
      optionSelected = List<bool>.filled(widget.questionData['options'].length, false);
      isAnswerCorrect = false;
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
    String questionText = widget.questionData['question'];
    List<String> options = List<String>.from(widget.questionData['options']);
    List<int> answer = List<int>.from(widget.questionData['answer']);
  
    List<Widget> questionWidgets = [];
    int inputIndex = 0;
  
    questionText.split(' ').forEach((word) {
      if (word == '<input>') {
        Color boxColor = selectedOptions[inputIndex] == null ? const Color(0xFF241242) : Colors.white;
        Color borderColor = selectedOptions[inputIndex] == null ? Colors.white : Colors.black;
        if (showUserAnswers) {
          boxColor = selectedOptions[inputIndex] == options[answer[inputIndex]] ? Colors.green : Colors.red;
        }
        questionWidgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: boxColor,
              border: Border.all(color: borderColor), // Conditionally set border color
              borderRadius: BorderRadius.circular(0),
            ),
            child: Text(
              selectedOptions[inputIndex] ?? '____',
              style: (selectedOptions[inputIndex] == null)
                  ? GoogleFonts.vt323(fontSize: 24, color: Colors.white)
                  : GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        );
        inputIndex++;
      } else {
        questionWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              word,
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    });
  
    return Column(
      children: [
        if (!showOptions && !showUserAnswers)
          const TextWithShadow(
            text: 'Fill in the Blanks',
            fontSize: 40, // Adjusted font size to 40
          ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: questionWidgets,
        ),
        if (showOptions)
          const SizedBox(height: 32),
        if (showOptions)
          SizedBox(
            height: 200, // Adjust the height as needed
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3, // Adjust the aspect ratio as needed
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                String option = options[index];
                return isChecking
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: optionSelected[index] ? const Color(0xFF241242) : Colors.white,
                          borderRadius: BorderRadius.circular(0),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: GoogleFonts.rubik(
                              fontSize: 18,
                              color: optionSelected[index] ? Colors.transparent : Colors.black, // Make text invisible when selected
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          _handleOptionSelection(index, option);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: optionSelected[index] ? Colors.transparent : Colors.black, // Make text invisible when selected
                          backgroundColor: optionSelected[index] ? const Color(0xFF241242) : Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: GoogleFonts.rubik(fontSize: 18),
                          ),
                        ),
                      );
              },
            ),
          ),
      ],
    );
  }
}