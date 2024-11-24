import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/game/prerequisite/prerequisite_page.dart';
import 'package:handabatamae/localization/stages/localization.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/models/game_state.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/services/game_save_manager.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/constants/breakpoints.dart';

void showStageDialog(
  BuildContext context,
  int stageNumber,
  Map<String, String> category,
  int maxScore,
  Map<String, dynamic> stageData,
  String mode,
  int personalBest,
  int stars,
  String selectedLanguage,
  StageService stageService,
) {
  print('\n🎮 Opening Stage Dialog');
  print('📋 Stage: $stageNumber');
  print('🎯 Category: ${category['id']}');
  print('🌍 Language: $selectedLanguage');
  
  stageService.debugCacheState();
  
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, anim1, anim2) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: _getSavedGameState(
          category['id']!,
          stageNumber,
          mode
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ Error loading saved game state: ${snapshot.error}');
          }

          return ResponsiveBuilder(
            breakpoints: AppBreakpoints.screenBreakpoints,
            builder: (context, sizingInformation) {
              // Get responsive dimensions
              final dialogWidth = ResponsiveUtils.valueByDevice<double>(
                context: context,
                mobile: MediaQuery.of(context).size.width * 0.9,
                tablet: 450,
                desktop: 500,
              );

              final titleFontSize = ResponsiveUtils.valueByDevice<double>(
                context: context,
                mobile: 36,
                tablet: 42,
                desktop: 48,
              );

              final descriptionFontSize = ResponsiveUtils.valueByDevice<double>(
                context: context,
                mobile: 24,
                tablet: 30,
                desktop: 36,
              );

              final statsFontSize = ResponsiveUtils.valueByDevice<double>(
                context: context,
                mobile: 18,
                tablet: 20,
                desktop: 24,
              );

              final buttonHeight = ResponsiveUtils.valueByDevice<double>(
                context: context,
                mobile: 45,
                tablet: 60,
                desktop: 50,
              );

              final buttonWidth = ResponsiveUtils.valueByDevice<double>(
                context: context,
                mobile: 180,
                tablet: 200,
                desktop: 200,
              );

              final contentPadding = ResponsiveUtils.valueByDevice<double>(
                context: context,
                mobile: 16,
                tablet: 20,
                desktop: 20,
              );

              return ScaleTransition(
                scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: anim1, curve: Curves.linear),
                ),
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  child: Container(
                    width: dialogWidth,
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            'Stage $stageNumber',
                            style: GoogleFonts.vt323(
                              fontSize: titleFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: contentPadding),
                        Text(
                          stageData['stageDescription'] ?? '',
                          style: GoogleFonts.vt323(
                            fontSize: descriptionFontSize,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: contentPadding),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: contentPadding * 0.4,
                              ),
                              child: SvgPicture.string(
                                '''
                                <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 12 11">
                                  <path d="M5 0H7V1H8V3H11V4H12V6H11V7H10V10H9V11H7V10H5V11H3V10H2V7H1V6H0V4H1V3H4V1H5V0Z"
                                    fill="${stars > index ? '#F1B33A' : '#453958'}"/>
                                </svg>
                                ''',
                                width: 36,
                                height: 36,
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: contentPadding),
                        Flexible(
                          child: Text(
                            'Personal Best: $personalBest / $maxScore',
                            style: GoogleFonts.vt323(
                              fontSize: statsFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: contentPadding * 1.5),
                        if (snapshot.hasData && snapshot.data != null) ...[
                          SizedBox(height: contentPadding),
                          _buildResumeButton(
                            context,
                            snapshot.data!,
                            buttonWidth,
                            buttonHeight,
                            statsFontSize,
                            category,
                            stageNumber,
                            mode,
                            stageData,
                            selectedLanguage,
                            stageService,
                          ),
                        ],
                        SizedBox(height: contentPadding),
                        _buildPlayButton(
                          context,
                          buttonWidth,
                          buttonHeight,
                          statsFontSize,
                          category,
                          stageNumber,
                          mode,
                          stageData,
                          maxScore,
                          stars,
                          selectedLanguage,
                          stageService,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _buildResumeButton(
  BuildContext context,
  Map<String, dynamic> savedData,
  double width,
  double height,
  double fontSize,
  Map<String, String> category,
  int stageNumber,
  String mode,
  Map<String, dynamic> stageData,
  String selectedLanguage,
  StageService stageService,
) {
  final savedState = GameState.fromJson(savedData);
  if (!savedState.completed && !savedState.isGameOver) {
    return Button3D(
      width: width,
      height: height,
      backgroundColor: const Color(0xFF32C067),
      borderColor: const Color(0xFF28A757),
      onPressed: () async {
        try {
          await _handleOfflineStageStart(
            category['id']!, 
            stageNumber,
            mode,
            stageService
          );
          
          if (context.mounted) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => GameplayPage(
                  language: selectedLanguage,
                  category: {
                    'id': category['id'],
                    'name': category['name'],
                  },
                  stageName: 'Stage $stageNumber',
                  stageData: {
                    ...stageData,
                    'savedGame': savedState.toJson(),
                  },
                  mode: mode,
                  gamemode: 'adventure',
                ),
              ),
            );
          }
        } catch (e) {
          print('❌ Error resuming game: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to resume game: $e')),
            );
          }
        }
      },
      child: Text(
        'Resume Game',
        style: GoogleFonts.vt323(
          fontSize: fontSize,
          color: Colors.white,
        ),
      ),
    );
  }
  return const SizedBox.shrink();
}

