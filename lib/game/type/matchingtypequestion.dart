import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';

class MatchingTypeQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final VoidCallback onOptionsShown; // Callback to notify when options are shown

  const MatchingTypeQuestion({
    super.key,
    required this.questionData,
    required this.onOptionsShown,
  });

  @override
  _MatchingTypeQuestionState createState() => _MatchingTypeQuestionState();
}

class _MatchingTypeQuestionState extends State<MatchingTypeQuestion> {
  String? selectedSection1Option;
  String? selectedSection2Option;
  bool showOptions = false;
  List<String> section1Options = [];
  List<String> section2Options = [];
  List<Map<String, String>> answerPairs = [];
  List<Color> pairColors = [];
  String questionText = '';

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        showOptions = true;
        widget.onOptionsShown(); // Notify that options are shown
      });
    });
  }

  void _initializeOptions() {
    setState(() {
      section1Options = List<String>.from(widget.questionData['section1'] ?? []);
      section2Options = List<String>.from(widget.questionData['section2'] ?? []);
      answerPairs = List<Map<String, String>>.from(
        widget.questionData['answerPairs']?.map((item) => {
          'section1': item['section1'] as String,
          'section2': item['section2'] as String,
        }) ?? [],
      );
      questionText = widget.questionData['question'] ?? 'No question available';
    });
    debugPrint('Section 1 Options: $section1Options');
    debugPrint('Section 2 Options: $section2Options');
    debugPrint('Answer Pairs: $answerPairs');
    debugPrint('Question Text: $questionText');
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
      answerPairs.add({
        'section1': selectedSection1Option!,
        'section2': selectedSection2Option!,
      });
      pairColors.add(_generateColor(answerPairs.length - 1));
      debugPrint('Matched Pair: Section 1 - $selectedSection1Option, Section 2 - $selectedSection2Option');
      selectedSection1Option = null;
      selectedSection2Option = null;
    }
  }

  void _cancelSelection(String section1Option, String section2Option) {
    setState(() {
      int index = answerPairs.indexWhere((pair) =>
          pair['section1'] == section1Option && pair['section2'] == section2Option);
      if (index != -1) {
        answerPairs.removeAt(index);
        pairColors.removeAt(index);
      }
    });
  }

  Color _generateColor(int index) {
    // Generate a color based on the index
    final colors = [Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.purple];
    return colors[index % colors.length];
  }

  Color? _getPairColor(String option, String section) {
    int index = answerPairs.indexWhere((pair) => pair[section] == option);
    if (index != -1 && index < pairColors.length) {
      return pairColors[index];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            if (!showOptions)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const TextWithShadow(
                      text: 'Matching Type',
                      fontSize: 48, // Increased font size
                    ),
                    const SizedBox(height: 16),
                    Text(
                      questionText,
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
                      questionText,
                      style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: section1Options.map((option) {
                            bool isSelected = selectedSection1Option == option;
                            bool isMatched = answerPairs.any((pair) => pair['section1'] == option);
                            Color? pairColor = _getPairColor(option, 'section1');
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (isMatched) {
                                    _cancelSelection(option, answerPairs.firstWhere((pair) => pair['section1'] == option)['section2']!);
                                  } else {
                                    _handleSection1OptionTap(option);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: isSelected || isMatched ? Colors.white : Colors.black,
                                  backgroundColor: isSelected || isMatched ? pairColor ?? Colors.blue : Colors.white,
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: Colors.black, width: 2),
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: GoogleFonts.rubik(fontSize: 18, color: isSelected || isMatched ? Colors.white : Colors.black),
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
                            bool isMatched = answerPairs.any((pair) => pair['section2'] == option);
                            Color? pairColor = _getPairColor(option, 'section2');
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (isMatched) {
                                    _cancelSelection(answerPairs.firstWhere((pair) => pair['section2'] == option)['section1']!, option);
                                  } else {
                                    _handleSection2OptionTap(option);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: isSelected || isMatched ? Colors.white : Colors.black,
                                  backgroundColor: isSelected || isMatched ? pairColor ?? Colors.blue : Colors.white,
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(color: Colors.black, width: 2),
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: GoogleFonts.rubik(fontSize: 18, color: isSelected || isMatched ? Colors.white : Colors.black),
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
        ),
      ),
    );
  }
}