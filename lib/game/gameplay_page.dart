import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/results_page.dart';
import 'package:handabatamae/game/type/multiplechoicequestion.dart';
import 'package:handabatamae/game/type/fillintheblanksquestion.dart';
import 'package:handabatamae/game/type/matchingtypequestion.dart';
import 'package:handabatamae/game/type/identificationquestion.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GameplayPage extends StatefulWidget {
  final String language;
  final Map<String, dynamic> category; // Accept the entire category map
  final String stageName;
  final Map<String, dynamic> stageData;
  final String mode; // Accept the mode

  const GameplayPage({
    super.key,
    required this.language,
    required this.category,
    required this.stageName,
    required this.stageData,
    required this.mode, // Add the mode parameter
  });

  @override
  GameplayPageState createState() => GameplayPageState();
}

class GameplayPageState extends State<GameplayPage> {
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
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
  int _fullyCorrectAnswersCount = 0; // Define the fully correct answers count
  bool _isGameOver = false;
  double _hp = 100.0; // Define the HP variable with a default value of 1.0 (full HP)
  List<Map<String, dynamic>> _answeredQuestions = []; // Add this line

  List<Map<String, dynamic>> get answeredQuestions => _answeredQuestions;

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
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 1.0;
    int timerDuration = widget.mode == 'Hard' ? 50 : 100; // Adjust timer duration based on mode
    _timer = Timer.periodic(Duration(milliseconds: timerDuration), (timer) {
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
    int timerDuration = widget.mode == 'Hard' ? 50 : 100; // Adjust timer duration based on mode
    _timer = Timer.periodic(Duration(milliseconds: timerDuration), (timer) {
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
    }
  }

  void _nextQuestion() {
    if (_isGameOver) {
      // Calculate accuracy
      int totalAnswers = _correctAnswersCount + _wrongAnswersCount;
      double accuracy = totalAnswers > 0 ? _correctAnswersCount / totalAnswers : 0.0;
  
      // Navigate to ResultsPage after a delay
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsPage(
              score: _correctAnswersCount, // Use the correct answers count as the score
              accuracy: accuracy,
              streak: _calculateStreak(),
              language: widget.language, // Pass the language
              category: widget.category, // Pass the category
              stageName: widget.stageName, // Pass the stage name
              stageData: {
                ...widget.stageData,
                'totalQuestions': _totalQuestions, // Add totalQuestions to stageData
              },
              mode: widget.mode, // Pass the mode
              fullyCorrectAnswersCount: _fullyCorrectAnswersCount, // Pass the fully correct answers count
              answeredQuestions: _answeredQuestions, // Pass the answered questions
            ),
          ),
        );
      });
    } else if (_currentQuestionIndex < _totalQuestions - 1) {
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
            score: _correctAnswersCount, // Use the correct answers count as the score
            accuracy: accuracy,
            streak: _calculateStreak(),
            language: widget.language, // Pass the language
            category: widget.category, // Pass the category
            stageName: widget.stageName, // Pass the stage name
            stageData: {
              ...widget.stageData,
              'totalQuestions': _totalQuestions, // Add totalQuestions to stageData
            },
            fullyCorrectAnswersCount: _fullyCorrectAnswersCount, // Pass the fully correct answers count
            mode: widget.mode, // Pass the mode
            answeredQuestions: _answeredQuestions, // Pass the answered questions
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
        _fullyCorrectAnswersCount++; // Increment fully correct answers count
        _currentStreak++; // Increment the current streak
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak; // Update the highest streak
        }
      } else {
        _wrongAnswersCount++;
        _currentStreak = 0; // Reset the current streak
      }
    });
  
    // Add a delay of 1 second before updating health
    Future.delayed(const Duration(seconds: 1), () {
      _updateHealth(isCorrect, 'Multiple Choice');
    });
  
    // Print fully correct answers count
  
    Future.delayed(const Duration(seconds: 6), () {
      _nextQuestion();
    });
  }

  void _handleFillInTheBlanksAnswerSubmission(Map<String, dynamic> answerData) {
    _timer?.cancel(); // Stop the timer when an answer is submitted
    setState(() {
    _answeredQuestions.add({
      'question': _questions[_currentQuestionIndex]['question'],
      'correctAnswer': answerData['correctAnswer'],
      'isCorrect': answerData['isCorrect'],
      'type': 'Fill in the Blanks',
    });
      _correctAnswersCount += (answerData['correctCount'] as int);
      _wrongAnswersCount += (answerData['wrongCount'] as int);
      if (answerData['isFullyCorrect'] as bool) {
        _fullyCorrectAnswersCount++; // Increment fully correct answers count
        _currentStreak++; // Increment the current streak
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak; // Update the highest streak
        }
      } else {
        _currentStreak = 0; // Reset the current streak
      }
    });
  
    // Delay the HP update by 1 second
    Future.delayed(const Duration(seconds: 1), () {
      _updateHealth(answerData['isFullyCorrect'] as bool, 'Fill in the Blanks', blankPairs: answerData['wrongCount'] as int);
    });
  
    // Print fully correct answers count
  
    Future.delayed(const Duration(seconds: 6), () {
      _nextQuestion();
    });
  }
  
