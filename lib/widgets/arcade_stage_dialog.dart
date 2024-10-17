import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import the GameplayPage
import 'package:handabatamae/game/prerequisite/prerequisite_page.dart';
import 'package:handabatamae/localization/stages/localization.dart'; // Import the localization file

void showArcadeStageDialog(
  BuildContext context,
  int stageNumber,
  Map<String, String> category,
  Map<String, dynamic> stageData,
  String mode,
  int bestRecord, // Change parameter name to bestRecord
  int currentRecord, // Add currentRecord
  int stars, // Add stars
  String selectedLanguage, // Add selectedLanguage
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
                      bestRecord == -1 ? 'None' : '$bestRecord',
                      style: GoogleFonts.vt323(
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Current Record:',
                      style: GoogleFonts.vt323(
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      currentRecord == -1 ? 'None' : '$currentRecord',
                      style: GoogleFonts.vt323(
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    print('Selected Language: $selectedLanguage');
                    print('Category: $category');
                    print('Stage Name: ${stageData['stageName']}');
                    print('Stage Data: $stageData');
                    print('Mode: $mode');
                    print('Best Record: $bestRecord');
                    print('Stars: $stars');
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PrerequisitePage(
                          language: selectedLanguage, // Pass selectedLanguage
                          category: category,
                          stageName: stageData['stageName'],
                          stageData: stageData,
                          mode: mode,
                          gamemode: 'arcade', // Set gamemode to arcade
                          personalBest: bestRecord, // Pass bestRecord as personalBest
                          crntRecord: currentRecord, // Pass bestRecord as personalBest
                          stars: stars,
                          maxScore: 0,
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
}