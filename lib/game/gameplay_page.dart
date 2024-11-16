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
import '../services/game_save_manager.dart';
import '../models/game_state.dart';

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
  int currentQuestionIndex = 0;
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

  final GameSaveManager _gameSaveManager = GameSaveManager();

  // Internal save state question index
  int saveStateQuestionIndex = 0;

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

    // Cleanup TTS and audio
    Future.microtask(() async {
      try {
        await flutterTts.stop();
        await flutterTts.pause();
        await _audioPlayer.pause();
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(0);
        await _audioPlayer.dispose();
      } catch (e) {
        print('❌ Error disposing audio: $e');
      }
    });

    // Auto-save if needed
    if (_shouldSaveGame()) {
      autoSaveGame();
    }

    super.dispose();
  }

void readCurrentQuestion() {
  if (_isTextToSpeechEnabled) {
    if (currentQuestionIndex < _questions.length) {
      Map<String, dynamic> currentQuestion = _questions[currentQuestionIndex];
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
    Map<String, dynamic> currentQuestion = _questions[currentQuestionIndex];
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
    } else if (currentQuestionIndex < _totalQuestions - 1) {
      autoSaveGame(); // Save after completing a question
      setState(() {
        currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isCorrect = null;
        _controller.clear();
        _progress = 1.0;
      });

      // Save again after state update
      autoSaveGame();

      if (widget.gamemode != 'arcade') {
        Future.delayed(const Duration(seconds: 5), () {
          _startTimer();
        });
      } else {
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
    _timer?.cancel();
    setState(() {
      _selectedOptionIndex = index;
      _isCorrect = isCorrect;
      
      // Update arcade stats
      if (widget.gamemode == 'arcade') {
        _questionsAnswered++;
        _totalTimeInSeconds = _stopwatchSeconds;
        _averageTimePerQuestion = _totalTimeInSeconds / _questionsAnswered;
      }

      // Update scores and streaks
      if (index == null) {
        _wrongAnswersCount++;
        _currentStreak = 0;
      } else if (_isCorrect == true) {
        _correctAnswersCount++;
        _fullyCorrectAnswersCount++;
        _currentStreak++;
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak;
        }
        // Handle arcade time
        if (widget.gamemode == 'arcade') {
          _stopwatchSeconds -= 10;
          if (_stopwatchSeconds < 0) _stopwatchSeconds = 0;
          _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds);
        }
      } else {
        _wrongAnswersCount++;
        _currentStreak = 0;
        // Handle arcade time
        if (widget.gamemode == 'arcade') {
          _stopwatchSeconds += 10;
          _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds);
        }
      }
    });

    // Increment save state index after answer
    saveStateQuestionIndex = currentQuestionIndex + 1;
    
    // Save with incremented index
    autoSaveGame();

    // Update health after delay
    Future.delayed(const Duration(seconds: 1), () {
      _updateHealth(isCorrect, 'Multiple Choice');
    });

    // Move to next question after delay
    Future.delayed(const Duration(seconds: 6), () {
      _nextQuestion();
    });
  }

  void _handleFillInTheBlanksAnswerSubmission(Map<String, dynamic> answerData) {
    _timer?.cancel();
    setState(() {
      _answeredQuestions.add({
        'question': _questions[currentQuestionIndex]['question'],
        'correctAnswer': answerData['correctAnswer'],
        'isCorrect': answerData['isCorrect'],
        'type': 'Fill in the Blanks',
      });
      
      // Update stats
      _correctAnswersCount += (answerData['correctCount'] as int);
      _wrongAnswersCount += (answerData['wrongCount'] as int);
      if (answerData['isFullyCorrect'] as bool) {
        _fullyCorrectAnswersCount++;
        _currentStreak++;
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak;
        }
      } else {
        _currentStreak = 0;
      }
    });
  }
  
