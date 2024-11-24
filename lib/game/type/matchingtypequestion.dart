import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:soundpool/soundpool.dart';
import 'package:responsive_builder/responsive_builder.dart';

class MatchingTypeQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final VoidCallback onOptionsShown; // Callback to notify when options are shown
  final VoidCallback onAnswerChecked; // Callback to notify when the answer is checked
  final VoidCallback onVisualDisplayComplete; // Callback to notify when visual display is complete
  final double sfxVolume; // Add this line
  final String gamemode; // Add this line
  final Function(bool, String, {int blankPairs, String difficulty}) updateHealth; // Add this line
  final Function(int) updateStopwatch; // Add this line
  final int currentQuestionIndex; // Add this line

  const MatchingTypeQuestion({
    super.key,
    required this.questionData,
    required this.onOptionsShown,
    required this.onAnswerChecked,
    required this.onVisualDisplayComplete, 
    required this.sfxVolume, 
    required this.gamemode, 
    required this.updateHealth, 
    required this.updateStopwatch, 
    required this.currentQuestionIndex, // Add this line
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
  late Soundpool _soundpool;
  late int _soundId1, _soundId2, _soundId3;
  bool _soundsLoaded = false;
  bool showCorrectAnswer = false;

  @override
  void initState() {
    super.initState();
    _initializeSounds();
    resetState();
  }

  void _initializeSounds() async {
  _soundpool = Soundpool.fromOptions(options: const SoundpoolOptions(streamType: StreamType.music));
  _soundId1 = await _soundpool.load(await rootBundle.load('assets/sound/ingame/zapsplat_multimedia_game_retro_musical_negative_001.mp3'));
  _soundId2 = await _soundpool.load(await rootBundle.load('assets/sound/ingame/zapsplat_multimedia_game_retro_musical_positive.mp3'));
  _soundId3 = await _soundpool.load(await rootBundle.load('assets/sound/ingame/zapsplat_multimedia_game_retro_musical_short_tone_001.mp3'));
  setState(() {
    _soundsLoaded = true;
  });
}

  void _playSound(int soundId) async {
    if (_soundsLoaded && soundId != -1) {
      await _soundpool.setVolume(soundId: soundId, volume: widget.sfxVolume); // Use the passed SFX volume
      await _soundpool.play(soundId);
    }
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
      if (widget.gamemode == 'arcade') {
        showOptions = true;
        widget.onOptionsShown(); // Notify that options are shown
      } else {
        _timer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              showOptions = true;
              widget.onOptionsShown(); // Notify that options are shown
            });
          }
        });
      }
      showCorrectAnswer = false;
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

      // Shuffle the options
      section1Options.shuffle(Random());
      section2Options.shuffle(Random());

      userPairs = [];
      pairColors = [];
      usedColors = [];
      questionText = widget.questionData['question'] ?? 'No question available';
      correctPairCount = 0;
      incorrectPairCount = 0;
    });
  }
  
  void _handleSection1OptionTap(String option) {
    _playSound(_soundId3); // Play select answer sound
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
    _playSound(_soundId3); // Play select answer sound
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
  
        // Check if we've reached the number of correct pairs
        if (userPairs.length == correctAnswers.length) {
          // Simply clear remaining options instead of adding them as empty pairs
          section1Options.clear();
          section2Options.clear();
          _submitPairs();
        }
      });
    }
  }

  void _cancelSelection(String section1Option, String section2Option) {
    if (isChecking) return;
    _playSound(_soundId3);

    setState(() {
      int index = userPairs.indexWhere((pair) =>
          pair['section1'] == section1Option && pair['section2'] == section2Option);
      
      if (index != -1) {
        // Remove the color from used colors
        if (index < pairColors.length) {
          Color colorToRemove = pairColors[index];
          usedColors.remove(colorToRemove);
        }
        
        // Remove the pair and its color
        userPairs.removeAt(index);
        if (index < pairColors.length) {
          pairColors.removeAt(index);
        }

        // Add the options back to their respective sections in the correct order
        section1Options.add(section1Option);
        section2Options.add(section2Option);
        
        // Reset selection states
        selectedSection1Option = null;
        selectedSection2Option = null;
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
              Stack(
                children: [
                  Container(
                    width: 150,
                    constraints: const BoxConstraints(minHeight: 75),
                    decoration: BoxDecoration(
                      color: pair['section1']!.isEmpty ? Colors.transparent : Colors.white,
                      borderRadius: BorderRadius.circular(0),
                      border: pair['section1']!.isEmpty ? null : Border.all(color: Colors.black, width: 2),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 8, 16),
                    child: Center(
                      child: Text(
                        pair['section1']!,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rubik(
                          fontSize: 18,
                          height: 1.2,
                          color: pair['section1']!.isEmpty ? Colors.transparent : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 2,
                    top: 2,
                    bottom: 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      width: 16,
                      decoration: BoxDecoration(
                        color: pair['section1']!.isEmpty ? Colors.transparent : color,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 150,
                constraints: const BoxConstraints(minHeight: 75),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500), // Set the duration for the fade-in effect
                  curve: Curves.easeInOut, // Use a smooth curve for the transition
                  decoration: BoxDecoration(
                    color: pair['section2']!.isEmpty ? Colors.grey : color,
                    borderRadius: BorderRadius.circular(0),
                    border: pair['section2']!.isEmpty ? null : Border.all(color: Colors.black, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Center(
                    child: Text(
                      pair['section2']!,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        height: 1.2,
                        color: pair['section2']!.isEmpty ? Colors.transparent : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (pair['section1']!.isNotEmpty && pair['section2']!.isNotEmpty && !isChecking)
            Positioned.fill(
              child: TextButton(
                onPressed: () {
                  _cancelSelection(pair['section1']!, pair['section2']!);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
                ),
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }

  void _recordAnsweredQuestion(bool isCorrect) {
  (context.findAncestorStateOfType<GameplayPageState>())?.answeredQuestions.add({
    'type': 'Matching Type',
    'question': widget.questionData['question'],
    'correctPairs': correctAnswers,
    'isCorrect': isCorrect,
  });
}

  void _checkAnswerImmediately() {
    setState(() {
      isChecking = true;
    });

    if (widget.gamemode == 'arcade') {
      (context.findAncestorStateOfType<GameplayPageState>())?.pauseStopwatch();
    }

    (context.findAncestorStateOfType<GameplayPageState>())?.stopTts();

    // Only check up to the number of correct pairs
    correctPairCount = 0;
    incorrectPairCount = 0;

    List<String> correctAnswerStrings = correctAnswers.map((pair) => '${pair['section1']}:${pair['section2']}').toList();
    
    // Only check pairs up to the number of correct answers
    for (int i = 0; i < correctAnswers.length && i < userPairs.length; i++) {
      String userPairString = '${userPairs[i]['section1']}:${userPairs[i]['section2']}';
      if (correctAnswerStrings.contains(userPairString) && pairColors[i] != Colors.red) {
        correctPairCount++;
      } else {
        incorrectPairCount++;
      }
    }

    widget.onAnswerChecked();

    setState(() {
      isChecking = false;
    });
  }
  
  void _showAnswerVisually() async {
    setState(() {
      isChecking = true;
    });

    int totalPairs = correctPairCount;
    int completedUpdates = 0;

    // Only check pairs that don't have empty sections
    for (int i = 0; i < userPairs.length; i++) {
      if (userPairs[i]['section1']!.isEmpty || userPairs[i]['section2']!.isEmpty) {
        continue; // Skip visual check for pairs with empty sections
      }

      await Future.delayed(const Duration(seconds: 1, milliseconds: 750));
  
      setState(() {
        // If the pair was force-paired (had grey color), always mark it as incorrect
        if (pairColors[i] == Colors.grey) {
          pairColors[i] = Colors.red;
          _playSound(_soundId1);
          widget.updateHealth(false, 'Matching Type', blankPairs: 1);
          if (widget.gamemode == 'arcade') {
            widget.updateStopwatch(5);
          }
        } else {
          // Only check correctness for user-made pairs
          String userPairString = '${userPairs[i]['section1']}:${userPairs[i]['section2']}';
          if (correctAnswers.any((pair) => '${pair['section1']}:${pair['section2']}' == userPairString)) {
            pairColors[i] = Colors.green;
            _playSound(_soundId2);
            widget.updateHealth(true, 'Matching Type');
            if (widget.gamemode == 'arcade') {
              widget.updateStopwatch(-5);
            }
          } else {
            pairColors[i] = Colors.red;
            _playSound(_soundId1);
            widget.updateHealth(false, 'Matching Type', blankPairs: 1);
            if (widget.gamemode == 'arcade') {
              widget.updateStopwatch(5);
            }
          }
        }
        completedUpdates++;
      });
    }

    // Only save after all HP updates are complete
    if (completedUpdates == totalPairs) {
      final gameplayState = context.findAncestorStateOfType<GameplayPageState>();
      if (gameplayState != null) {
        gameplayState.saveStateQuestionIndex = widget.currentQuestionIndex + 1;
        gameplayState.autoSaveGame();
      }
    }

    // Record answer AFTER saving state
    _recordAnsweredQuestion(correctPairCount == correctAnswers.length);

        // Add delay then show correct answers
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      showCorrectAnswer = true;
      userPairs = List.from(correctAnswers);
      pairColors = List.filled(correctAnswers.length, Colors.green);
    });
  
    widget.onVisualDisplayComplete();

  }
  
  void _checkAnswer() {
    _checkAnswerImmediately(); // Perform the immediate background check
    _showAnswerVisually(); // Show the correctness of the pairs visually
  }
  
  void forceCheckAnswer() {
    setState(() {
      isChecking = true;
      (context.findAncestorStateOfType<GameplayPageState>())?.stopTts();

      if (widget.gamemode == 'arcade') {
        (context.findAncestorStateOfType<GameplayPageState>())?.pauseStopwatch();
      }

      // Create deliberately wrong pairs for remaining options
      while (userPairs.length < correctAnswers.length && section1Options.isNotEmpty && section2Options.isNotEmpty) {
        String section1Option = section1Options.removeAt(0);
        
        // Find a section2 option that doesn't form a correct pair with section1Option
        String section2Option = section2Options.firstWhere(
          (option) => !correctAnswers.any((pair) => 
            pair['section1'] == section1Option && pair['section2'] == option
          ),
          orElse: () => section2Options[0], // If no wrong match found, just take the first one
        );
        section2Options.remove(section2Option);
        
        userPairs.add({
          'section1': section1Option,
          'section2': section2Option,
        });
        // Use a neutral color for force-paired options
        pairColors.add(Colors.grey);
      }

      // Clear remaining options
      section1Options.clear();
      section2Options.clear();
    });

    // These pairs will be checked normally in _checkAnswer
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

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Calculate dynamic widths based on screen size
        final containerWidth = isTablet 
            ? 200.0 
            : (screenWidth - (screenWidth * 0.3)) / 2;
        
        // Calculate consistent padding for both selected and unselected pairs
        final horizontalPadding = isTablet 
            ? const EdgeInsets.symmetric(horizontal: 200.0)  // Tablet padding
            : const EdgeInsets.symmetric(horizontal: 16.0);  // Phone padding

        return Column(
          children: [
            if (!showOptions)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextWithShadow(
                      text: 'Matching Type',
                      fontSize: isTablet ? 36 : 28,
                    ),
                    SizedBox(height: isTablet ? 24 : 16),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12.0 : 4.0
                      ),
                      child: Text(
                        questionText,
                        style: GoogleFonts.rubik(
                          fontSize: isTablet ? 28 : 20,
                          color: Colors.white
                        ),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12.0 : 4.0
                      ),
                      child: Text(
                        questionText,
                        style: GoogleFonts.rubik(
                          fontSize: isTablet ? 28 : 20,
                          color: Colors.white
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                  // Matched Pairs Section with consistent padding
                  Padding(
                    padding: horizontalPadding,
                    child: Column(
                    children: userPairs.map((pair) {
                      int index = userPairs.indexOf(pair);
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 12.0 : 8.0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (!isChecking) {
                              _cancelSelection(pair['section1']!, pair['section2']!);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Left option (section1)
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        minHeight: isTablet ? 90 : 60
                                      ),
                                      decoration: BoxDecoration(
                                        color: pair['section1']!.isEmpty ? Colors.transparent : Colors.white,
                                        border: pair['section1']!.isEmpty ? null : Border.all(color: Colors.black, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          pair['section1']!,
                                          softWrap: true,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.rubik(
                                            fontSize: isTablet ? 22 : 16,
                                            color: pair['section1']!.isEmpty ? Colors.transparent : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 2,
                                      top: 2,
                                      bottom: 2,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeInOut,
                                        width: isTablet ? 20 : 16,
                                        decoration: BoxDecoration(
                                          color: pair['section1']!.isEmpty ? Colors.transparent : pairColors[index],
                                          borderRadius: BorderRadius.zero,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                                SizedBox(width: isTablet ? 24 : 8),
                              // Right option (section2)
                              Expanded(
                                child: Container(
                                  constraints: BoxConstraints(
                                    minHeight: isTablet ? 90 : 60
                                  ),
                                    decoration: BoxDecoration(
                                      color: pair['section2']!.isEmpty ? Colors.grey : pairColors[index],
                                    border: Border.all(color: Colors.black, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        pair['section2']!,
                                        softWrap: true,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.rubik(
                                          fontSize: isTablet ? 22 : 16,
                                        color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                  // Unmatched Options Section with same padding
                  Padding(
                    padding: horizontalPadding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Left column (section1 options)
                      Expanded(
                        child: Column(
                          children: section1Options.map((option) {
                            bool isSelected = selectedSection1Option == option;
                            bool isMatched = userPairs.any((pair) => pair['section1'] == option);
                            Color? pairColor = _getPairColor(option, 'section1');
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 12.0 : 8.0,
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width: containerWidth,
                                    constraints: BoxConstraints(
                                      minHeight: isTablet ? 90 : 60
                                    ),
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
                                        backgroundColor: isSelected ? Colors.grey : isMatched ? Colors.white : Colors.white,
                                        padding: EdgeInsets.fromLTRB(
                                          isTablet ? 32 : 24,
                                          isTablet ? 20 : 12,
                                          isTablet ? 12 : 8,
                                          isTablet ? 20 : 12
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(0),
                                          side: const BorderSide(color: Colors.black, width: 2),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          option,
                                          style: GoogleFonts.rubik(
                                            fontSize: isTablet ? 22 : 16,
                                            height: 1.2,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 1,
                                    top: 1,
                                    bottom: 1,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeInOut,
                                      width: isTablet ? 20 : 16,
                                      decoration: BoxDecoration(
                                        color: isMatched ? pairColor ?? const Color(0xFF241242) : const Color(0xFF241242),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(width: isTablet ? 24 : 8),
                        // Right column (section2 options)
                      Expanded(
                        child: Column(
                          children: section2Options.map((option) {
                            bool isSelected = selectedSection2Option == option;
                            bool isMatched = userPairs.any((pair) => pair['section2'] == option);
                            Color? pairColor = _getPairColor(option, 'section2');
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isTablet ? 12.0 : 8.0,
                              ),
                              child: Container(
                                width: containerWidth,
                                constraints: BoxConstraints(
                                  minHeight: isTablet ? 90 : 60
                                ),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 12 : 8,
                                      vertical: isTablet ? 20 : 12
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                      side: const BorderSide(color: Colors.black, width: 2),
                                    ),
                                  ),
                                  child: Text(
                                    option,
                                    softWrap: true,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.rubik(
                                      fontSize: isTablet ? 22 : 16,
                                      height: 1.2,
                                      color: isSelected || isMatched ? Colors.white : Colors.black,
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
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