void _handleIdentificationAnswerSubmission(String answer, bool isCorrect) {
    _timer?.cancel(); // Stop the timer when an answer is submitted
    Map<String, dynamic> currentQuestion = _questions[_currentQuestionIndex];
    
    _answeredQuestions.add({
    'question': currentQuestion['question'],
    'options': [], // Identification questions don't have options
    'correctAnswer': currentQuestion['answer'],
    'isCorrect': isCorrect,
    'type': 'Identification',
  });

  setState(() {
    _isCorrect = isCorrect;
    if (_isCorrect == true) {
      _correctAnswersCount++;
      _fullyCorrectAnswersCount++; // Increment fully correct answers count
      _currentStreak++; // Increment the current streak
      if (_currentStreak > _highestStreak) {
        _highestStreak = _currentStreak; // Update the highest streak
      }
    } else {
      _wrongAnswersCount++;
      _currentStreak = 0; // Reset the current streak
    }
  });

  // Update health
  _updateHealth(isCorrect, 'Identification');

  // Print fully correct answers count

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
        _fullyCorrectAnswersCount++; // Increment fully correct answers count
        _currentStreak++; // Increment the current streak
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak; // Update the highest streak
        }
      } else {
        _currentStreak = 0; // Reset the current streak
      }
    });
  
    // Update health
    _updateHealth(_matchingTypeQuestionKey.currentState?.areAllPairsCorrect() == true, 'Matching Type', blankPairs: _matchingTypeQuestionKey.currentState?.incorrectPairCount ?? 0);
  
    // Print fully correct answers count
  }
  
  void _handleVisualDisplayComplete() {
    Future.delayed(const Duration(seconds: 3), () {
      _nextQuestion();
    });
  }

  void _updateHealth(bool isCorrect, String questionType, {int blankPairs = 0, String difficulty = 'normal'}) {
    setState(() {
      if (isCorrect) {
        if (questionType == 'Matching Type' || questionType == 'Fill in the Blanks') {
          _hp += 5;
        } else {
          _hp += 20;
        }
      } else {
        if (questionType == 'Matching Type' || questionType == 'Fill in the Blanks') {
          _hp -= (difficulty == 'hard' ? 20 : 10) * blankPairs;
        } else {
          _hp -= (difficulty == 'hard' ? 50 : 25);
        }
      }
  
      // Clamp the health value between 0 and 100
      _hp = _hp.clamp(0.0, 100.0);
  
      // Handle health reaching 0
      if (_hp <= 0) {
        _hp = 0;
        // Handle game over logic here
        _isGameOver = true;
      }
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
    body: ResponsiveBreakpoints(
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: 800, name: TABLET),
        Breakpoint(start: 801, end: 1920, name: DESKTOP),
        Breakpoint(start: 1921, end: double.infinity, name: '4K'),
      ],
      child: MaxWidthBox(
        maxWidth: 1200,
        child: ResponsiveScaledBox(
          width: ResponsiveValue<double>(context, conditionalValues: [
            const Condition.equals(name: MOBILE, value: 450),
            const Condition.between(start: 800, end: 1100, value: 800),
            const Condition.between(start: 1000, end: 1200, value: 1000),
          ]).value,
          child: WillPopScope(
            onWillPop: () async {
              // Prevent back navigation
              return false;
            },
            child: Scaffold(
              backgroundColor: const Color(0xFF5E31AD),
              body: SafeArea(
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
                    HPBar(hp: _hp), // Add the HP bar at the bottom
                  ],
                ),
              ),
            ),
          ),
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

class HPBar extends StatelessWidget {
  final double hp;

  const HPBar({super.key, required this.hp});

  @override
  Widget build(BuildContext context) {
    final fill = (hp * 3).toInt(); // Calculate the fill based on the HP value (0 to 300)

    final svgString = '''
    <svg
      width="100%"
      height="100%"
      viewBox="0 0 306 30" 
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M6 6H300V24H6V6Z" fill="black" /> 
      <path
        d="M6 6H${fill}V24H6V6Z" 
        fill="${fill > 75 ? "#32C067" : "#C62323"}"
      />
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M6 0H300V6H276V24H300V30H6V24H30V6H6V0ZM270 24V6H246V24H270ZM240 24V6H216V24H240ZM210 24V6H186V24H210ZM180 24V6H156V24H180ZM150 6V24H126V6H150ZM120 6V24H96V6H120ZM90 6V24H66V6H90ZM60 6V24H36V6H60Z"
        fill="#16171A"
      />
      <path d="M6 6V24H0V6H6Z" fill="#16171A" />
      <path d="M300 24V6H306V24H300Z" fill="#16171A" />
    </svg>
    ''';

    return SizedBox(
      height: 120, // Adjust height as needed
      child: SvgPicture.string(svgString),
    );
  }
}