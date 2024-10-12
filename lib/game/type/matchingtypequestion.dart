import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

class MatchingTypeQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final VoidCallback onOptionsShown; // Callback to notify when options are shown
  final VoidCallback onAnswerChecked; // Callback to notify when the answer is checked
  final VoidCallback onVisualDisplayComplete; // Callback to notify when visual display is complete

  const MatchingTypeQuestion({
    super.key,
    required this.questionData,
    required this.onOptionsShown,
    required this.onAnswerChecked,
    required this.onVisualDisplayComplete, // Add this line
  });

  @override
  MatchingTypeQuestionState createState() => MatchingTypeQuestionState();
}

class MatchingTypeQuestionState extends State<MatchingTypeQuestion> {
  List<String> section1Options = [];
  List<String> section2Options = [];
  List<Map<String, String>> userPairs = [];
  List<Map<String, String>> correctAnswers = [];
  List<Color> pairColors = [];
  List<Color> usedColors = [];
  String? selectedSection1Option;
  String? selectedSection2Option;
  bool showOptions = false;
  String questionText = '';
  int correctPairCount = 0;
  int incorrectPairCount = 0;
  Timer? _timer;
  bool isChecking = false; // Add this flag
  bool isSubmitted = false; // Add this flag
  
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
      isChecking = false; // Reset the flag
      isSubmitted = false; // Reset the flag
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
      } else {
        selectedSection1Option = option;
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
      } else {
        selectedSection2Option = option;
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
  
        // Remove the matched options from the lists
        section1Options.remove(selectedSection1Option);
        section2Options.remove(selectedSection2Option);
  
        selectedSection1Option = null;
        selectedSection2Option = null;
  
        // Check if all pairs are matched
        if (userPairs.length == correctAnswers.length) {
          _submitPairs();
        }
      });
    }
  }

  void _cancelSelection(String section1Option, String section2Option) {
    if (isChecking) return; // Prevent unpairing during the checking phase
  
    setState(() {
      int index = userPairs.indexWhere((pair) =>
          pair['section1'] == section1Option && pair['section2'] == section2Option);
      if (index != -1) {
        usedColors.remove(pairColors[index]);
        userPairs.removeAt(index);
        pairColors.removeAt(index);
  
        // Add the options back to their respective sections
        section1Options.add(section1Option);
        section2Options.add(section2Option);
      }
    });
  }

    void _submitPairs() {
    setState(() {
      isSubmitted = true; // Set the flag to true
    });
    _checkAnswer();
  }

  Widget _buildPairRow(Map<String, String> pair, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 75,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      pair['section1']!,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 150,
                height: 75,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(0),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      pair['section2']!,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: isChecking,
              child: TextButton(
                onPressed: () {
                  _cancelSelection(pair['section1']!, pair['section2']!);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.transparent, backgroundColor: Colors.transparent,
                ),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkAnswerImmediately() {
    setState(() {
      isChecking = true; // Set the flag to true
    });
  
    // Convert pairs to strings for comparison
    List<String> userPairStrings = userPairs.map((pair) => '${pair['section1']}:${pair['section2']}').toList();
    List<String> correctAnswerStrings = correctAnswers.map((pair) => '${pair['section1']}:${pair['section2']}').toList();
  
    // Sort the lists for comparison
    userPairStrings.sort();
    correctAnswerStrings.sort();
  
    setState(() {
      correctPairCount = 0;
      incorrectPairCount = 0;
    });
  
    for (int i = 0; i < userPairs.length; i++) {
      String userPairString = '${userPairs[i]['section1']}:${userPairs[i]['section2']}';
      if (correctAnswerStrings.contains(userPairString) && pairColors[i] != Colors.red) {
        correctPairCount++;
      } else {
        incorrectPairCount++;
      }
    }
  
    // Mark unselected section2 buttons as incorrect
    for (int i = userPairs.length; i < correctAnswers.length; i++) {
      incorrectPairCount++;
    }
  
    // Notify that the answer has been checked
    widget.onAnswerChecked();
  
    setState(() {
      isChecking = false; // Set the flag to false
    });
  }
  
  void _showAnswerVisually() async {
    setState(() {
      isChecking = true; // Set the flag to true
    });
  
    for (int i = 0; i < userPairs.length; i++) {
      await Future.delayed(const Duration(seconds: 1, milliseconds: 750)); // Introduce a delay of 1 second
  
      setState(() {
        String userPairString = '${userPairs[i]['section1']}:${userPairs[i]['section2']}';
        if (correctAnswers.any((pair) => '${pair['section1']}:${pair['section2']}' == userPairString) && pairColors[i] != Colors.red) {
          pairColors[i] = Colors.green; // Correct pair
        } else {
          pairColors[i] = Colors.red; // Incorrect pair
        }
      });
    }
  
    // Color unselected section2 buttons as red
    for (int i = userPairs.length; i < correctAnswers.length; i++) {
      await Future.delayed(const Duration(seconds: 1)); // Introduce a delay of 1 second
  
      setState(() {
        userPairs.add({
          'section1': section1Options[i],
          'section2': '',
        });
        pairColors.add(Colors.red);
      });
    }
  
    // Notify that the visual display is complete
    widget.onVisualDisplayComplete();
  }
  
  void _checkAnswer() {
    _checkAnswerImmediately(); // Perform the immediate background check
    _showAnswerVisually(); // Show the correctness of the pairs visually
  }
  
  void forceCheckAnswer() {
    setState(() {
      isChecking = true; // Set the flag to true
  
      // Randomly pair up the remaining options
      List<String> remainingSection1Options = List.from(section1Options);
      List<String> remainingSection2Options = List.from(section2Options);
      Random random = Random();
  
      // Shuffle section2Options to ensure incorrect pairings
      remainingSection2Options.shuffle(random);
  
      while (remainingSection1Options.isNotEmpty && remainingSection2Options.isNotEmpty) {
        String section1Option = remainingSection1Options.removeAt(0);
        String section2Option = remainingSection2Options.removeAt(0);
        userPairs.add({
          'section1': section1Option,
          'section2': section2Option,
        });
        pairColors.add(Colors.red);
        incorrectPairCount++;
  
        // Remove the paired options from the original lists
        section1Options.remove(section1Option);
        section2Options.remove(section2Option);
      }
  
      // If there are any remaining options in section1 or section2, mark them as wrong
      for (String section1Option in remainingSection1Options) {
        userPairs.add({
          'section1': section1Option,
          'section2': '',
        });
        pairColors.add(Colors.red);
        incorrectPairCount++;
  
        // Remove the option from the original list
        section1Options.remove(section1Option);
      }
  
      for (String section2Option in remainingSection2Options) {
        userPairs.add({
          'section1': '',
          'section2': section2Option,
        });
        pairColors.add(Colors.red);
        incorrectPairCount++;
  
        // Remove the option from the original list
        section2Options.remove(section2Option);
      }
    });
  
    // Show correct pairs in green
    _checkAnswer();
  
  }

  bool areAllPairsCorrect() {
    return correctPairCount == correctAnswers.length;
  }

  Color _generateUniqueColor() {
    final colors = [
      const Color(0xFFC32929), // #c32929
      const Color(0xFFE18128), // #e18128
      const Color(0xFF2C28E1), // #2c28e1
      const Color(0xFFF1B33A), // #f1b33a
      const Color(0xFF1B198F), // #1b198f
    ];
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
              Column(
                children: userPairs.map((pair) {
                  int index = userPairs.indexOf(pair);
                  return _buildPairRow(pair, pairColors[index]);
                }).toList(),
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
                                  borderRadius: BorderRadius.circular(0),
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
                                  borderRadius: BorderRadius.circular(0),
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
            ],
          ),
      ],
    );
  }
}