Widget _buildPlayButton(
  BuildContext context,
  double width,
  double height,
  double fontSize,
  Map<String, String> category,
  int stageNumber,
  String mode,
  Map<String, dynamic> stageData,
  int maxScore,
  int stars,
  String selectedLanguage,
  StageService stageService,
) {
  return Button3D(
    width: width,
    height: height,
    backgroundColor: const Color(0xFF351B61),
    borderColor: const Color(0xFF1A0D30),
    onPressed: () async {
      try {
        // Delete any existing saves first
        final gameSaveManager = GameSaveManager();
        await gameSaveManager.deleteSavedGame(
          categoryId: category['id']!,
          stageName: 'Stage $stageNumber',
          mode: mode,
        );
        print('🧹 Cleaned up existing saves before starting new game');

        await _handleOfflineStageStart(
          category['id']!, 
          stageNumber,
          mode,
          stageService
        );

        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PrerequisitePage(
              language: selectedLanguage,
              category: category,
              stageName: 'Stage $stageNumber',
              stageData: stageData,
              mode: mode,
              gamemode: 'adventure',
              personalBest: 0,
              crntRecord: -1,
              maxScore: maxScore,
              stars: stars,
            ),
          ),
        );
      } catch (e) {
        print('❌ Error starting new game: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start game: $e')),
          );
        }
      }
    },
    child: Text(
      StageDialogLocalization.translate('play_now', selectedLanguage),
      style: GoogleFonts.vt323(
        fontSize: fontSize,
        color: Colors.white,
      ),
    ),
  );
}

Future<Map<String, dynamic>?> _getSavedGameState(
  String categoryId,
  int stageNumber,
  String mode
) async {
  try {
    final stageName = 'Stage $stageNumber';
    
    final gameSaveManager = GameSaveManager();
    final savedState = await gameSaveManager.getSavedGameState(
      categoryId: categoryId,
      stageName: stageName,
      mode: mode,
    );

    if (savedState != null) {
      return savedState.toJson();
    }
    return null;
  } catch (e) {
    print('❌ Error getting saved game state: $e');
    return null;
  }
}

Future<void> _handleOfflineStageStart(
  String categoryId, 
  int stageNumber,
  String mode,
  StageService stageService
) async {
  try {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      await stageService.addOfflineChange('stage_start', {
        'categoryId': categoryId,
        'stageKey': GameSaveData.getStageKey(categoryId, stageNumber),
        'mode': mode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('📱 Added offline change for stage start');
    }
  } catch (e) {
    print('❌ Error handling offline start: $e');
    throw GameSaveDataException('Failed to handle offline start: $e');
  }
}