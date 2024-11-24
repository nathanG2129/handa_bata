import 'dart:async';
import 'dart:math'; // Import the dart:math library for shuffling
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:soundpool/soundpool.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
  final int currentQuestionIndex; // Add this line

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
    required this.currentQuestionIndex, // Add this line
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
      // First check if index is valid for optionSelected array
      if (index < 0 || index >= optionSelected.length) {
        return;
      }

      if (optionSelected[index]) {
        // Deselect the option
        int selectedIndex = selectedOptions.indexOf(option);
        // Add bounds check for selectedOptions array
        if (selectedIndex != -1 && selectedIndex < selectedOptions.length) {
          selectedOptions[selectedIndex] = null;
          optionSelected[index] = false;
        }
      } else {
        // Select the option
        int emptyIndex = selectedOptions.indexOf(null);
        // Add bounds check for selectedOptions array
        if (emptyIndex != -1 && emptyIndex < selectedOptions.length) {
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
  int totalUpdates = correctOptions.length;
  int completedUpdates = 0;

  for (int i = 0; i < selectedOptions.length; i++) {
    await Future.delayed(const Duration(seconds: 1, milliseconds: 750));

    setState(() {
      if (selectedOptions[i] == correctOptions[i]) {
        _playSound(_soundId2);
        correctness[i] = true;
        widget.updateHealth(true, 'Fill in the Blanks');
        if (widget.gamemode == 'arcade') {
          widget.updateStopwatch(-5);
        }
      } else {
        _playSound(_soundId1);
        correctness[i] = false;
        widget.updateHealth(false, 'Fill in the Blanks', blankPairs: 1);
        if (widget.gamemode == 'arcade') {
          widget.updateStopwatch(5);
        }
      }
      completedUpdates++;
    });
  }

  // Only save after all HP updates are complete
  if (completedUpdates == totalUpdates) {
    final gameplayState = context.findAncestorStateOfType<GameplayPageState>();
    if (gameplayState != null) {
      gameplayState.saveStateQuestionIndex = widget.currentQuestionIndex + 1;
      gameplayState.autoSaveGame();
    }
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
  
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
  
        questionText.split(' ').forEach((word) {
          if (word.startsWith('<input>')) {
            String suffix = word.substring(7);
            
            questionWidgets.add(
              Container(
                margin: EdgeInsets.symmetric(
                  vertical: isTablet ? 6.0 : 4.0,
                  horizontal: isTablet ? 6.0 : 4.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 12.0 : 8.0,
                    horizontal: isTablet ? 16.0 : 12.0,
                  ),
                  color: selectedOptions[inputIndex] == null 
                      ? const Color(0xFF241242) 
                      : (correctness[inputIndex] != null
                          ? (correctness[inputIndex]! ? Colors.green : Colors.red)
                          : Colors.white),
                  child: Text(
                    selectedOptions[inputIndex] ?? '____',
                    style: (selectedOptions[inputIndex] == null)
                      ? GoogleFonts.vt323(
                          fontSize: isTablet ? 24 : 20,
                          color: Colors.white
                        )
                      : GoogleFonts.rubik(
                          fontSize: isTablet ? 20 : 16,
                          fontWeight: FontWeight.bold,
                          color: correctness[inputIndex] != null ? Colors.white : Colors.black,
                        ),
                  ),
                ),
              ),
            );
            if (suffix.isNotEmpty) {
              questionWidgets.add(
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 6.0 : 4.0
                  ),
                  child: Text(
                    suffix,
                    style: GoogleFonts.rubik(
                      fontSize: isTablet ? 24 : 18,
                      color: Colors.white
                    ),
                  ),
                ),
              );
            }
            inputIndex++;
          } else {
            questionWidgets.add(
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 6.0 : 4.0
                ),
                child: Text(
                  word,
                  style: GoogleFonts.rubik(
                    fontSize: isTablet ? 24 : 18,
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
              TextWithShadow(
                text: 'Fill in the Blanks',
                fontSize: isTablet ? 36 : 28,
              ),
            SizedBox(height: isTablet ? 24 : 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: questionWidgets,
            ),
            if (showOptions)
              SizedBox(height: isTablet ? 48 : 32),
            if (showOptions)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 150.0 : 16.0
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: isTablet ? 10.0 : 8.0,
                    crossAxisSpacing: isTablet ? 10.0 : 8.0,
                    mainAxisExtent: isTablet ? 70 : 60,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    String option = options[index];
                    return isChecking
                        ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 12 : 8
                            ),
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
                                      fontSize: isTablet ? 18 : 16,
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
                                        fontSize: isTablet ? 24 : 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Container(
                            constraints: BoxConstraints(
                              minHeight: isTablet ? 70 : 60
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                _handleOptionSelection(index, option);
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: optionSelected[index] ? Colors.white : Colors.black,
                                backgroundColor: optionSelected[index] ? const Color(0xFF241242) : Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 10 : 8,
                                  vertical: isTablet ? 16 : 12
                                ),
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
                                        fontSize: isTablet ? 18 : 16,
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
                                          fontSize: isTablet ? 24 : 20,
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
      },
    );
  }
}