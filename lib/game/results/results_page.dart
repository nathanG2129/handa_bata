import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/prerequisite/prerequisite_page.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/stages_page.dart';
import 'package:handabatamae/pages/arcade_stages_page.dart'; // Import ArcadeStagesPage
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/widgets/loading_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:soundpool/soundpool.dart'; // Import soundpool package
import 'question_widgets.dart';
import 'results_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/badge_unlock_service.dart';
import 'package:handabatamae/services/game_save_manager.dart';

class ResultsPage extends StatefulWidget {
  final int score;
  final double accuracy;
  final int streak;
  final String language;
  final Map<String, dynamic> category;
  final String stageName;
  final Map<String, dynamic> stageData;
  final String mode;
  final String gamemode;
  final int fullyCorrectAnswersCount;
  final List<Map<String, dynamic>> answeredQuestions;
  final String record;
  final bool isGameOver;
  final double averageTimePerQuestion;

  const ResultsPage({
    super.key,
    required this.score,
    required this.accuracy,
    required this.streak,
    required this.language,
    required this.category,
    required this.stageName,
    required this.stageData,
    required this.mode,
    required this.gamemode,
    required this.fullyCorrectAnswersCount,
    required this.answeredQuestions,
    required this.record, 
    required this.isGameOver,
    required this.averageTimePerQuestion,
  });

  @override
  ResultsPageState createState() => ResultsPageState();
}

