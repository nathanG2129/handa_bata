import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/prerequisite/prerequisite_page.dart';
import 'package:handabatamae/localization/stages/localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:handabatamae/services/auth_service.dart';

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
        future: _getSavedGameData(
          category['id']!,
          stageNumber,
          mode
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ Error loading saved game: ${snapshot.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading game data: ${snapshot.error}')),
            );
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
                    ElevatedButton(
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

Future<Map<String, dynamic>?> _getSavedGameData(
  String categoryId,
  int stageNumber,
  String mode
) async {
  try {
    final arcadeKey = GameSaveData.getArcadeKey(categoryId);
    
    // Use AuthService's getSavedGameState instead of direct access
    final authService = AuthService();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await authService.getSavedGameState(
        userId: user.uid,
        categoryId: categoryId,
        stageName: arcadeKey,
        mode: mode,
      );
    }
    return null;
  } catch (e) {
    print('❌ Error getting saved game data: $e');
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