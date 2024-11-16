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
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
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

          return ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                      'Stage $stageNumber',
                      style: GoogleFonts.vt323(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      stageData['stageDescription'] ?? '',
                      style: GoogleFonts.vt323(
                      fontSize: 36,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add horizontal spacing
                          child: SvgPicture.string(
                            '''
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              width="36"
                              height="36"
                              viewBox="0 0 12 11"
                            >
                              <path
                                d="M5 0H7V1H8V3H11V4H12V6H11V7H10V10H9V11H7V10H5V11H3V10H2V7H1V6H0V4H1V3H4V1H5V0Z"
                                fill="${stars > index ? '#F1B33A' : '#453958'}"
                              />
                            </svg>
                            ''',
                            width: 36,
                            height: 36,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: Text(
                        'Personal Best: $personalBest / $maxScore', // Use maxScore instead of numberOfQuestions
                        style: GoogleFonts.vt323(
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (snapshot.hasData && snapshot.data != null) ...[
                      const SizedBox(height: 20),
                      Builder(
                        builder: (context) {
                          final savedState = GameState.fromJson(snapshot.data!);
                          if (!savedState.completed && !savedState.isGameOver) {
                            return ElevatedButton(
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
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF32C067),
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Text(
                                'Resume Game',
                                style: GoogleFonts.vt323(fontSize: 24),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF351B61), // Set the background color to #351b61
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // Set sharp corners
                        ),
                      ),
                      child: Text(
                        StageDialogLocalization.translate('play_now', selectedLanguage), // Use localization
                        style: GoogleFonts.vt323(
                          fontSize: 24,
                        ),
                      ),
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