class ResultsPageState extends State<ResultsPage> {
  final GameSaveManager _gameSaveManager = GameSaveManager();
  late Soundpool _soundpool;
  late int _soundIdFail;
  late int _soundId1Star;
  late int _soundId2Stars;
  late int _soundId3Stars;
  bool _isInitialized = false;
  int stars = 0;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeResultsPage();
  }

  Future<void> _initializeResultsPage() async {
    try {
      print('🎮 Starting results page initialization');

      // Calculate stars first
      stars = _calculateStars(
        widget.accuracy,
        widget.score,
        widget.stageData['maxScore'],
        widget.isGameOver
      );

      // Initialize soundpool
      _soundpool = Soundpool.fromOptions(
        options: const SoundpoolOptions(
          streamType: StreamType.music,
          maxStreams: 4,
        ),
      );

      // Load sounds first and ensure they're loaded
      await _loadSounds();
      print('🔊 Sounds loaded successfully');

      // Run other tasks
      await Future.wait([
        _updateProgress(),
        _cleanupGameSave(),
      ]).catchError((e) {
        print('⚠️ Error in initialization tasks: $e');
        return [null, null];
      });

      // Play sound only once and with a slight delay
      await Future.delayed(const Duration(milliseconds: 100));
      _playSoundBasedOnStars(stars);

      // Mark as initialized and update UI
      if (mounted) {
        setState(() => _isInitialized = true);
      }

      print('✅ Results page initialization complete');
    } catch (e) {
      print('❌ Error initializing results page: $e');
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  Future<void> _loadSounds() async {
    try {
      print('🎵 Loading result sounds...');
      _soundIdFail = await _soundpool.load(
        await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_descend_fail_negative.mp3')
      );
      _soundId1Star = await _soundpool.load(
        await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_001.mp3')
      );
      _soundId2Stars = await _soundpool.load(
        await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_004.mp3')
      );
      _soundId3Stars = await _soundpool.load(
        await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_007.mp3')
      );
      print('✅ All sounds loaded successfully');
    } catch (e) {
      print('❌ Error loading sounds: $e');
    }
  }

  void _playSoundBasedOnStars(int stars) {
    try {
      print('🎵 Playing sound for $stars stars');
      switch (stars) {
        case 0:
          _soundpool.play(_soundIdFail);
          break;
        case 1:
          _soundpool.play(_soundId1Star);
          break;
        case 2:
          _soundpool.play(_soundId2Stars);
          break;
        case 3:
          _soundpool.play(_soundId3Stars);
          break;
      }
    } catch (e) {
      print('❌ Error playing sound: $e');
    }
  }

  int _calculateStars(double accuracy, int score, int maxScore, bool isGameOver) {
    // If game is over, return 0 stars
    if (isGameOver) return 0;
    
    // Otherwise calculate stars normally
    double scorePercent = (score / maxScore) * 100;
    
    // Calculate stars based on and score percentage
    if (scorePercent >= 90) return 3;
    if (scorePercent >= 60) return 2;
    if (scorePercent >= 0) return 1;
    return 0;
  }

  int _convertRecordToSeconds(String record) {
    final parts = record.split(':');
    final minutes = int.parse(parts[0]);
    final seconds = int.parse(parts[1]);
    return (minutes * 60) + seconds;
  }

  @override
  void dispose() {
    // Add delay before disposing soundpool
    Future.delayed(const Duration(seconds: 1), () {
      _soundpool.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isInitialized
          ?         Container(
          color: const Color(0xFF5E31AD), // Add purple background color
          child: const Center(
            child: LoadingWidget(),
          ),
        )
          : ResponsiveBreakpoints(
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
                  child: Container(
                    color: const Color(0xFF5E31AD), // Same background color as GameplayPage
                    child: SafeArea(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 125),
                            buildReactionWidget(stars),
                            const SizedBox(height: 20),
                            if (widget.gamemode == 'arcade')
                              buildStatisticItem('Record', widget.record), // Display the record widget if gamemode is arcade
                            if (widget.gamemode != 'arcade')
                              buildStarsWidget(stars), // Display the stars widget if gamemode is not arcade
                            const SizedBox(height: 20),
                            Text(
                              'My Performance',
                              style: GoogleFonts.vt323(fontSize: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            buildStatisticsWidget(
                              widget.score,
                              widget.accuracy,
                              widget.streak,
                            ),
                            const SizedBox(height: 50),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Button3D(
                                  onPressed: () {
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
                                  },
                                  backgroundColor: const Color(0xFF351b61),
                                  borderColor: const Color(0xFF1A0D30),
                                  width: 120,
                                  height: 50,
                                  child: Text(
                                    'Back',
                                    style: GoogleFonts.vt323(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 25),
                                Button3D(
                                  onPressed: () {
                                    // Delete any existing saved game first
                                    _gameSaveManager.deleteSavedGame(
                                      categoryId: widget.category['id'],
                                      stageName: widget.stageName,
                                      mode: widget.mode,
                                    );

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PrerequisitePage(
                                          language: widget.language,
                                          category: widget.category as Map<String, String>,
                                          stageName: widget.stageName,
                                          stageData: widget.stageData,
                                          mode: widget.mode,
                                          gamemode: widget.gamemode,
                                          personalBest: widget.score,
                                          maxScore: widget.stageData['maxScore'],
                                          stars: stars,
                                          crntRecord: widget.gamemode == 'arcade' ? 
                                            _convertRecordToSeconds(widget.record) : -1,
                                        ),
                                      ),
                                    );
                                  },
                                  backgroundColor: const Color(0xFFF1B33A),
                                  borderColor: const Color(0xFF8B5A00),
                                  width: 120,
                                  height: 50,
                                  child: Text(
                                    'Play Again',
                                    style: GoogleFonts.vt323(
                                      color: Colors.black,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 50),
                            Text(
                              'Stage Questions',
                              style: GoogleFonts.vt323(fontSize: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            _buildAnsweredQuestionsWidget(context),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
          ),
    );
  }

  Widget _buildAnsweredQuestionsWidget(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: widget.answeredQuestions.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> question = entry.value;
          if (question['type'] == 'Multiple Choice') {
            return buildMultipleChoiceQuestionWidget(context, index, question);
          } else if (question['type'] == 'Identification') {
            return buildIdentificationQuestionWidget(context, index, question);
          } else if (question['type'] == 'Fill in the Blanks') {
            return buildFillInTheBlanksQuestionWidget(context, index, question);
          } else {
            return buildMatchingTypeQuestionWidget(context, index, question);
          }
        }).toList(),
      ),
    );
  }

  Widget buildRecordWidget(String record) {
    return Column(
      children: [
        Text(
          'Record',
          style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          record,
          style: GoogleFonts.vt323(fontSize: 24, color: Colors.white),
        ),
      ],
    );
  }

  Future<void> _checkBadgeUnlocks() async {
    try {
      print('\n🎮 Checking Badge Unlocks');
      print('Game Mode: ${widget.gamemode}');
      
      final badgeUnlockService = BadgeUnlockService();
      GameSaveData? saveData = await _authService.getLocalGameSaveData(widget.category['id']);
      
      if (widget.gamemode == 'arcade') {
        final recordParts = widget.record.split(':');
        final totalSeconds = (int.parse(recordParts[0]) * 60) + int.parse(recordParts[1]);
        
        print('\n🎯 Arcade Mode Stats:');
        print('Total Time: $totalSeconds seconds');
        print('Accuracy: ${(widget.accuracy * 100).toStringAsFixed(2)}%');
        print('Streak: ${widget.streak}');
        print('Avg Time per Question: ${widget.averageTimePerQuestion.toStringAsFixed(2)} seconds');
        
        await badgeUnlockService.checkArcadeBadges(
          totalTime: totalSeconds,
          accuracy: widget.accuracy * 100,
          streak: widget.streak,
          averageTimePerQuestion: widget.averageTimePerQuestion,
        );
      } else {
        if (saveData != null) {
          List<int> stageStars = widget.mode.toLowerCase() == 'normal' 
              ? saveData.normalStageStars 
              : saveData.hardStageStars;
          
          print('\n🎯 Adventure Mode Stats:');
          print('Quest: ${widget.category['name']}');
          print('Stage: ${widget.stageName}');
          print('Difficulty: ${widget.mode}');
          print('Stars: $stars');
          print('All Stage Stars: $stageStars');
          
          await badgeUnlockService.checkAdventureBadges(
            questName: widget.category['name'],
            stageName: widget.stageName,
            difficulty: widget.mode.toLowerCase(),
            stars: stars,
            allStageStars: stageStars,
          );
        } else {
          print('⚠️ No save data found for badge checks');
        }
      }
      print('\n✅ Badge check completed');
    } catch (e) {
      print('❌ Error checking badge unlocks: $e');
    }
  }

  Future<void> _updateProgress() async {
    try {
      final userProfileService = UserProfileService();
      
      // Get current profile first
      UserProfile? currentProfile = await userProfileService.fetchUserProfile();
      if (currentProfile == null) return;

      // Calculate XP gained based on game mode and performance
      int xpGained;
      if (widget.gamemode == 'arcade') {
        // For arcade mode: 500 XP for completion, 0 for game over
        xpGained = widget.isGameOver ? 0 : 500;
      } else {
        // For adventure mode: score * multiplier (10 for hard, 5 for normal)
        int multiplier = widget.mode.toLowerCase() == 'hard' ? 10 : 5;
        xpGained = widget.score * multiplier;
      }

      print('\n💫 UPDATING PROGRESS');
      print('Game Mode: ${widget.gamemode}');
      print('Score: ${widget.score}');
      print('XP Gained: $xpGained');

      // Send only the XP gain to batchUpdateProfile
      await userProfileService.batchUpdateProfile({
        'exp': xpGained,
      });

      // Update game progress
      if (!widget.isGameOver) {
        await _authService.updateGameProgress(
          categoryId: widget.category['id'],
          stageName: widget.stageName,
          score: widget.score,
          stars: stars,
          mode: widget.mode.toLowerCase(),
          record: widget.gamemode == 'arcade' ? _convertRecordToSeconds(widget.record) : null,
          isArcade: widget.gamemode == 'arcade',
        );

        // Update total stages cleared after game progress is updated
        await userProfileService.updateTotalStagesCleared();

        // Delete saved game state if exists
        await _cleanupGameSave();
      }

      // Check for badge unlocks
      await _checkBadgeUnlocks();

    } catch (e) {
      print('❌ Error updating progress: $e');
    }
  }

  Future<void> _cleanupGameSave() async {
    try {
      // Delete save if:
      // 1. Game is over (HP = 0)
      // 2. Game completed normally (got stars)
      // 3. Arcade mode (no saves needed)
      if (widget.isGameOver || stars > 0 || widget.gamemode == 'arcade') {
        await _gameSaveManager.deleteSavedGame(
          categoryId: widget.category['id'],
          stageName: widget.stageName,
          mode: widget.mode,
        );
        print('🧹 Game save cleaned up - ${widget.isGameOver ? "Game over" : 
              widget.gamemode == "arcade" ? "Arcade mode" : "Stage completed"}');
      }
    } catch (e) {
      print('❌ Error cleaning up game save: $e');
    }
  }
}