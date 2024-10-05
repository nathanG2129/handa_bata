import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/results_page.dart';
import 'package:handabatamae/game/type/multiplechoicequestion.dart';
import 'package:handabatamae/game/type/fillintheblanksquestion.dart';
import 'package:handabatamae/game/type/matchingtypequestion.dart';
import 'package:handabatamae/game/type/identificationquestion.dart';

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
  int _fullyCorrectAnswersCount = 0; // Add this line to track fully correct answers
  int _totalQuestions = 0;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _timer;
  double _progress = 1.0;
  int? _selectedOptionIndex;
  bool? _isCorrect;
  int _correctAnswersCount = 0; // Define the correct answers count
  int _wrongAnswersCount = 0; // Define the wrong answers count
  int _currentStreak = 0;
  int _highestStreak = 0;
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<IdentificationQuestionState> _identificationQuestionKey = GlobalKey<IdentificationQuestionState>();
  final GlobalKey<MultipleChoiceQuestionState> _multipleChoiceQuestionKey = GlobalKey<MultipleChoiceQuestionState>();
  final GlobalKey<FillInTheBlanksQuestionState> _fillInTheBlanksQuestionKey = GlobalKey<FillInTheBlanksQuestionState>(); // Add a global key for FillInTheBlanksQuestion
  final GlobalKey<MatchingTypeQuestionState> _matchingTypeQuestionKey = GlobalKey<MatchingTypeQuestionState>();

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
  }

  void _initializeQuestions() {
    try {
      List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(widget.stageData['questions'] ?? []);
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
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress -= 0.01;
        if (_progress <= 0) {
          _progress = 0;
          _timer?.cancel();
          _forceCheckAnswer(); // Force check the answer when the timer reaches zero
        }
      });
    });
  }

  void _startMatchingTimer() {
    _timer?.cancel();
    _progress = 1.0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress -= 0.01;
        if (_progress <= 0) {
          _progress = 0;
          _timer?.cancel();
          _forceCheckAnswer(); // Force check the answer when the timer reaches zero
        }
      });
    });
  }
  
  void _forceCheckAnswer() {
    Map<String, dynamic> currentQuestion = _questions[_currentQuestionIndex];
    String? questionType = currentQuestion['type'];
  
    switch (questionType) {
      case 'Multiple Choice':
        if (_selectedOptionIndex == null) {
          _multipleChoiceQuestionKey.currentState?.forceCheckAnswer();
        }
        break;
      case 'Fill in the Blanks':
        _fillInTheBlanksQuestionKey.currentState?.forceCheckAnswer(); // Call the forceCheckAnswer method of FillInTheBlanksQuestion
        break;
      case 'Identification':
        _identificationQuestionKey.currentState?.forceCheckAnswer();
        break;
      case 'Matching Type':
        _matchingTypeQuestionKey.currentState?.forceCheckAnswer(); // Call the forceCheckAnswer method of MatchingTypeQuestion
        break;
      default:
        print('Unknown question type');
    }
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
      // Calculate accuracy
      int totalAnswers = _correctAnswersCount + _wrongAnswersCount;
      double accuracy = totalAnswers > 0 ? _correctAnswersCount / totalAnswers : 0.0;
  
      // Navigate to ResultsPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsPage(
            score: _fullyCorrectAnswersCount,
            accuracy: accuracy,
            streak: _calculateStreak(),
          ),
        ),
      );
    }
  }
  
  int _calculateStreak() {
    return _highestStreak;
  }

  void _handleMultipleChoiceAnswerSubmission(int? index, bool isCorrect) {
    _timer?.cancel(); // Stop the timer when an option is selected or forced check occurs
    setState(() {
      _selectedOptionIndex = index;
      _isCorrect = isCorrect;
      if (index == null) {
        // Forced check, increment wrong answers count
        _wrongAnswersCount++;
        _currentStreak = 0; // Reset the current streak
      } else if (_isCorrect == true) {
        _correctAnswersCount++;
        _fullyCorrectAnswersCount++;
        _currentStreak++; // Increment the current streak
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak; // Update the highest streak
        }
      } else {
        _wrongAnswersCount++;
        _currentStreak = 0; // Reset the current streak
      }
    });
  
    print('Correct Answers Count: $_correctAnswersCount');
    print('Wrong Answers Count: $_wrongAnswersCount');
    print('Fully Correct Answers Count: $_fullyCorrectAnswersCount');
    print('Current Streak: $_currentStreak');
    print('Highest Streak: $_highestStreak');
  
    Future.delayed(const Duration(seconds: 6), () {
      _nextQuestion();
    });
  }

  void _handleFillInTheBlanksAnswerSubmission(Map<String, dynamic> answerData) {
    _timer?.cancel(); // Stop the timer when an answer is submitted
    setState(() {
      _correctAnswersCount += (answerData['correctCount'] as int);
      _wrongAnswersCount += (answerData['wrongCount'] as int);
      if (answerData['isFullyCorrect'] as bool) {
        _fullyCorrectAnswersCount++;
        _currentStreak++; // Increment the current streak
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak; // Update the highest streak
        }
      } else {
        _currentStreak = 0; // Reset the current streak
      }
    });
  
    print('Correct Answers Count: $_correctAnswersCount');
    print('Wrong Answers Count: $_wrongAnswersCount');
    print('Fully Correct Answers Count: $_fullyCorrectAnswersCount');
    print('Current Streak: $_currentStreak');
    print('Highest Streak: $_highestStreak');
  
    Future.delayed(const Duration(seconds: 6), () {
      _nextQuestion();
    });
  }
  
