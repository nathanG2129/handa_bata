import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/prerequisite/prerequisite_page.dart';
import 'package:handabatamae/localization/stages/localization.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/services/game_save_manager.dart';
import 'package:handabatamae/utils/category_text_utils.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';

String formatTime(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainingSeconds';
}

void showArcadeStageDialog(
  BuildContext context,
  int stageNumber,
  Map<String, String> category,
  Map<String, dynamic> stageData,
  String mode,
  int bestRecord,
  int crntRecord,
  int stars,
  String selectedLanguage,
  StageService stageService,
) {
  print('\n🎮 Opening Arcade Stage Dialog');
  print('📋 Stage: $stageNumber');
  print('🎯 Category: ${category['id']}');
  print('🌍 Language: $selectedLanguage');
  print('🏆 Best Record: ${formatTime(bestRecord)}');
  print('📊 Current Record: ${formatTime(crntRecord)}');
  
  stageService.debugCacheState();
  
  // Get the category text using the shared utility
  final categoryText = getCategoryText(category['name']!, selectedLanguage);
  
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        categoryText['name']!,
                        style: GoogleFonts.vt323(
                          fontSize: 48,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Text(
                          'Best Record:',
                          style: GoogleFonts.vt323(
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          bestRecord == -1 ? 'None' : formatTime(bestRecord),
                          style: GoogleFonts.vt323(
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Current Season Record:',
                          style: GoogleFonts.vt323(
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          crntRecord == -1 ? 'None' : formatTime(crntRecord),
                          style: GoogleFonts.vt323(
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Button3D(
                      width: 200,
                      height: 50,
                      backgroundColor: const Color(0xFF351B61),
                      borderColor: const Color(0xFF1A0D30),
                      onPressed: () async {
                        try {
                          await _handleOfflineArcadeStart(
                            category['id']!, 
                            stageNumber,
                            mode,
                            stageService
                          );
                          
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PrerequisitePage(
                                  language: selectedLanguage,
                                  category: category,
                                  stageName: stageData['stageName'],
                                  stageData: stageData,
                                  mode: mode,
                                  gamemode: 'arcade',
                                  personalBest: bestRecord,
                                  crntRecord: crntRecord,
                                  stars: stars,
                                  maxScore: 0,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('❌ Error starting arcade game: $e');
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
                          fontSize: 24,
                          color: Colors.white,
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
    final arcadeKey = GameSaveData.getArcadeKey(categoryId);
    
    // Only get saved game state from GameSaveManager
    final gameSaveManager = GameSaveManager();
    final savedState = await gameSaveManager.getSavedGameState(
      categoryId: categoryId,
      stageName: arcadeKey,
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

Future<void> _handleOfflineArcadeStart(
  String categoryId, 
  int stageNumber,
  String mode,
  StageService stageService
) async {
  try {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      final arcadeKey = GameSaveData.getArcadeKey(categoryId);
      await stageService.addOfflineChange('arcade_start', {
        'categoryId': categoryId,
        'stageKey': arcadeKey,
        'mode': mode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('📱 Added offline change for arcade start');
    }
  } catch (e) {
    print('❌ Error handling offline start: $e');
    throw GameSaveDataException('Failed to handle offline arcade start: $e');
  }
}