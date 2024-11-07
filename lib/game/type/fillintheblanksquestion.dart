import 'dart:async';
import 'dart:math'; // Import the dart:math library for shuffling
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:soundpool/soundpool.dart';

class FillInTheBlanksQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final TextEditingController controller;
  final bool isCorrect;
  final Function(Map<String, dynamic>) onAnswerSubmitted; // Change the type here
  final VoidCallback onOptionsShown; // Add the callback to start the timer
  final VoidCallback nextQuestion; // Add the nextQuestion callback
  final VoidCallback onVisualDisplayComplete; // Add this callback
  final double sfxVolume; // Add this line
  final String gamemode; // Add this line
  final Function(bool, String, {int blankPairs, String difficulty}) updateHealth; // Add this line
  final Function(int) updateStopwatch; // Add this line

  const FillInTheBlanksQuestion({
    super.key,
    required this.questionData,
    required this.controller,
    required this.isCorrect,
    required this.onAnswerSubmitted,
    required this.onOptionsShown,
    required this.nextQuestion,
    required this.onVisualDisplayComplete, // Add this callback
    required this.sfxVolume, 
    required this.gamemode, 
    required this.updateHealth, // Add this line
    required this.updateStopwatch, // Add this line
  });

  @override
  FillInTheBlanksQuestionState createState() => FillInTheBlanksQuestionState();
}

class FillInTheBlanksQuestionState extends State<FillInTheBlanksQuestion> {
  List<String?> selectedOptions = [];
  List<bool> optionSelected = [];
  List<bool?> correctness = []; // Add this list to track correctness
  bool showOptions = false;
  bool showUserAnswers = false;
  bool showAllRed = false;
  bool isAnswerCorrect = false;
  bool isChecking = false; // Add this flag
  bool _isVisualDisplayComplete = false; // Add this flag
  Timer? _timer;
  List<String> options = []; // Store shuffled options
  List<String> correctOptions = []; // Store correct options based on the string value
  late Soundpool _soundpool;
  late int _soundId1, _soundId2, _soundId3;
  bool _soundsLoaded = false;
  List<int?> optionPositions = []; // Stores the blank position (1-based) for each option

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    _initializeSounds();
    _showIntroduction();
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
      correctness = List<bool?>.filled(widget.questionData['answer'].length, null); // Initialize correctness list
      options = List<String>.from(widget.questionData['options']);
      options.shuffle(Random()); // Shuffle the options