void _handleIdentificationAnswerSubmission(String answer, bool isCorrect) {
  _timer?.cancel(); // Stop the timer when an answer is submitted
  setState(() {
    _isCorrect = isCorrect;
    if (_isCorrect == true) {
      _correctAnswersCount++;
      _fullyCorrectAnswersCount++;
      _currentStreak++; // Increment the current streak
      if (_currentStreak > _highestStreak) {
        _highestStreak = _currentStreak; // Update the highest streak
      }
    } else {
      _wrongAnswersCount++;
      _currentStreak = 0; // Reset the current streak
    }
  });

  print('Correct Answers Count: $_correctAnswersCount');
  print('Wrong Answers Count: $_wrongAnswersCount');
  print('Fully Correct Answers Count: $_fullyCorrectAnswersCount');
  print('Current Streak: $_currentStreak');
  print('Highest Streak: $_highestStreak');

  Future.delayed(const Duration(seconds: 6), () {
    _nextQuestion();
  });
}
  
  void _handleMatchingTypeAnswerSubmission() {
    _timer?.cancel(); // Stop the timer when an answer is submitted
    setState(() {
      // Assuming correctPairCount and incorrectPairCount are updated in MatchingTypeQuestion
      _correctAnswersCount += _matchingTypeQuestionKey.currentState?.correctPairCount ?? 0;
      _wrongAnswersCount += _matchingTypeQuestionKey.currentState?.incorrectPairCount ?? 0;
  
      // Check if all pairs are correct and increment the fully correct answers count
      if (_matchingTypeQuestionKey.currentState?.areAllPairsCorrect() == true) {
        _fullyCorrectAnswersCount++;
        _currentStreak++; // Increment the current streak
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak; // Update the highest streak
        }
      } else {
        _currentStreak = 0; // Reset the current streak
      }
    });
  
    print('Correct Answers Count: $_correctAnswersCount');
    print('Wrong Answers Count: $_wrongAnswersCount');
    print('Fully Correct Answers Count: $_fullyCorrectAnswersCount');
    print('Current Streak: $_currentStreak');
    print('Highest Streak: $_highestStreak');
  
    Future.delayed(const Duration(seconds: 6), () {
      _nextQuestion();
    });
  }
  
  void _handleVisualDisplayComplete() {
    Future.delayed(const Duration(seconds: 3), () {
      _nextQuestion();
    });
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
          key: _multipleChoiceQuestionKey, // Use the global key to access the state
          questionData: currentQuestion,
          selectedOptionIndex: _selectedOptionIndex,
          onOptionSelected: _handleMultipleChoiceAnswerSubmission,
          onOptionsShown: _startTimer, // Start the timer when options are shown
        );
        break;
      case 'Fill in the Blanks':
        questionWidget = FillInTheBlanksQuestion(
          key: _fillInTheBlanksQuestionKey, // Use the global key to access the state
          questionData: currentQuestion,
          controller: _controller,
          isCorrect: _isCorrect ?? false,
          onAnswerSubmitted: _handleFillInTheBlanksAnswerSubmission,
          onOptionsShown: _startTimer, // Pass the callback to start the timer
          nextQuestion: () {},
        );
        break;
      case 'Matching Type':
        questionWidget = MatchingTypeQuestion(
          key: _matchingTypeQuestionKey, // Use the global key to access the state
          questionData: currentQuestion,
          onOptionsShown: _startMatchingTimer, // Start the timer when options are shown
          onAnswerChecked: _handleMatchingTypeAnswerSubmission, // Use the new method
          onVisualDisplayComplete: _handleVisualDisplayComplete, // Add this line
        );
        break;
      case 'Identification':
        questionWidget = IdentificationQuestion(
          key: _identificationQuestionKey, // Use the global key to access the state
          questionData: currentQuestion,
          controller: _controller,
          onAnswerSubmitted: _handleIdentificationAnswerSubmission,
          onOptionsShown: _startTimer, // Pass the callback to start the timer
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
      height: 30, // Make the progress bar thicker
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
      ),
    );
  }
}