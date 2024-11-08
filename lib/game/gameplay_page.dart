import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/results/results_page.dart';
import 'package:handabatamae/game/type/multiplechoicequestion.dart';
import 'package:handabatamae/game/type/fillintheblanksquestion.dart';
import 'package:handabatamae/game/type/matchingtypequestion.dart';
import 'package:handabatamae/game/type/identificationquestion.dart';
import 'package:handabatamae/pages/arcade_stages_page.dart';
import 'package:handabatamae/pages/stages_page.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'settings_dialog.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handabatamae/services/auth_service.dart';

class GameplayPage extends StatefulWidget {
  final String language;
  final Map<String, dynamic> category; // Accept the entire category map
  final String stageName;
  final Map<String, dynamic> stageData;
  final String mode; // Accept the mode
  final String gamemode;

  const GameplayPage({
    super.key,
    required this.language,
    required this.category,
    required this.stageName,
    required this.stageData,
    required this.mode, // Add the mode parameter
    required this.gamemode,
  });

  @override
  GameplayPageState createState() => GameplayPageState();
}

class GameplayPageState extends State<GameplayPage> {
  FlutterTts flutterTts = FlutterTts();
  double _speechRate = 0.5;
  double _ttsVolume = 0.5;
  double _musicVolume = 0.5; // Default music volume
  double _sfxVolume = 0.5; // Default SFX volume
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _totalQuestions = 0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _bgMusicLoaded = false;
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

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isTextToSpeechEnabled = false; // Add this line
  String _selectedVoice = ''; // Default to male voice
  final String _maleVoiceEn = 'en-us-x-tpd-local'; // Male voice for English
  final String _femaleVoiceEn = 'en-us-x-log-local'; // Female voice for English
  final String _maleVoiceFil = 'fil-ph-x-fie-local'; // Male voice for Filipino
  final String _femaleVoiceFil = 'fil-PH-language'; // Female voice for Filipino

  Timer? _stopwatchTimer;
  int _stopwatchSeconds = 0;
  String _stopwatchTime = '00:00';

  int _totalTimeInSeconds = 0;
  int _questionsAnswered = 0;
  double _averageTimePerQuestion = 0.0;

  // Add this field to track if the page is being disposed
  bool _isDisposing = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _playBackgroundMusic();
    _loadSavedGameOrInitialize();
    _loadSettings();
    flutterTts = FlutterTts(); // Ensure TTS is initialized
    if (widget.language == 'fil') {
      _selectedVoice = _maleVoiceFil;
    } else {
      _selectedVoice = _maleVoiceEn;
    }
    if (widget.gamemode == 'arcade') {
    _startStopwatch();
    }
  }

  @override
  void didUpdateWidget(covariant GameplayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stageData != widget.stageData) {
      _initializeQuestions();
    }
  
    // Read the current question whenever the widget is updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      readCurrentQuestion();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTextToSpeechEnabled = prefs.getBool('isTextToSpeechEnabled') ?? false;
      _selectedVoice = prefs.getString('selectedVoice') ?? 'en-us-x-tpd-local';
      _speechRate = prefs.getDouble('speed')!;
      _ttsVolume = prefs.getDouble('ttsVolume')!;
      _musicVolume = prefs.getDouble('musicVolume') ?? 1.0;
      _sfxVolume = prefs.getDouble('sfxVolume') ?? 1.0;
    });
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

  Future<void> _playBackgroundMusic() async {
    try {
      await _audioPlayer.setLoopMode(LoopMode.one); // Loop the background music
      await _audioPlayer.setAsset('assets/sound/bgm/AdvBGM.mp3'); // Set the audio source
      setState(() {
        _bgMusicLoaded = true;
      });
      await _audioPlayer.setVolume(_musicVolume); // Set the volume
      await _audioPlayer.play(); // Play the background music
    } catch (e) {
    }
  }

  Future<void> _speak(String text) async {
    // Debugging statement
    String locale = widget.language == 'fil' ? 'fil-PH' : 'en-US';
    await flutterTts.setLanguage(locale);
    await flutterTts.setVoice({"name": _selectedVoice, "locale": locale});
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(_speechRate); // Use the state variable
    await flutterTts.setVolume(_ttsVolume); // Use the state variable
    await flutterTts.speak(text);
  }

  Future<void> stopTts() async {
    await flutterTts.stop();
  }
  
  @override
  void dispose() {
    print('🎮 Disposing GameplayPage');
    _isDisposing = true;

    // Cancel timers
    _timer?.cancel();
    _timer = null;
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;

    // Cleanup TTS
    Future.microtask(() async {
      try {
        await flutterTts.stop();
        await flutterTts.pause();
      } catch (e) {
        print('❌ Error disposing TTS: $e');
      }
    });

    // Cleanup audio
    Future.microtask(() async {
      try {
        await _audioPlayer.pause();
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(0);
        await _audioPlayer.dispose();
      } catch (e) {
        print('❌ Error disposing audio player: $e');
      }
    });

    // Only save state if:
    // 1. Not in arcade mode
    // 2. Game is not over
    // 3. Not navigating to results page
    if (!_isGameOver && 
        widget.gamemode != 'arcade' && 
        !ModalRoute.of(context)!.settings.name!.contains('ResultsPage')) {
      _saveGameState();
    }

    super.dispose();
  }

