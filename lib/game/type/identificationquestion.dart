import 'dart:async';
import 'dart:math'; // Import the dart:math library for shuffling
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:soundpool/soundpool.dart';

class IdentificationQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final TextEditingController controller;
  final Function(String, bool) onAnswerSubmitted; // Update the callback to include correctness
  final VoidCallback onOptionsShown;
  final double sfxVolume; // Add this line
  final String gamemode; // Add this line

  const IdentificationQuestion({
    super.key,
    required this.questionData,
    required this.controller,
    required this.onAnswerSubmitted,
    required this.onOptionsShown, 
    required this.sfxVolume,
    required this.gamemode, // Add this line
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
  int isCorrect = 0; // Use int to represent correctness: 0 (neutral), 1 (wrong), 2 (correct)
  bool isCheckingAnswer = false; // Flag to indicate when the answer is being checked
  bool showCorrectAnswer = false; // Flag to indicate when to show the correct answer
  late Soundpool _soundpool;
  late int _soundId1, _soundId2, _soundId3;
  bool _soundsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    _initializeSounds();
    _showIntroduction();
    _resetState(); // Add debug statements
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
      uniqueOptions.shuffle(Random()); // Shuffle the options
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
    if (widget.gamemode == 'arcade') {
      setState(() {
        showInput = true;
      });
      widget.onOptionsShown(); // Call the callback to start the timer
    } else {
      _timer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            showInput = true;
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
      isCorrect = 0; // Set to 0 to indicate neutral state
    });

    (context.findAncestorStateOfType<GameplayPageState>())?.stopTts();

    // Pause the stopwatch
    if (widget.gamemode == 'arcade') {
      (context.findAncestorStateOfType<GameplayPageState>())?.pauseStopwatch();
    }


    String userAnswer = '';
    for (int i = 0; i < widget.questionData['answerLength']; i++) {
      userAnswer += selectedOptions[i]?.split('_')[0] ?? '_';
    }

    // Trim spaces from userAnswer
    userAnswer = userAnswer.trim();

    // Add a delay before showing the correctness of the answer
    Future.delayed(const Duration(seconds: 0, milliseconds: 500), () {
      setState(() {
        isCorrect = userAnswer == widget.questionData['answer'] ? 2 : 1;
        _playSound(isCorrect == 2 ? _soundId2 : _soundId1); // Play correct or wrong answer sound
      });

      // Call the callback with the correctness of the answer
      widget.onAnswerSubmitted(userAnswer, isCorrect == 2);

      // Add a delay before showing the correct answer
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          showCorrectAnswer = true; // Show the correct answer after the delay
        });
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
      isCorrect = 0; // Reset to neutral state
      isCheckingAnswer = false;
      showCorrectAnswer = false;
      _initializeOptions();
      if (widget.gamemode == 'arcade') {
        showInput = true;
      } else {
        _showIntroduction();
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
    List<int> spaces = List<int>.from(
        widget.questionData['space'].map((e) => int.parse(e.toString())));
  
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
                  style: GoogleFonts.rubik(fontSize: 25, color: Colors.white), // Updated font style
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
                  color: showCorrectAnswer
                      ? Colors.green
                      : (isCheckingAnswer
                          ? (isCorrect == 0
                              ? Colors.white
                              : (isCorrect == 2
                                  ? Colors.green
                                  : Colors.red))
                          : Colors.white), // Change color based on correctness
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500), // Set the duration for the fade-in effect
                  curve: Curves.easeInOut, // Use a smooth curve for the transition
                  color: showCorrectAnswer
                      ? Colors.green
                      : (isCheckingAnswer
                          ? (isCorrect == 0
                              ? Colors.white
                              : (isCorrect == 2
                                  ? Colors.green
                                  : Colors.red))
                          : Colors.white),
                  child: Text(
                    answerText,
                    style: GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black), // Updated font style
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!showCorrectAnswer) // Hide options when showing the correct answer
                Wrap(
                  alignment: WrapAlignment.center,
                  children: uniqueOptions.asMap().entries.map((entry) {
                    int index = entry.key;
                    String option = entry.value;
                    String optionValue = option.split('_')[0];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
                      child: IgnorePointer(
                        ignoring: isCheckingAnswer,
                        child: ElevatedButton(
                          onPressed: () {
                            _handleOptionSelection(index, option);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: optionSelected[index] ? Colors.white : Colors.black,
                            backgroundColor: optionSelected[index] ? const Color(0xFF241242) : Colors.white,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                          child: Text(
                            optionValue,
                            style: GoogleFonts.rubik(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )
            ],
          ),
      ],
    );
  }
}