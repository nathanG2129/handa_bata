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
  
      // If the answer is incorrect, show the correct answers
      if (!isAnswerCorrect) {
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            selectedOptions = correctOptions;
          });
  
          // Call nextQuestion after showing the correct answers
          Future.delayed(const Duration(seconds: 4), () {
            widget.nextQuestion();
          });
        });
      } else {
        // Call nextQuestion after a delay even if the answer is correct
        Future.delayed(const Duration(seconds: 4), () {
          widget.nextQuestion();
        });
      }
    });
  }
  
  // Add a method to force check the answer
   void forceCheckAnswer() {
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
  
      // If the answer is incorrect, show the correct answers
      if (!isAnswerCorrect) {
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            selectedOptions = correctOptions;
          });
  
          // Call nextQuestion after showing the correct answers
          Future.delayed(const Duration(seconds: 4), () {
            widget.nextQuestion();
          });
        });
      } else {
        // Call nextQuestion after a delay even if the answer is correct
        Future.delayed(const Duration(seconds: 4), () {
          widget.nextQuestion();
        });
      }
    });
  }

  // Add a method to reset the state
  void resetState() {
    setState(() {
      showOptions = false;
      showUserAnswers = false;
      showAllRed = false;
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
        Color boxColor = Colors.white;
        if (selectedOptions[inputIndex] == '') {
          boxColor = Colors.red;
        } else if (showUserAnswers) {
          boxColor = selectedOptions[inputIndex] == options[answer[inputIndex]] ? Colors.green : Colors.red;
        }
        questionWidgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: boxColor,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              selectedOptions[inputIndex] ?? '____',
              style: GoogleFonts.vt323(fontSize: 24, color: Colors.black),
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
        if (!showOptions)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
              ],
            ),
          ),
        if (showOptions)
          Column(
            children: [
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: questionWidgets,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                children: options.asMap().entries.map((entry) {
                  int index = entry.key;
                  String option = entry.value;
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
                        option,
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