      // Get the correct options based on the string value
      correctOptions = widget.questionData['answer']
          .map<String>((index) => widget.questionData['options'][index as int] as String)
          .toList();
      optionPositions = List<int?>.filled(widget.questionData['options'].length, null);
    });
  }

  void _showIntroduction() {
    setState(() {
      showOptions = false;
    });
    if (widget.gamemode == 'arcade') {
      setState(() {
        showOptions = true;
      });
      widget.onOptionsShown(); // Call the callback to start the timer
    } else {
      _timer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            showOptions = true;
          });
          widget.onOptionsShown(); // Call the callback to start the timer
        }
      });
    }
  }

  void _handleOptionSelection(int index, String option) {
    _playSound(_soundId3); // Play select answer sound
    setState(() {
      if (index < 0 || index >= optionSelected.length) {
        return;
      }

      if (optionSelected[index]) {
        // Deselect the option
        int selectedIndex = selectedOptions.indexOf(option);
        if (selectedIndex != -1) {
          selectedOptions[selectedIndex] = null;
          optionPositions[index] = null; // Clear the position
        }
        optionSelected[index] = false;
      } else {
        // Select the option
        int emptyIndex = selectedOptions.indexOf(null);
        if (emptyIndex != -1) {
          selectedOptions[emptyIndex] = option;
          optionSelected[index] = true;
          optionPositions[index] = emptyIndex + 1; // Store 1-based position
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

  (context.findAncestorStateOfType<GameplayPageState>())?.stopTts();

  // Pause the stopwatch
  if (widget.gamemode == 'arcade') {
    (context.findAncestorStateOfType<GameplayPageState>())?.pauseStopwatch();
  }

  // Perform the immediate background check
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
    'question': widget.questionData['question'],
    'correctAnswer': correctAnswer,
    'answer': userAnswer,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'isFullyCorrect': isFullyCorrect, // Add this to the answer data
    'isCorrect': isFullyCorrect,
  });

  // Show the correctness of the blanks visually
  _showAnswerVisually();
}

void _showAnswerVisually() async {
  for (int i = 0; i < selectedOptions.length; i++) {
    await Future.delayed(const Duration(seconds: 1, milliseconds: 750)); // Introduce a delay of 1.75 seconds

    setState(() {
      if (selectedOptions[i] == correctOptions[i]) {
        _playSound(_soundId2); // Play correct answer sound
        correctness[i] = true; // Mark as correct
        widget.updateHealth(true, 'Fill in the Blanks'); // Add HP for correct answer
        if (widget.gamemode == 'arcade') {
          widget.updateStopwatch(-5); // Deduct 5 seconds for correct answer
        }
      } else {
        _playSound(_soundId1); // Play wrong answer sound
        correctness[i] = false; // Mark as incorrect
        widget.updateHealth(false, 'Fill in the Blanks', blankPairs: 1); // Subtract HP for incorrect answer
        if (widget.gamemode == 'arcade') {
          widget.updateStopwatch(5); // Add 5 seconds for incorrect answer
        }
      }
    });
  }

  // Show the correct answers after a delay
  Future.delayed(const Duration(seconds: 1, milliseconds: 750), () {
    setState(() {
      selectedOptions = correctOptions;
      showOptions = false;
      // Mark all options as correct
      correctness = List<bool?>.filled(correctOptions.length, true);
      _isVisualDisplayComplete = true; // Set the flag to true
    });
  });

  // Transition to the next question after showing the correct answers
  Future.delayed(const Duration(seconds: 3), () {
    widget.onVisualDisplayComplete();
  });
}
 
  void forceCheckAnswer() {
    if (isChecking) return; // Prevent multiple calls to forceCheckAnswer
  
    setState(() {
      isChecking = true; // Set the flag to true when checking starts
    });
  
    (context.findAncestorStateOfType<GameplayPageState>())?.stopTts();
  
    // Pause the stopwatch
    if (widget.gamemode == 'arcade') {
      (context.findAncestorStateOfType<GameplayPageState>())?.pauseStopwatch();
    }
  
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
      'question': widget.questionData['question'],
      'correctAnswer': correctAnswer,
      'answer': userAnswer,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'isFullyCorrect': isFullyCorrect, // Add this to the answer data
      'isCorrect': isFullyCorrect,
    });
  
    // Show the correctness of the blanks visually
    _showAnswerVisually();
  }
 
  // Add a method to reset the state
  void resetState() {
    setState(() {
      showOptions = false;
      showUserAnswers = false;
      showAllRed = false;
      isChecking = false; // Reset the flag
      _isVisualDisplayComplete = false; // Reset the flag
      selectedOptions = List<String?>.filled(widget.questionData['answer'].length, null);
      optionSelected = List<bool>.filled(widget.questionData['options'].length, false);
      correctness = List<bool?>.filled(widget.questionData['answer'].length, null); // Reset correctness list
      isAnswerCorrect = false;
      options = List<String>.from(widget.questionData['options']);
      options.shuffle(Random()); // Shuffle the options
  
      // Get the correct options based on the string value
      correctOptions = widget.questionData['answer']
          .map<String>((index) => widget.questionData['options'][index as int] as String)
          .toList();
  
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
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    String questionText = widget.questionData['question'];
  
    List<Widget> questionWidgets = [];
    int inputIndex = 0;
  
    questionText.split(' ').forEach((word) {
      if (word.startsWith('<input>')) {
        String suffix = word.substring(7); // Get the suffix after <input>
        Color boxColor = selectedOptions[inputIndex] == null ? const Color(0xFF241242) : Colors.white; // Always white border
        Color textColor = Colors.white; // Default text color
        
        if (correctness[inputIndex] != null) {
          if (_isVisualDisplayComplete) {
            boxColor = Colors.green;
            textColor = Colors.white;
          } else {
            boxColor = correctness[inputIndex]! ? Colors.green : Colors.red;
            textColor = Colors.white;
          }
        } else if (selectedOptions[inputIndex] != null) {
          textColor = Colors.black; // Black text for selected options
        }

        questionWidgets.add(
          AnimatedContainer(
            duration: const Duration(milliseconds: 500), // Set the duration for the fade-in effect
            curve: Curves.easeInOut, // Use a smooth curve for the transition
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: boxColor,
              border: Border.all(
                color: Colors.white, // Always white border
                width: 2, // Make border more visible
              ),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Text(
              selectedOptions[inputIndex] ?? '____',
              style: (selectedOptions[inputIndex] == null)
                ? GoogleFonts.vt323(fontSize: 24, color: Colors.white)
                : GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        );
        if (suffix.isNotEmpty) {
          questionWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                suffix,
                style: GoogleFonts.rubik(fontSize: 25, color: Colors.white), // Make suffix white
              ),
            ),
          );
        }
        inputIndex++;
      } else {
        questionWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              word,
              style: GoogleFonts.rubik(
                fontSize: 25,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    });
  
    return Column(
      children: [
        if (!showOptions && !showUserAnswers && !_isVisualDisplayComplete)
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true, // Allow the grid to take only the space it needs
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                mainAxisExtent: 75, // Set initial height, will expand if needed
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                String option = options[index];
                return isChecking
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        decoration: BoxDecoration(
                          color: optionSelected[index] ? const Color(0xFF241242) : Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                option,
                                softWrap: true,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.rubik(
                                  fontSize: 18,
                                  height: 1.2,
                                  color: optionSelected[index] ? Colors.transparent : Colors.black,
                                ),
                              ),
                            ),
                            if (optionSelected[index] && optionPositions[index] != null)
                              Center(
                                child: Text(
                                  optionPositions[index].toString(),
                                  style: GoogleFonts.rubik(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Container(
                        constraints: const BoxConstraints(minHeight: 75),
                        child: ElevatedButton(
                          onPressed: () {
                            _handleOptionSelection(index, option);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: optionSelected[index] ? Colors.white : Colors.black,
                            backgroundColor: optionSelected[index] ? const Color(0xFF241242) : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  option,
                                  softWrap: true,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.rubik(
                                    fontSize: 18,
                                    height: 1.2,
                                    color: optionSelected[index] ? Colors.transparent : Colors.black,
                                  ),
                                ),
                              ),
                              if (optionSelected[index] && optionPositions[index] != null)
                                Center(
                                  child: Text(
                                    optionPositions[index].toString(),
                                    style: GoogleFonts.rubik(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
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