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
import 'package:responsive_builder/responsive_builder.dart';
import 'package:soundpool/soundpool.dart'; // Import soundpool package
import 'question_widgets.dart';
import 'results_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/badge_unlock_service.dart';
import 'package:handabatamae/services/game_save_manager.dart';
import 'package:handabatamae/localization/results/localization.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/services/leaderboard_service.dart';

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
  int? _soundIdFail;
  int? _soundId1Star;
  int? _soundId2Stars;
  int? _soundId3Stars;
  bool _isInitialized = false;
  bool _isSoundLoaded = false;
  int stars = 0;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeResultsPage();
  }

  Future<void> _initializeResultsPage() async {
    try {

      // Calculate stars first
      stars = _calculateStars(
        widget.accuracy,
        widget.score,
        widget.stageData['maxScore'],
        widget.isGameOver
      );

      // Load sounds first
      await _loadSounds();

      // Run other tasks
      await Future.wait([
        _updateProgress(),
        _cleanupGameSave(),
      ]).catchError((e) {
        return [null, null];
      });

      // Play sound only if loaded successfully
      if (_isSoundLoaded) {
        await Future.delayed(const Duration(milliseconds: 100));
        _playSoundBasedOnStars(stars);
      }

      // Mark as initialized and update UI
      if (mounted) {
        setState(() => _isInitialized = true);
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  Future<void> _loadSounds() async {
    try {
      _soundpool = Soundpool.fromOptions(
        options: const SoundpoolOptions(
          streamType: StreamType.music,
          maxStreams: 4,
        ),
      );

      // Load all sounds in parallel
      final results = await Future.wait([
        _soundpool.load(
          await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_descend_fail_negative.mp3')
        ),
        _soundpool.load(
          await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_001.mp3')
        ),
        _soundpool.load(
          await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_004.mp3')
        ),
        _soundpool.load(
          await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_007.mp3')
        ),
      ]);

      _soundIdFail = results[0];
      _soundId1Star = results[1];
      _soundId2Stars = results[2];
      _soundId3Stars = results[3];
      
      _isSoundLoaded = true;
    } catch (e) {
      _isSoundLoaded = false;
    }
  }

  void _playSoundBasedOnStars(int stars) {
    if (!_isSoundLoaded) return;
    
    try {
      switch (stars) {
        case 0:
          if (_soundIdFail != null) _soundpool.play(_soundIdFail!);
          break;
        case 1:
          if (_soundId1Star != null) _soundpool.play(_soundId1Star!);
          break;
        case 2:
          if (_soundId2Stars != null) _soundpool.play(_soundId2Stars!);
          break;
        case 3:
          if (_soundId3Stars != null) _soundpool.play(_soundId3Stars!);
          break;
      }
    } catch (e) {
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
    // Ensure proper cleanup
    if (_isSoundLoaded) {
      _soundpool.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isInitialized
          ? Container(
              color: const Color(0xFF5E31AD),
              child: const Center(
                child: LoadingWidget(),
              ),
            )
          : ResponsiveBuilder(
              builder: (context, sizingInformation) {
                final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
                
                return Container(
                  color: const Color(0xFF5E31AD),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 80.0,
                            tablet: 125.0,
                          )),
                          buildReactionWidget(stars, widget.language),
                          SizedBox(height: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 16.0,
                            tablet: 20.0,
                          )),
                          if (widget.gamemode == 'arcade')
                            buildStatisticItem(
                              ResultsLocalization.translate('record', widget.language), 
                              widget.record
                            ),
                          if (widget.gamemode != 'arcade')
                            buildStarsWidget(stars),
                          SizedBox(height: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 16.0,
                            tablet: 20.0,
                          )),
                          Text(
                            ResultsLocalization.translate('myPerformance', widget.language),
                            style: GoogleFonts.vt323(
                              fontSize: isTablet ? 36 : 32,
                              color: Colors.white
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 16.0,
                            tablet: 20.0,
                          )),
                          buildStatisticsWidget(
                            widget.score,
                            widget.accuracy,
                            widget.streak,
                            widget.language,
                          ),
                          SizedBox(height: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 40.0,
                            tablet: 50.0,
                          )),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Button3D(
                                onPressed: () async {
                                  // Cleanup sounds before navigation
                                  if (_isSoundLoaded) {
                                    _soundpool.dispose();
                                    _isSoundLoaded = false;
                                  }

                                  if (!mounted) return;

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
                                // width: ResponsiveUtils.valueByDevice(
                                //   context: context,
                                //   mobile: 120.0,
                                //   tablet: 150.0,
                                // ),
                                // height: ResponsiveUtils.valueByDevice(
                                //   context: context,
                                //   mobile: 50.0,
                                //   tablet: 60.0,
                                // ),
                                child: Text(
                                  ResultsLocalization.translate('back', widget.language),
                                  style: GoogleFonts.vt323(
                                    color: Colors.white,
                                    fontSize: isTablet ? 24 : 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.valueByDevice(
                                context: context,
                                mobile: 20.0,
                                tablet: 25.0,
                              )),
                              Button3D(
                                onPressed: () async {
                                  // Cleanup sounds before navigation
                                  if (_isSoundLoaded) {
                                    _soundpool.dispose();
                                    _isSoundLoaded = false;
                                  }

                                  if (!mounted) return;

                                  // Delete any existing saved game first
                                  await _gameSaveManager.deleteSavedGame(
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
                                // width: ResponsiveUtils.valueByDevice(
                                //   context: context,
                                //   mobile: 120.0,
                                //   tablet: 150.0,
                                // ),
                                // height: ResponsiveUtils.valueByDevice(
                                //   context: context,
                                //   mobile: 50.0,
                                //   tablet: 60.0,
                                // ),
                                child: Text(
                                  ResultsLocalization.translate('playAgain', widget.language),
                                  style: GoogleFonts.vt323(
                                    color: Colors.black,
                                    fontSize: isTablet ? 24 : 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 40.0,
                            tablet: 50.0,
                          )),
                          Text(
                            ResultsLocalization.translate('stageQuestions', widget.language),
                            style: GoogleFonts.vt323(
                              fontSize: isTablet ? 36 : 32,
                              color: Colors.white
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 8.0,
                            tablet: 10.0,
                          )),
                          _buildAnsweredQuestionsWidget(context),
                          SizedBox(height: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 40.0,
                            tablet: 50.0,
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnsweredQuestionsWidget(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;
        final refinedSize = sizingInformation.refinedSize;
        
        // Adjust width based on refined size
        double containerWidth;
        if (refinedSize == RefinedSize.small) {
          containerWidth = 0.95; // Smaller phones
        } else if (refinedSize == RefinedSize.normal) {
          containerWidth = 0.90; // Normal phones
        } else if (isTablet) {
          containerWidth = 0.85; // Tablets
        } else {
          containerWidth = 0.88; // Default/larger phones
        }
        
        return SizedBox(
          width: MediaQuery.of(context).size.width * containerWidth,
          child: Column(
            children: widget.answeredQuestions.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> question = entry.value;
              if (question['type'] == 'Multiple Choice') {
                return buildMultipleChoiceQuestionWidget(context, index, question);
              } else if (question['type'] == 'Identification') {
                return buildIdentificationQuestionWidget(context, index, question, widget.language);
              } else if (question['type'] == 'Fill in the Blanks') {
                return buildFillInTheBlanksQuestionWidget(context, index, question);
              } else {
                return buildMatchingTypeQuestionWidget(context, index, question, widget.language);
              }
            }).toList(),
          ),
        );
      },
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
      } else {
        if (saveData != null) {
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
        } else {
        }
      }
    } catch (e) {
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

      // Send only the XP gain to batchUpdateProfile
      await userProfileService.batchUpdateProfile({
        'exp': xpGained,
      });

      // Update game progress
      if (!widget.isGameOver) {
        // First update game progress which handles offline/online automatically
        await _authService.updateGameProgress(
          categoryId: widget.category['id'],
          stageName: widget.stageName,
          score: widget.score,
          stars: stars,
          mode: widget.mode.toLowerCase(),
          record: widget.gamemode == 'arcade' ? _convertRecordToSeconds(widget.record) : null,
          isArcade: widget.gamemode == 'arcade',
        );

        // For arcade mode, queue leaderboard update (will be processed when online)
        if (widget.gamemode == 'arcade') {
          final leaderboardService = LeaderboardService();
          await leaderboardService.queueLeaderboardUpdate(
            widget.category['id'],
            currentProfile.profileId,
            _convertRecordToSeconds(widget.record),
          );
        }

        // Update total stages cleared after game progress is updated
        await userProfileService.updateTotalStagesCleared();

        // Delete saved game state if exists
        await _cleanupGameSave();
      }

      // Check for badge unlocks
      await _checkBadgeUnlocks();

    } catch (e) {
      // Handle errors
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
      }
    } catch (e) {
    }
  }
}