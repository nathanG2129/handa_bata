import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

class MatchingTypeQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final VoidCallback onOptionsShown; // Callback to notify when options are shown
  final VoidCallback onAnswerChecked; // Callback to notify when the answer is checked

  const MatchingTypeQuestion({
    super.key,
    required this.questionData,
    required this.onOptionsShown,
    required this.onAnswerChecked,
  });

  @override
  MatchingTypeQuestionState createState() => MatchingTypeQuestionState();
}

class MatchingTypeQuestionState extends State<MatchingTypeQuestion> {
  String? selectedSection1Option;
  String? selectedSection2Option;
  bool showOptions = false;
  List<String> section1Options = [];
  List<String> section2Options = [];
  List<Map<String, String>> userPairs = [];
  List<Color> pairColors = [];
  List<Color> usedColors = [];
  String questionText = '';
  List<Map<String, String>> correctAnswers = [];
  int correctPairCount = 0;
  int incorrectPairCount = 0;
  Timer? _timer; // Timer to handle the delay

  @override
  void initState() {
    super.initState();
    resetState();
  }

  @override
  void didUpdateWidget(covariant MatchingTypeQuestion oldWidget) {
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

  void resetState() {
    setState(() {
      selectedSection1Option = null;
      selectedSection2Option = null;
      showOptions = false;
      section1Options = [];
      section2Options = [];
      userPairs = [];
      pairColors = [];
      usedColors = [];
      questionText = '';
      correctAnswers = [];
      correctPairCount = 0;
      incorrectPairCount = 0;
      _initializeOptions();
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

  void _initializeOptions() {
    setState(() {
      section1Options = List<String>.from(widget.questionData['section1'] ?? []);
      section2Options = List<String>.from(widget.questionData['section2'] ?? []);
      correctAnswers = List<Map<String, String>>.from(
        widget.questionData['answerPairs']?.map((item) => {
          'section1': item['section1'] as String,
          'section2': item['section2'] as String,
        }) ?? [],
      );

      // Debug prints
      debugPrint('Section 1 Options: $section1Options');
      debugPrint('Section 2 Options: $section2Options');
      debugPrint('Correct Answers: $correctAnswers');

      userPairs = [];
      pairColors = [];
      usedColors = [];
      questionText = widget.questionData['question'] ?? 'No question available';
      correctPairCount = 0;
      incorrectPairCount = 0;
    });
  }

  void _handleSection1OptionTap(String option) {
    setState(() {
      if (selectedSection1Option == option) {
        selectedSection1Option = null;
        debugPrint('Deselected section1 option: $option');
      } else {
        selectedSection1Option = option;
        debugPrint('Selected section1 option: $option');
        if (selectedSection2Option != null) {
          _matchOptions();
        }
      }
    });
  }

  void _handleSection2OptionTap(String option) {
    setState(() {
      if (selectedSection2Option == option) {
        selectedSection2Option = null;
        debugPrint('Deselected section2 option: $option');
      } else {
        selectedSection2Option = option;
        debugPrint('Selected section2 option: $option');
        if (selectedSection1Option != null) {
          _matchOptions();
        }
      }
    });
  }

  void _matchOptions() {
    if (selectedSection1Option != null && selectedSection2Option != null) {
      setState(() {
        userPairs.add({
          'section1': selectedSection1Option!,
          'section2': selectedSection2Option!,
        });
        Color newColor = _generateUniqueColor();
        pairColors.add(newColor);
        usedColors.add(newColor);
        debugPrint('Matched Pair: Section 1 - $selectedSection1Option, Section 2 - $selectedSection2Option with color $newColor');
        selectedSection1Option = null;
        selectedSection2Option = null;

        // Check if all pairs are matched
        if (userPairs.length == section1Options.length) {
          _checkAnswer();
        }
      });
    }
  }

  void _cancelSelection(String section1Option, String section2Option) {
    setState(() {
      int index = userPairs.indexWhere((pair) =>
          pair['section1'] == section1Option && pair['section2'] == section2Option);
      if (index != -1) {
        usedColors.remove(pairColors[index]);
        userPairs.removeAt(index);
        pairColors.removeAt(index);
        debugPrint('Canceled Pair: Section 1 - $section1Option, Section 2 - $section2Option');
      }
    });
  }

  void _checkAnswer() {
    // Convert pairs to strings for comparison
    List<String> userPairStrings = userPairs.map((pair) => '${pair['section1']}:${pair['section2']}').toList();
    List<String> correctAnswerStrings = correctAnswers.map((pair) => '${pair['section1']}:${pair['section2']}').toList();

    // Sort the lists for comparison
    userPairStrings.sort();
    correctAnswerStrings.sort();

    debugPrint('User Pair Strings: $userPairStrings');
    debugPrint('Correct Answer Strings: $correctAnswerStrings');

    setState(() {
      correctPairCount = 0;
      incorrectPairCount = 0;

      for (int i = 0; i < userPairs.length; i++) {
        String userPairString = '${userPairs[i]['section1']}:${userPairs[i]['section2']}';
        if (correctAnswerStrings.contains(userPairString)) {
          pairColors[i] = Colors.green; // Correct pair
          correctPairCount++;
        } else {
          pairColors[i] = Colors.red; // Incorrect pair
          incorrectPairCount++;
        }
      }

      // Color unselected section2 buttons as red
      for (int i = userPairs.length; i < section1Options.length; i++) {
        userPairs.add({
          'section1': section1Options[i],
          'section2': '',
        });
        pairColors.add(Colors.red);
        incorrectPairCount++;
      }
    });

    // Notify that the answer has been checked
    widget.onAnswerChecked();
  }

  void forceCheckAnswer() {
    // Mark unselected pairs as wrong
    setState(() {
      // Mark unselected section1 options as wrong
      for (int i = userPairs.length; i < section1Options.length; i++) {
        userPairs.add({
          'section1': section1Options[i],
          'section2': '',
        });
        pairColors.add(Colors.red);
        incorrectPairCount++;
      }
    });

    // Show correct pairs in green
    _checkAnswer();
  }

  Color _generateUniqueColor() {
    final colors = [Colors.blue, Colors.yellow, Colors.pink, Colors.orange, Colors.purple];
    for (Color color in colors) {
      if (!usedColors.contains(color)) {
        return color;
      }
    }
    // If all colors are used, start reusing colors
    return colors[usedColors.length % colors.length];
  }

  Color? _getPairColor(String option, String section) {
    int index = userPairs.indexWhere((pair) => pair[section] == option);
    if (index != -1 && index < pairColors.length) {
      return pairColors[index];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!showOptions)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TextWithShadow(
                  text: 'Matching Type',
                  fontSize: 40, // Adjusted font size to 40
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    questionText,
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
                    questionText,
                    style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: section1Options.map((option) {
                        bool isSelected = selectedSection1Option == option;
                        bool isMatched = userPairs.any((pair) => pair['section1'] == option);
                        Color? pairColor = _getPairColor(option, 'section1');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SizedBox(
                            width: 150, // Set a fixed width
                            height: 75, // Set a fixed height
                            child: ElevatedButton(
                              onPressed: () {
                                if (isMatched) {
                                  _cancelSelection(option, userPairs.firstWhere((pair) => pair['section1'] == option)['section2']!);
                                } else {
                                  _handleSection1OptionTap(option);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: isSelected || isMatched ? Colors.white : Colors.black,
                                backgroundColor: isSelected ? Colors.grey : isMatched ? pairColor ?? Colors.white : Colors.white,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  option,
                                  softWrap: true,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.rubik(fontSize: 18, color: isSelected || isMatched ? Colors.white : Colors.black),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: section2Options.map((option) {
                        bool isSelected = selectedSection2Option == option;
                        bool isMatched = userPairs.any((pair) => pair['section2'] == option);
                        Color? pairColor = _getPairColor(option, 'section2');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SizedBox(
                            width: 150, // Set a fixed width
                            height: 75, // Set a fixed height
                            child: ElevatedButton(
                              onPressed: () {
                                if (isMatched) {
                                  _cancelSelection(userPairs.firstWhere((pair) => pair['section2'] == option)['section1']!, option);
                                } else {
                                  _handleSection2OptionTap(option);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: isSelected || isMatched ? Colors.white : Colors.black,
                                backgroundColor: isSelected ? Colors.grey : isMatched ? pairColor ?? Colors.white : Colors.white,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  option,
                                  softWrap: true,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.rubik(fontSize: 18, color: isSelected || isMatched ? Colors.white : Colors.black),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Correct Pairs: $correctPairCount, Incorrect Pairs: $incorrectPairCount',
                  style: GoogleFonts.rubik(fontSize: 24, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
      ],
    );
  }
}