void readCurrentQuestion() {
  if (_isTextToSpeechEnabled) {
    if (_currentQuestionIndex < _questions.length) {
      Map<String, dynamic> currentQuestion = _questions[_currentQuestionIndex];
      String questionType = currentQuestion['type'] ?? '';

      String textToRead = '';
      switch (questionType) {
        case 'Multiple Choice':
          String questionText = currentQuestion['question'] ?? '';
          List<String> options = _multipleChoiceQuestionKey.currentState?.options ?? [];
          textToRead = '$questionText ';
          for (int i = 0; i < options.length; i++) {
            textToRead += '${String.fromCharCode(65 + i)}. ${options[i]}. ';
          }
          break;
        case 'Fill in the Blanks':
          String questionText = currentQuestion['question'] ?? '';
          List<String> options = _fillInTheBlanksQuestionKey.currentState?.options ?? [];
          textToRead = '${questionText.replaceAll('<input>', 'blank')} ';
          for (int i = 0; i < options.length; i++) {
            textToRead += '${options[i]}. ';
          }
          break;
        case 'Matching Type':
          String questionText = currentQuestion['question'] ?? '';
          List<String> section1Options = _matchingTypeQuestionKey.currentState?.section1Options ?? [];
          List<String> section2Options = _matchingTypeQuestionKey.currentState?.section2Options ?? [];
          textToRead = '$questionText ';
          textToRead += 'Column A options: ';
          for (int i = 0; i < section1Options.length; i++) {
            textToRead += '${section1Options[i]}. ';
          }
          textToRead += 'Column B options: ';
          for (int i = 0; i < section2Options.length; i++) {
            textToRead += '${section2Options[i]}. ';
          }
          break;
        case 'Identification':
          textToRead = currentQuestion['question'] ?? '';
          break;
        // Add cases for other question types here
        default:
          textToRead = 'Unknown question type';
      }

      // Debugging statement
      _speak(textToRead);
    } else {
      // Debugging statement
    }
  } else {
    // Debugging statement
  }
}

  void _startTimer() {
    if (_isDisposing) return;
    
    _timer?.cancel();
    _progress = 1.0;
    int timerDuration = widget.mode == 'Hard' ? 100 : 300;
    readCurrentQuestion();
    _timer = Timer.periodic(Duration(milliseconds: timerDuration), (timer) {
      if (_isDisposing) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress -= 0.01;
        if (_progress <= 0) {
          _progress = 0;
          _timer?.cancel();
          _forceCheckAnswer();
        }
      });
    });
  }
  
  void _startMatchingTimer() {
    _timer?.cancel();
    _progress = 1.0;
    int timerDuration = widget.mode == 'Hard' ? 100 : 300; // Adjust timer duration based on mode
    readCurrentQuestion(); // Read the next question
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

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _stopwatchSeconds++;
        _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds);
      });
    });
  }

  void pauseStopwatch() {
    _stopwatchTimer?.cancel();
  }

  void _resumeStopwatch() {
    _startStopwatch();
  }

  String _formatStopwatchTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
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
        _audioPlayer.stop(); // Stop the background music
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'ResultsPage'),
            builder: (context) {
              // Stop any ongoing timers before navigation
              _timer?.cancel();
              _stopwatchTimer?.cancel();
              
              return ResultsPage(
                score: _correctAnswersCount,
                accuracy: accuracy,
                streak: _calculateStreak(),
                language: widget.language,
                category: widget.category,
                stageName: widget.stageName,
                stageData: {
                  ...widget.stageData,
                  'totalQuestions': _totalQuestions,
                  'maxScore': _questions.fold(0, (sum, question) {
                    if (question['type'] == 'Multiple Choice') {
                      return sum + 1;
                    } else if (question['type'] == 'Fill in the Blanks') {
                      return sum + (question['answer'] as List).length;
                    } else if (question['type'] == 'Identification') {
                      return sum + 1;
                    } else if (question['type'] == 'Matching Type') {
                      return sum + (question['answerPairs'] as List).length;
                    } else {
                      return sum;
                    }
                  }),
                },
                mode: widget.mode,
                gamemode: widget.gamemode,
                fullyCorrectAnswersCount: _fullyCorrectAnswersCount,
                answeredQuestions: _answeredQuestions,
                record: _stopwatchTime,
                isGameOver: _isGameOver,
                averageTimePerQuestion: _averageTimePerQuestion,
              );
            },
          ),
        );
      });
    } else if (_currentQuestionIndex < _totalQuestions - 1) {
      _saveGameState(); // Auto-save after each question
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isCorrect = null;
        _controller.clear();
        _progress = 1.0; // Reset the progress bar immediately
      });
      if (widget.gamemode != 'arcade') {
        Future.delayed(const Duration(seconds: 5), () {
          _startTimer(); // Restart the timer after the intro delay
        });
      } else if (widget.gamemode == 'arcade') {
      _resumeStopwatch();
      }
    } else {
      // Calculate accuracy
      int totalAnswers = _correctAnswersCount + _wrongAnswersCount;
      double accuracy = totalAnswers > 0 ? _correctAnswersCount / totalAnswers : 0.0;
      
      _audioPlayer.stop(); // Stop the background music
      // Navigate to ResultsPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'ResultsPage'),
          builder: (context) {
            // Stop any ongoing timers before navigation
            _timer?.cancel();
            _stopwatchTimer?.cancel();
            
            return ResultsPage(
              score: _correctAnswersCount,
              accuracy: accuracy,
              streak: _calculateStreak(),
              language: widget.language,
              category: widget.category,
              stageName: widget.stageName,
              stageData: {
                ...widget.stageData,
                'totalQuestions': _totalQuestions,
                'maxScore': _questions.fold(0, (sum, question) {
                  if (question['type'] == 'Multiple Choice') {
                    return sum + 1;
                  } else if (question['type'] == 'Fill in the Blanks') {
                    return sum + (question['answer'] as List).length;
                  } else if (question['type'] == 'Identification') {
                    return sum + 1;
                  } else if (question['type'] == 'Matching Type') {
                    return sum + (question['answerPairs'] as List).length;
                  } else {
                    return sum;
                  }
                }),
              },
              mode: widget.mode,
              gamemode: widget.gamemode,
              fullyCorrectAnswersCount: _fullyCorrectAnswersCount,
              answeredQuestions: _answeredQuestions,
              record: _stopwatchTime,
              isGameOver: _isGameOver,
              averageTimePerQuestion: _averageTimePerQuestion,
            );
          },
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
      
      // Update questions answered and total time for arcade mode
      if (widget.gamemode == 'arcade') {
        _questionsAnswered++;
        _totalTimeInSeconds = _stopwatchSeconds;
        _averageTimePerQuestion = _totalTimeInSeconds / _questionsAnswered;
      }

      if (index == null) {
        _wrongAnswersCount++;
        _currentStreak = 0; // Reset the current streak
      } else if (_isCorrect == true) {
        _correctAnswersCount++;
        _fullyCorrectAnswersCount++; // Increment fully correct answers count
        _currentStreak++; // Increment the current streak
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak; // Update the highest streak
        }
        if (widget.gamemode == 'arcade') {
          _stopwatchSeconds -= 10; // Deduct 10 seconds for correct answer
          if (_stopwatchSeconds < 0) _stopwatchSeconds = 0; // Ensure stopwatch doesn't go below 0
          _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds); // Update the stopwatch time immediately
        }
      } else {
        _wrongAnswersCount++;
        _currentStreak = 0; // Reset the current streak
        if (widget.gamemode == 'arcade') {
          _stopwatchSeconds += 10; // Add 10 seconds for wrong answer
          _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds); // Update the stopwatch time immediately
        }
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
      
      // Update questions answered and total time for arcade mode
      if (widget.gamemode == 'arcade') {
        _questionsAnswered++;
        _totalTimeInSeconds = _stopwatchSeconds;
        _averageTimePerQuestion = _totalTimeInSeconds / _questionsAnswered;
      }

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
    
    // Update questions answered and total time for arcade mode
    if (widget.gamemode == 'arcade') {
      _questionsAnswered++;
      _totalTimeInSeconds = _stopwatchSeconds;
      _averageTimePerQuestion = _totalTimeInSeconds / _questionsAnswered;
    }

    if (_isCorrect == true) {
      _correctAnswersCount++;
      _fullyCorrectAnswersCount++; // Increment fully correct answers count
      _currentStreak++; // Increment the current streak
      if (_currentStreak > _highestStreak) {
        _highestStreak = _currentStreak; // Update the highest streak
      }
      if (widget.gamemode == 'arcade') {
        _stopwatchSeconds -= 10; // Deduct 10 seconds for correct answer
        if (_stopwatchSeconds < 0) _stopwatchSeconds = 0; // Ensure stopwatch doesn't go below 0
        _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds); // Update the stopwatch time immediately
      }
    } else {
      _wrongAnswersCount++;
      _currentStreak = 0; // Reset the current streak
      if (widget.gamemode == 'arcade') {
        _stopwatchSeconds += 10; // Add 10 seconds for wrong answer
        _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds); // Update the stopwatch time immediately
      }
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
  }
  
  void _handleVisualDisplayComplete() {
    Future.delayed(const Duration(seconds: 3), () {
      _nextQuestion();
    });
  }

    void _handleFitBVisualDisplayComplete() {
    Future.delayed(const Duration(seconds: 3), () {
      _nextQuestion();
    });
  }

  void _updateHealth(bool isCorrect, String questionType, {int blankPairs = 0, String difficulty = 'normal'}) {
    if (widget.gamemode == 'arcade') return; // Skip health update for arcade mode
  
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

  void _updateStopwatch(int seconds) {
    setState(() {
      _stopwatchSeconds += seconds;
      if (_stopwatchSeconds < 0) _stopwatchSeconds = 0; // Ensure stopwatch doesn't go below 0
      _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds); // Update the stopwatch time immediately
    });
  }

  Future<void> handleQuitGame() async {
    print('🎮 Starting handleQuitGame');
  
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Store context in local variable to ensure type safety
    final BuildContext currentContext = context;

    Map<String, dynamic> gameState = {
      'completed': false,
      'score': _correctAnswersCount,
      'accuracy': _correctAnswersCount / (_correctAnswersCount + _wrongAnswersCount),
      'streak': _calculateStreak(),
      'answeredQuestions': _answeredQuestions,
      'currentQuestionIndex': _currentQuestionIndex,
      'totalQuestions': _totalQuestions,
      'fullyCorrectAnswersCount': _fullyCorrectAnswersCount,
      'questions': _questions,
      'gamemode': widget.gamemode,
    };

    // Add gamemode-specific data
    if (widget.gamemode == 'arcade') {
      gameState['stopwatchTime'] = _stopwatchTime;
      gameState['averageTimePerQuestion'] = _averageTimePerQuestion;
      gameState['questionsAnswered'] = _questionsAnswered;
    } else {
      gameState['hp'] = _hp;
    }

    await _authService.handleGameQuit(
      userId: user.uid,
      categoryId: widget.category['id'],
      stageName: widget.stageName,
      mode: widget.mode.toLowerCase(),
      gamemode: widget.gamemode,
      gameState: gameState,
      onCleanup: () {
        // Cleanup logic
        _timer?.cancel();
        _timer = null;
        _stopwatchTimer?.cancel();
        _stopwatchTimer = null;
        flutterTts.stop();
        flutterTts.pause();
        _audioPlayer.pause();
        _audioPlayer.stop();
        _audioPlayer.dispose();
      },
      navigateBack: (BuildContext context) {
        if (widget.gamemode == 'arcade') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ArcadeStagesPage(
                category: {
                  'id': widget.category['id'],
                  'name': widget.category['name'],
                },
                selectedLanguage: widget.language,
                questName: widget.category['name'],
                savedGameDocId: '${widget.category['id']}_${widget.stageName}_${widget.mode.toLowerCase()}',
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StagesPage(
                questName: widget.category['name'],
                category: {
                  'id': widget.category['id'],
                  'name': widget.category['name'],
                },
                selectedLanguage: widget.language,
                savedGameDocId: '${widget.category['id']}_${widget.stageName}_${widget.mode.toLowerCase()}',
              ),
            ),
          );
        }
      },
      context: currentContext,
    );
  }

  void _loadSavedGameOrInitialize() {
    final savedGame = widget.stageData['savedGame'];
    if (savedGame != null) {
      setState(() {
        _questions = List<Map<String, dynamic>>.from(savedGame['questions'] ?? []);
        _currentQuestionIndex = savedGame['currentQuestionIndex'];
        
        // Check if the current question was answered
        final answeredQuestions = List<Map<String, dynamic>>.from(savedGame['answeredQuestions']);
        if (answeredQuestions.isNotEmpty) {
          // Compare the current question with the last answered question
          final lastAnsweredQuestion = answeredQuestions.last;
          final currentQuestion = _questions[_currentQuestionIndex];
          
          // If this question was already answered, move to the next one
          if (lastAnsweredQuestion['question'] == currentQuestion['question']) {
            // Only increment if not at the last question
            if (_currentQuestionIndex < _questions.length - 1) {
              _currentQuestionIndex++;
            }
          }
        }
        
        // Rest of the initialization code...
      });
    } else {
      _initializeQuestions();
    }
  }

  int _convertTimeToSeconds(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _saveGameState() async {
    print('🎮 Starting _saveGameState');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Don't save if this is the last question and it's been answered
        if (_currentQuestionIndex >= _totalQuestions - 1 && 
            _answeredQuestions.length >= _totalQuestions) {
          print('🎮 Last question answered - not saving game state');
          return;
        }

        Map<String, dynamic> gameState = {
          'completed': false,
          'score': _correctAnswersCount,
          'accuracy': _correctAnswersCount / (_correctAnswersCount + _wrongAnswersCount),
          'streak': _calculateStreak(),
          'answeredQuestions': _answeredQuestions,
          'currentQuestionIndex': _currentQuestionIndex,
          'totalQuestions': _totalQuestions,
          'fullyCorrectAnswersCount': _fullyCorrectAnswersCount,
          'questions': _questions,
          'gamemode': widget.gamemode,
        };

        // Add gamemode-specific data
        if (widget.gamemode == 'arcade') {
          gameState['stopwatchTime'] = _stopwatchTime;
          gameState['averageTimePerQuestion'] = _averageTimePerQuestion;
          gameState['questionsAnswered'] = _questionsAnswered;
        } else {
          gameState['hp'] = _hp;
        }

        await _authService.saveGameState(
          userId: user.uid,
          categoryId: widget.category['id'],
          stageName: widget.stageName,
          mode: widget.mode.toLowerCase(),
          gamemode: widget.gamemode,
          gameState: gameState,
        );
        print('🎮 Game state saved');
      }
    } catch (e) {
      print('❌ Error saving game state: $e');
    }
  }

   @override
  Widget build(BuildContext context) {
    if (_isLoading || !_bgMusicLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF5E31AD), // Same background color as GameplayPage
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
          sfxVolume: _sfxVolume, // Pass the SFX volume
          gamemode: widget.gamemode,
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
          onVisualDisplayComplete: _handleFitBVisualDisplayComplete, // Add this callback
          sfxVolume: _sfxVolume, // Pass the SFX volume
          gamemode: widget.gamemode,
          updateHealth: _updateHealth, // Pass the updateHealth method
          updateStopwatch: _updateStopwatch, // Pass the updateStopwatch method
        );
        break;
      case 'Matching Type':
        questionWidget = MatchingTypeQuestion(
          key: _matchingTypeQuestionKey, // Use the global key to access the state
          questionData: currentQuestion,
          onOptionsShown: _startMatchingTimer, // Start the timer when options are shown
          onAnswerChecked: _handleMatchingTypeAnswerSubmission, // Use the new method
          onVisualDisplayComplete: _handleVisualDisplayComplete, // Add this line
          sfxVolume: _sfxVolume, // Pass the SFX volume
          gamemode: widget.gamemode,
          updateHealth: _updateHealth, // Pass the updateHealth method
          updateStopwatch: _updateStopwatch, // Pass the updateStopwatch method
        );
        break;
      case 'Identification':
        questionWidget = IdentificationQuestion(
          key: _identificationQuestionKey, // Use the global key to access the state
          questionData: currentQuestion,
          controller: _controller,
          onAnswerSubmitted: _handleIdentificationAnswerSubmission,
          onOptionsShown: _startTimer, // Pass the callback to start the timer
          sfxVolume: _sfxVolume, // Pass the SFX volume
          gamemode: widget.gamemode,
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
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white),
                              onPressed: () async {
                                List<Map<String, String>> availableVoices = widget.language == 'fil'
                                    ? [
                                        {"name": _maleVoiceFil, "locale": "fil-PH"},
                                        {"name": _femaleVoiceFil, "locale": "fil-PH"}
                                      ]
                                    : [
                                        {"name": _maleVoiceEn, "locale": "en-US"},
                                        {"name": _femaleVoiceEn, "locale": "en-US"}
                                      ];
  
                                // Ensure the selectedVoice is valid for the current language
                                if (!availableVoices.any((voice) => voice['name'] == _selectedVoice)) {
                                  setState(() {
                                    _selectedVoice = availableVoices.first['name']!;
                                  });
                                }
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return SettingsDialog(
                                      flutterTts: flutterTts, // Pass the flutterTts instance
                                      isTextToSpeechEnabled: _isTextToSpeechEnabled,
                                      onTextToSpeechChanged: (bool value) {
                                        setState(() {
                                          _isTextToSpeechEnabled = value;
                                        });
                                        if (value) {
                                          String locale = widget.language == 'fil' ? 'fil-PH' : 'en-US';
                                          flutterTts.setLanguage(locale);
                                          flutterTts.setVoice({"name": _selectedVoice, "locale": locale});
                                          flutterTts.setSpeechRate(_speechRate);
                                          flutterTts.setVolume(_ttsVolume);
                                        }
                                      },
                                      selectedVoice: _selectedVoice,
                                      onVoiceChanged: (String? newValue) {
                                        setState(() {
                                          _selectedVoice = newValue!;
                                        });
                                        String locale = widget.language == 'fil' ? 'fil-PH' : 'en-US';
                                        flutterTts.setVoice({"name": newValue!, "locale": locale});
                                      },
                                      speed: _speechRate, // Use the state variable
                                      onSpeedChanged: (double value) {
                                        setState(() {
                                          _speechRate = value;
                                        });
                                        flutterTts.setSpeechRate(value);
                                      },
                                      ttsVolume: _ttsVolume, // Use the state variable
                                      onTtsVolumeChanged: (double value) {
                                        setState(() {
                                          _ttsVolume = value;
                                        });
                                        flutterTts.setVolume(value);
                                      },
                                      availableVoices: availableVoices,
                                      musicVolume: _musicVolume, // Use the state variable
                                      onMusicVolumeChanged: (double value) {
                                        setState(() {
                                          _musicVolume = value;
                                        });
                                        _audioPlayer.setVolume(value);
                                      },
                                      sfxVolume: _sfxVolume, // Use the state variable
                                      onSfxVolumeChanged: (double value) {
                                        setState(() {
                                          _sfxVolume = value;
                                        });
                                      },
                                      onQuitGame: handleQuitGame, // Pass the handleQuitGame method directly
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true, // Always show the scrollbar thumb
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50.0),
                              child: questionWidget,
                            ),
                          ),
                        ),
                      ),
                      if (widget.gamemode == 'arcade')
                        Text(
                          _stopwatchTime,
                          style: GoogleFonts.vt323(fontSize: 32, color: Colors.white),
                        ),
                      if (widget.gamemode != 'arcade') HPBar(hp: _hp), // Add the HP bar at the bottom only if not in arcade mode
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