void _handleIdentificationAnswerSubmission(String answer, bool isCorrect) {
    _timer?.cancel();
    Map<String, dynamic> currentQuestion = _questions[currentQuestionIndex];
    
    _answeredQuestions.add({
    'question': currentQuestion['question'],
    'options': [],
    'correctAnswer': currentQuestion['answer'],
    'isCorrect': isCorrect,
    'type': 'Identification',
    });

  setState(() {
    _isCorrect = isCorrect;
    
    // Update arcade stats
    if (widget.gamemode == 'arcade') {
      _questionsAnswered++;
      _totalTimeInSeconds = _stopwatchSeconds;
      _averageTimePerQuestion = _totalTimeInSeconds / _questionsAnswered;
    }

    // Update scores and streaks
    if (_isCorrect == true) {
      _correctAnswersCount++;
      _fullyCorrectAnswersCount++;
      _currentStreak++;
      if (_currentStreak > _highestStreak) {
        _highestStreak = _currentStreak;
      }
      // Handle arcade time
      if (widget.gamemode == 'arcade') {
        _stopwatchSeconds -= 10;
        if (_stopwatchSeconds < 0) _stopwatchSeconds = 0;
        _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds);
      }
    } else {
      _wrongAnswersCount++;
      _currentStreak = 0;
      // Handle arcade time
      if (widget.gamemode == 'arcade') {
        _stopwatchSeconds += 10;
        _stopwatchTime = _formatStopwatchTime(_stopwatchSeconds);
      }
    }
  });

  // Increment save state index after answer
  saveStateQuestionIndex = currentQuestionIndex + 1;

  // Save right after answer submission
  autoSaveGame();

  // Update health
  _updateHealth(isCorrect, 'Identification');

  // Move to next question after delay
  Future.delayed(const Duration(seconds: 6), () {
    _nextQuestion();
  });
}
  
  void _handleMatchingTypeAnswerSubmission() {
    _timer?.cancel();
    setState(() {
      _correctAnswersCount += _matchingTypeQuestionKey.currentState?.correctPairCount ?? 0;
      _wrongAnswersCount += _matchingTypeQuestionKey.currentState?.incorrectPairCount ?? 0;
      
      bool isFullyCorrect = _matchingTypeQuestionKey.currentState?.areAllPairsCorrect() ?? false;
      if (isFullyCorrect) {
        _fullyCorrectAnswersCount++;
        _currentStreak++;
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak;
        }
      } else {
        _currentStreak = 0;
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
    try {
      if (!_shouldSaveGame()) {
        _cleanup();
        _navigateBack();
        return;
      }

      await _gameSaveManager.handleGameQuit(
        state: _createGameState(),
        onCleanup: _cleanup,
        navigateBack: (BuildContext ctx) => _navigateBack(),
        context: context,
      );
    } catch (e) {
      print('❌ Error handling game quit: $e');
      _cleanup();
      _navigateBack();
    }
  }

  Future<void> _loadSavedGameOrInitialize() async {
    try {
      final savedGame = widget.stageData['savedGame'];
      if (savedGame != null) {
        final savedGameState = GameState.fromJson(savedGame);
        setState(() {
          _questions = savedGameState.questions;
          currentQuestionIndex = savedGameState.currentQuestionIndex;
          saveStateQuestionIndex = savedGameState.currentQuestionIndex;
          _correctAnswersCount = savedGameState.correctAnswers;
          _wrongAnswersCount = savedGameState.wrongAnswers;
          _currentStreak = savedGameState.currentStreak;
          _highestStreak = savedGameState.highestStreak;
          _hp = savedGameState.hp;
          _isGameOver = savedGameState.isGameOver;
          _answeredQuestions = savedGameState.answeredQuestions;
          _totalQuestions = savedGameState.questions.length;
          
          if (widget.gamemode == 'arcade') {
            _stopwatchTime = savedGameState.stopwatchTime ?? '00:00';
            _questionsAnswered = savedGameState.questionsAnswered ?? 0;
            _averageTimePerQuestion = savedGameState.averageTimePerQuestion ?? 0.0;
          }
        });
        _isLoading = false;
      } else {
        _initializeQuestions();
      }
    } catch (e) {
      print('❌ Error loading saved game: $e');
      _initializeQuestions();
    }
  }

  GameState _createGameState() => GameState(
    categoryId: widget.category['id'],
    stageId: widget.stageName,
    mode: widget.mode,
    gamemode: widget.gamemode,
    currentQuestionIndex: saveStateQuestionIndex,
    questions: _questions,
    answeredQuestions: _answeredQuestions,
    score: _correctAnswersCount,
    correctAnswers: _correctAnswersCount,
    wrongAnswers: _wrongAnswersCount,
    currentStreak: _currentStreak,
    highestStreak: _highestStreak,
    hp: _hp,
    isGameOver: _isGameOver,
    stopwatchTime: widget.gamemode == 'arcade' ? _stopwatchTime : null,
    averageTimePerQuestion: widget.gamemode == 'arcade' ? _averageTimePerQuestion : null,
    questionsAnswered: widget.gamemode == 'arcade' ? _questionsAnswered : null,
    completed: false,
    lastSaved: DateTime.now(),
  );

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
  
    Map<String, dynamic> currentQuestion = _questions[currentQuestionIndex];
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
          currentQuestionIndex: currentQuestionIndex, // Pass the current question index
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
          currentQuestionIndex: currentQuestionIndex, // Pass the current question index
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
                              '${currentQuestionIndex + 1} of $_totalQuestions',
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
                                      isLastQuestion: _isLastAnsweredQuestion(),
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

  // Move the helper methods inside the class
  bool _hasAnsweredQuestions() {
    return _answeredQuestions.isNotEmpty;
  }

  bool _isFirstUnansweredQuestion() {
    return currentQuestionIndex == 0 && !_hasAnsweredQuestions();
  }

  bool _isLastAnsweredQuestion() {
    return currentQuestionIndex >= _totalQuestions - 1 && 
           _answeredQuestions.length >= _totalQuestions;
  }

  double _calculateAccuracy() {
    int totalAnswers = _correctAnswersCount + _wrongAnswersCount;
    return totalAnswers > 0 ? _correctAnswersCount / totalAnswers : 0.0;
  }

  void _cleanup() {
    _timer?.cancel();
    _timer = null;
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
    flutterTts.stop();
    flutterTts.pause();
    _audioPlayer.pause();
    _audioPlayer.stop();
    _audioPlayer.dispose();
  }

  void _navigateBack() {
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
          ),
        ),
      );
    }
  }

  bool _shouldSaveGame() {
    // Don't save if:
    if (widget.gamemode == 'arcade') return false;  // Arcade mode
    if (_isFirstUnansweredQuestion()) return false; // First question
    if (_isGameOver) return false;                 // Game over
    if (_isNavigatingToResults()) return false;    // Going to results

    // Save if:
    return true; // Normal gameplay progress
  }

  bool _isNavigatingToResults() {
    final route = ModalRoute.of(context);
    return route?.settings.name?.contains('ResultsPage') ?? false;
  }

  void autoSaveGame() async {
    if (!_shouldSaveGame()) return;
    
    try {
      await _gameSaveManager.saveGameState(
        state: _createGameState(),
      );
      print('✅ Auto-saved game state');
    } catch (e) {
      print('❌ Error auto-saving: $e');
    }
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