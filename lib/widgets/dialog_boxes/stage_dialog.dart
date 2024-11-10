import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart';
// Import the GameplayPage
import 'package:handabatamae/game/prerequisite/prerequisite_page.dart';
import 'package:handabatamae/localization/stages/localization.dart'; // Import the localization file
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:handabatamae/services/stage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
        future: _getSavedGameData(category['id']!, stageNumber, mode),
        builder: (context, snapshot) {
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
                      if (!(snapshot.data!['completed'] ?? false)) ...[
                        ElevatedButton(
                          onPressed: () async {
                            await _handleOfflineStageStart(
                              category['id']!, 
                              'Stage $stageNumber',
                              mode,
                              stageService
                            );
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
                                    'savedGame': snapshot.data,
                                  },
                                  mode: mode,
                                  gamemode: 'adventure',
                                ),
                              ),
                            );
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
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await _handleOfflineStageStart(
                          category['id']!, 
                          'Stage $stageNumber',
                          mode,
                          stageService
                        );
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PrerequisitePage(
                              language: selectedLanguage, // Pass selectedLanguage
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

// Helper function to get saved game data
Future<Map<String, dynamic>?> _getSavedGameData(String categoryId, int stageNumber, String mode) async {
  try {
    final docId = '${categoryId}_Stage ${stageNumber}_${mode.toLowerCase()}';
    
    // Try local storage first
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedGameJson = prefs.getString('game_progress_$docId');
    if (savedGameJson != null) {
      return jsonDecode(savedGameJson);
    }
    
    // Only try Firebase if we're online
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('User')
            .doc(user.uid)
            .collection('GameProgress')
            .doc(docId)
            .get();
            
        if (doc.exists) {
          final savedGame = doc.data();
          // Cache the Firebase data locally
          await prefs.setString('game_progress_$docId', jsonEncode(savedGame));
          return savedGame;
        }
      }
    }
    
    return null;
  } catch (e) {
    print('Error getting saved game data: $e');
    return null;
  }
}

// Add offline change handling
Future<void> _handleOfflineStageStart(
  String categoryId, 
  String stageName, 
  String mode,
  StageService stageService
) async {
  final connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    await stageService.addOfflineChange('stage_start', {
      'categoryId': categoryId,
      'stageName': stageName,
      'mode': mode,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}