import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/models/user_model.dart';
import 'package:handabatamae/pages/stages_page.dart';
import 'package:handabatamae/pages/arcade_stages_page.dart'; // Import ArcadeStagesPage
import 'package:handabatamae/shared/connection_quality.dart';
import 'package:handabatamae/widgets/loading_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:soundpool/soundpool.dart'; // Import soundpool package
import 'question_widgets.dart';
import 'results_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/badge_unlock_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  late Soundpool _soundpool;
  late int _soundIdFail;
  late int _soundId1Star;
  late int _soundId2Stars;
  late int _soundId3Stars;
  bool _soundsLoaded = false;
  bool _starsCalculated = false;
  int stars = 0;
  int _xpGained = 0;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _deleteSavedGame();
    _soundpool = Soundpool.fromOptions(options: const SoundpoolOptions(streamType: StreamType.music));
    _initializeResultsPage();
  }

  Future<void> _initializeResultsPage() async {
    try {
      print('🎮 Initializing results page...');
      
      // Check connection quality first
      final connectionManager = ConnectionManager();
      final quality = await connectionManager.checkConnectionQuality();
      print('📡 Connection quality: $quality');

      // Load sounds and calculate stars in parallel with timeout
      try {
        await Future.wait([
          _loadSounds().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⚠️ Sound loading timed out, continuing without sounds');
              setState(() => _soundsLoaded = true);
            },
          ),
          _updateScoreAndStarsInFirestore().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⚠️ Score update timed out, will sync later');
              // Calculate stars locally
              setState(() {
                stars = _calculateStars(
                  widget.accuracy,
                  widget.score,
                  widget.stageData['maxScore'],
                  widget.isGameOver
                );
                _starsCalculated = true;
              });
            },
          ),
        ], eagerError: false); // Continue if one operation fails
      } catch (e) {
        print('⚠️ Error in parallel operations: $e');
        // Ensure states are set even if operations fail
        setState(() {
          _soundsLoaded = true;
          _starsCalculated = true;
        });
      }

      // Only play sound if loaded successfully
      if (_soundsLoaded) {
        _playSoundBasedOnStars();
      }

      // Ensure UI updates
      if (mounted) {
        setState(() {
          _starsCalculated = true;
        });
      }

      print('✅ Results page initialization complete');
    } catch (e) {
      print('❌ Error initializing results page: $e');
      // Ensure the page is still usable even if initialization fails
      if (mounted) {
        setState(() {
          _soundsLoaded = true;
          _starsCalculated = true;
        });
      }
    }
  }

  int _calculateStars(double accuracy, int score, int maxScore, bool isGameOver) {
    if (isGameOver) {
      return 0;
    } else if (accuracy > 0.9 && score == maxScore) {
      return 3;
    } else if (score > maxScore / 2) {
      return 2;
    } else {
      return 1;
    }
  }

  int _convertRecordToSeconds(String record) {
    final parts = record.split(':');
    final minutes = int.parse(parts[0]);
    final seconds = int.parse(parts[1]);
    return (minutes * 60) + seconds;
  }

  Future<void> _loadSounds() async {
    _soundIdFail = await _soundpool.load(await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_descend_fail_negative.mp3'));
    _soundId1Star = await _soundpool.load(await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_001.mp3'));
    _soundId2Stars = await _soundpool.load(await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_004.mp3'));
    _soundId3Stars = await _soundpool.load(await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_007.mp3'));
    setState(() {
      _soundsLoaded = true;
    });
  }

  void _playSoundBasedOnStars() {
    int stars = _calculateStars(widget.accuracy, widget.score, widget.stageData['totalQuestions'] ?? 0, widget.isGameOver);
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
  }

  Future<void> _updateScoreAndStarsInFirestore() async {
    try {
      print('🎮 Starting score update process...');
      
      // Get connection quality first
      final connectionManager = ConnectionManager();
      final quality = await connectionManager.checkConnectionQuality();
      print('📡 Connection status: $quality');

      UserProfile? profile = await _authService.getUserProfile();
      if (profile != null) {
        print('👤 Current profile stats:');
        print('📊 Level: ${profile.level}');
        print('📈 EXP: ${profile.exp}/${profile.expCap}');

        // Add gamemode context
        print('🎲 Game Details:');
        print('🎮 Mode: ${widget.gamemode}');
        print('⚔️ Difficulty: ${widget.mode}');
        print('🎯 Score: ${widget.score}');
        print('📊 Accuracy: ${(widget.accuracy * 100).toStringAsFixed(1)}%');

        // Calculate XP and new level
        final updates = _calculateUpdates(profile);
        
        // Handle updates based on connection
        if (quality == ConnectionQuality.OFFLINE) {
          print('📱 Offline mode - Queueing updates');
          // Queue updates for later sync
          await _queueProfileUpdates(updates);
          
          // Update local state immediately
          setState(() {
            stars = _calculateStars(
              widget.accuracy,
              widget.score,
              widget.stageData['maxScore'],
              widget.isGameOver
            );
            _xpGained = updates['xpGained'];
          });
          
          print('💾 Updates queued for later sync');
        } else {
          print('🌐 Online mode - Updating immediately');
          // Existing online update logic
          await _authService.updateUserProfile('exp', updates['newXP']);
          await _authService.updateUserProfile('level', updates['newLevel']);
          await _authService.updateUserProfile('expCap', updates['newExpCap']);
        }

        // Check badges regardless of connection
        await _checkBadgeUnlocks();
      }
    } catch (e) {
      print('❌ Error in score update: $e');
      // Ensure UI still updates
      setState(() {
        stars = _calculateStars(
          widget.accuracy,
          widget.score,
          widget.stageData['maxScore'],
          widget.isGameOver
        );
      });
    }
  }

  // Helper to calculate all updates
  Map<String, dynamic> _calculateUpdates(UserProfile profile) {
    // Calculate XP gained
    int xpGained;
    if (widget.gamemode == 'arcade') {
      xpGained = widget.isGameOver ? 0 : 500;
    } else {
      int multiplier = widget.mode == 'Hard' ? 10 : 5;
      xpGained = widget.score * multiplier;
    }

    // Calculate new stats
    int newXP = profile.exp + xpGained;
    int newLevel = profile.level;
    int requiredXP = profile.level * 100;

    // Handle level ups
    while (newXP >= requiredXP) {
      newXP -= requiredXP;
      newLevel++;
      requiredXP = newLevel * 100;
    }

    return {
      'xpGained': xpGained,
      'newXP': newXP,
      'newLevel': newLevel,
      'newExpCap': newLevel * 100,
    };
  }

  // Helper to queue offline updates
  Future<void> _queueProfileUpdates(Map<String, dynamic> updates) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> pendingUpdates = 
      jsonDecode(prefs.getString('pending_profile_updates') ?? '[]')
        .cast<Map<String, dynamic>>();

    pendingUpdates.add({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'updates': updates,
    });

    await prefs.setString('pending_profile_updates', jsonEncode(pendingUpdates));
  }

  Future<void> _deleteSavedGame() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docId = '${widget.category['id']}_${widget.stageName}_${widget.mode.toLowerCase()}';
        print('🎮 Deleting saved game...');
        
        // Delete from local storage first
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('game_progress_$docId');
        print('🎮 Local saved game deleted');

        // Try to delete from Firebase if online
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult != ConnectivityResult.none) {
          await FirebaseFirestore.instance
              .collection('User')
              .doc(user.uid)
              .collection('GameProgress')
              .doc(docId)
              .delete();
          print('🎮 Firebase saved game deleted');
        }
      }
    } catch (e) {
      print('❌ Error deleting saved game: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (_soundsLoaded && _starsCalculated)
          ? ResponsiveBreakpoints(
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
                            const SizedBox(height: 175),
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
                                ElevatedButton(
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
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: const Color(0xFF351b61),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(0)),
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF1A0D30),
                                      width: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  ),
                                  child: const Text('Back'),
                                ),
                                const SizedBox(width: 25),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GameplayPage(
                                          language: widget.language,
                                          category: widget.category,
                                          stageName: widget.stageName,
                                          stageData: widget.stageData,
                                          mode: widget.mode,
                                          gamemode: widget.gamemode,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: const Color(0xFFF1B33A),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(0)),
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF8B5A00),
                                      width: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  ),
                                  child: const Text('Play Again'),
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
                            if (_xpGained > 0)
                              Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Text(
                                    'XP Gained: $_xpGained',
                                    style: GoogleFonts.vt323(
                                      fontSize: 24,
                                      color: Colors.yellow,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
          ) : Container(
              color: const Color(0xFF5E31AD),
              child: const LoadingWidget(),
            ),
    );
  }

  Widget _buildAnsweredQuestionsWidget(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
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
      final badgeUnlockService = BadgeUnlockService();
      
      // Get local game save data first
      GameSaveData? saveData = await _authService.getLocalGameSaveData(widget.category['id']);
      
      if (widget.gamemode == 'arcade') {
        final recordParts = widget.record.split(':');
        final totalSeconds = (int.parse(recordParts[0]) * 60) + int.parse(recordParts[1]);
        
        await badgeUnlockService.checkArcadeBadges(
          totalTime: totalSeconds,
          accuracy: widget.accuracy * 100,
          streak: widget.streak,
          averageTimePerQuestion: widget.averageTimePerQuestion,
        );
      } else if (saveData != null) {
        List<int> stageStars = widget.mode.toLowerCase() == 'normal' 
            ? saveData.normalStageStars 
            : saveData.hardStageStars;
        
        await badgeUnlockService.checkAdventureBadges(
          questName: widget.category['name'],
          stageName: widget.stageName,
          difficulty: widget.mode.toLowerCase(),
          stars: stars,
          allStageStars: stageStars,
        );
      }
    } catch (e) {
      print('❌ Error checking badge unlocks: $e');
    }
  }
}