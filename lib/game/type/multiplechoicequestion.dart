import 'dart:async';
import 'dart:math'; // Import the dart:math library for shuffling
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:soundpool/soundpool.dart';
import '../../widgets/text_with_shadow.dart';

class MultipleChoiceQuestion extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final int? selectedOptionIndex; // Allow null values
  final Function(int, bool) onOptionSelected; // Update the callback to include correctness
  final VoidCallback onOptionsShown; // Callback to notify when options are shown
  final double sfxVolume; // Add this line
  final String gamemode; // Add gamemode parameter

  const MultipleChoiceQuestion({
    super.key,
    required this.questionData,
    required this.selectedOptionIndex,
    required this.onOptionSelected,
    required this.onOptionsShown,
    required this.sfxVolume,
    required this.gamemode, // Add gamemode parameter
  });

  @override
  MultipleChoiceQuestionState createState() => MultipleChoiceQuestionState();
}

class MultipleChoiceQuestionState extends State<MultipleChoiceQuestion> {
  String? resultMessage;
  bool showOptions = false;
  bool showSelectedAnswer = false;
  bool showAllAnswers = false;
  bool showAllRed = false; // New state variable to show all options as red
  Timer? _timer; // Timer to handle the delay
  List<String> options = []; // Store shuffled options
  String? correctAnswer; // Store the correct answer text
  late Soundpool _soundpool;
  late int _soundId1, _soundId2, _soundId3;
  bool _soundsLoaded = false;

  @override
  void initState() {
    super.initState();
    resetState();
    _initializeSounds();
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
      await _soundpool.setVolume(soundId: soundId, volume: widget.sfxVolume); // Set the desired volume
      await _soundpool.play(soundId);
    }
  }

  @override
  void didUpdateWidget(covariant MultipleChoiceQuestion oldWidget) {
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

  void _handleOptionSelected(int index) {
    _playSound(_soundId3); // Play sound when an option is selected

    bool isCorrect = options[index] == correctAnswer;
    widget.onOptionSelected(index, isCorrect);

    (context.findAncestorStateOfType<GameplayPageState>())?.stopTts();

    // Use the public getter method to access answeredQuestions
    (context.findAncestorStateOfType<GameplayPageState>())?.answeredQuestions.add({
      'type': 'Multiple Choice', // Add the type field
      'question': widget.questionData['question'],
      'options': options,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect, // Add this line
    });

    // Pause the stopwatch
    if (widget.gamemode == 'arcade') {
      (context.findAncestorStateOfType<GameplayPageState>())?.pauseStopwatch();
    }

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showSelectedAnswer = true;
        if (isCorrect) {
          _playSound(_soundId2); // Play correct answer sound
        } else {
          _playSound(_soundId1); // Play wrong answer sound
        }
      });

      Future.delayed(const Duration(seconds: 1, milliseconds: 250), () {
        setState(() {
          showAllAnswers = true;
        });
      });
    });
  }

  // Add a method to force check the answer
  void forceCheckAnswer() {
    _playSound(_soundId1); // Play wrong answer sound

    setState(() {
      showAllRed = true; // Show all options as red
    });

    (context.findAncestorStateOfType<GameplayPageState>())?.stopTts();

    // Use the public getter method to access answeredQuestions
    (context.findAncestorStateOfType<GameplayPageState>())?.answeredQuestions.add({
      'type': 'Multiple Choice', // Add the type field
      'question': widget.questionData['question'],
      'options': options,
      'correctAnswer': correctAnswer,
      'isCorrect': false, // Add this line
    });

    // Pause the stopwatch
    if (widget.gamemode == 'arcade') {
      (context.findAncestorStateOfType<GameplayPageState>())?.pauseStopwatch();
    }

    // Call the onOptionSelected callback with null index and false correctness
    widget.onOptionSelected(-1, false);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showAllRed = false;
        showAllAnswers = true;
      });
    });
  }

  void resetState() {
    setState(() {
      resultMessage = null;
      showOptions = false;
      showSelectedAnswer = false;
      showAllAnswers = false;
      showAllRed = false;
      options = List<String>.from(widget.questionData['options'] ?? []);
      int correctAnswerIndex = int.parse(widget.questionData['answer'].toString()); // Fetch the correct answer index
      correctAnswer = options[correctAnswerIndex]; // Get the text corresponding to the correct answer index
      options.shuffle(Random()); // Shuffle the options
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

  @override
  Widget build(BuildContext context) {
    if (correctAnswer == null || !options.contains(correctAnswer)) {
      return Center(
        child: Text(
          'Error: Correct answer is null or not in options',
          style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        if (!showOptions)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TextWithShadow(
                  text: 'Multiple Choice',
                  fontSize: 40, // Adjusted font size to 40
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    widget.questionData['question'] ?? '',
                    style: GoogleFonts.rubik(fontSize: 25, color: Colors.white), // Reduced font size and removed bold
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
                    widget.questionData['question'] ?? '',
                    style: GoogleFonts.rubik(fontSize: 25, color: Colors.white), // Reduced font size and removed bold
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  Color buttonColor = Colors.white;
                  Color textColor = Colors.black;
                  if (showAllRed) {
                    buttonColor = Colors.red;
                    textColor = Colors.white;
                  } else if (showSelectedAnswer && index == widget.selectedOptionIndex) {
                    buttonColor = options[index] == correctAnswer ? Colors.green : Colors.red;
                    textColor = Colors.white;
                  } else if (showAllAnswers) {
                    if (index == widget.selectedOptionIndex) {
                      buttonColor = options[index] == correctAnswer ? Colors.green : Colors.red;
                      textColor = Colors.white;
                    } else {
                      buttonColor = options[index] == correctAnswer ? Colors.green : Colors.red;
                      textColor = Colors.white;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Stack(
                      children: [
                        ElevatedButton(
                          onPressed: widget.selectedOptionIndex == null
                              ? () {
                                  _handleOptionSelected(index);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: textColor,
                            backgroundColor: buttonColor,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                            disabledBackgroundColor: buttonColor, // Ensure the background color is not transparent when disabled
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 56.0), // Add padding to the left to make space for the letter container
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                options[index],
                                style: GoogleFonts.rubik(fontSize: 20, color: Colors.black), // Same font size as question text
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF241242),
                              borderRadius: BorderRadius.zero, // Set borderRadius to zero for sharp corners
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D, etc.
                                style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (resultMessage != null)
                Center(
                  child: Text(
                    resultMessage!,
                    style: GoogleFonts.rubik(fontSize: 24, color: resultMessage == 'Correct' ? Colors.green : Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}