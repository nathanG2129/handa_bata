import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/type/multiplechoicequestion.dart';
import 'package:handabatamae/game/type/FillInTheBlanksQuestion.dart';
import 'package:handabatamae/game/type/MatchingTypeQuestion.dart';
import 'package:handabatamae/game/type/IdentificationQuestion.dart';

class GameplayPage extends StatefulWidget {
  final String language;
  final String category;
  final String stageName;
  final Map<String, dynamic> stageData;

  const GameplayPage({
    super.key,
    required this.language,
    required this.category,
    required this.stageName,
    required this.stageData,
  });

  @override
  _GameplayPageState createState() => _GameplayPageState();
}

class _GameplayPageState extends State<GameplayPage> {
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _totalQuestions = 0;
  Timer? _timer;
  double _progress = 1.0;
  bool _isLoading = true;
  bool _hasError = false;
  int? _selectedOptionIndex;
  bool? _isCorrect;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
  }

  void _initializeQuestions() {
    try {
      List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(widget.stageData['questions'] ?? []);
      if (questions.isEmpty) {
        throw Exception('No questions found');
      }
      questions.shuffle(Random());
      setState(() {
        _questions = questions;
        _totalQuestions = questions.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      print('Error initializing questions: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 1.0;
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        _progress -= 0.01;
        if (_progress <= 0) {
          _progress = 0;
          _timer?.cancel();
          _nextQuestion();
        }
      });
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isCorrect = null;
        _controller.clear();
        _progress = 1.0; // Reset the progress bar immediately
      });
      Future.delayed(const Duration(seconds: 5), () {
        _startTimer(); // Restart the timer after the intro delay
      });
    } else {
      // Handle end of questions
    }
  }

  void _handleAnswerSelection(int index) {
    _timer?.cancel(); // Stop the timer when an option is selected
    setState(() {
      _selectedOptionIndex = index;
      _isCorrect = _questions[_currentQuestionIndex]['answer'] == index;
    });

    Future.delayed(const Duration(seconds: 3), () {
      _nextQuestion();
    });
  }

  void _handleTextAnswerSubmission(String answer) {
    _timer?.cancel(); // Stop the timer when an answer is submitted
    setState(() {
      _isCorrect = _questions[_currentQuestionIndex]['correctAnswer'] == answer;
    });

    Future.delayed(const Duration(seconds: 3), () {
      _nextQuestion();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error initializing questions. Please try again later.',
            style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'No questions available.',
            style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    Map<String, dynamic> currentQuestion = _questions[_currentQuestionIndex];
    String? questionType = currentQuestion['type'];

    Widget questionWidget;
    switch (questionType) {
      case 'Multiple Choice':
        questionWidget = MultipleChoiceQuestion(
          key: ValueKey(_currentQuestionIndex), // Ensure the widget is rebuilt for each question
          questionData: currentQuestion,
          selectedOptionIndex: _selectedOptionIndex,
          onOptionSelected: _handleAnswerSelection,
          onOptionsShown: _startTimer, // Start the timer when options are shown
        );
        break;
      case 'Fill in the Blanks':
        questionWidget = FillInTheBlanksQuestion(
          questionData: currentQuestion,
          controller: _controller,
          isCorrect: _isCorrect ?? false,
          onAnswerSubmitted: _handleTextAnswerSubmission,
        );
        break;
      case 'Matching Type':
        questionWidget = MatchingTypeQuestion(
          questionData: currentQuestion,
          onMatchingCompleted: (matching) {
            // Handle matching completion
          },
        );
        break;
      case 'Identification':
        questionWidget = IdentificationQuestion(
          questionData: currentQuestion,
          controller: _controller,
          isCorrect: _isCorrect ?? false,
          onAnswerSubmitted: _handleTextAnswerSubmission,
        );
        break;
      default:
        questionWidget = Center(
          child: Text(
            'Unknown question type',
            style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
          ),
        );
    }

    return Scaffold(
      body: Container(
        color: const Color(0xFF5E31AD), // Set the background color to #5e31ad
        child: SafeArea(
          child: Column(
            children: [
              ProgressBar(progress: _progress),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentQuestionIndex + 1} of $_totalQuestions',
                      style: GoogleFonts.vt323(fontSize: 32, color: Colors.white), // Increased font size and set color to white
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      onPressed: () {
                        // Handle mute/unmute
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: questionWidget,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double progress;

  const ProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20, // Make the progress bar thicker
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
      ),
    );
  }
}