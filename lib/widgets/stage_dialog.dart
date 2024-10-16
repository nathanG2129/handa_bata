import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
// Import the GameplayPage
import 'package:handabatamae/game/prerequisite_page.dart';
import 'package:handabatamae/localization/stages/localization.dart'; // Import the localization file

void showStageDialog(
  BuildContext context,
  int stageNumber,
  Map<String, String> category,
  int maxScore, // Change parameter name to maxScore
  Map<String, dynamic> stageData,
  String mode,
  int personalBest, // Add personal best score
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PrerequisitePage(
                          language: selectedLanguage, // Pass selectedLanguage
                          category: category,
                          stageName: 'Stage $stageNumber',
                          stageData: stageData,
                          mode: mode,
                          personalBest: personalBest,
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
}