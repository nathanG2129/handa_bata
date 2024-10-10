import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart'; // Import the GameplayPage

void showStageDialog(
  BuildContext context,
  int stageNumber,
  Map<String, String> category,
  int maxScore, // Change parameter name to maxScore
  Map<String, dynamic> stageData,
  String mode,
  int personalBest, // Add personal best score
  int stars, // Add stars
) {
  // Convert category name to plural form
  String pluralQuestName = category['name']!.endsWith('s') ? category['name']! : '${category['name']}s';

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: Container(
          width: 350,
          height: 400,
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
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'About $pluralQuestName',
                style: GoogleFonts.vt323(
                  fontSize: 36,
                ),
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
              Text(
                'Personal Best: $personalBest / $maxScore', // Use maxScore instead of numberOfQuestions
                style: GoogleFonts.vt323(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GameplayPage(
                        language: 'en',
                        category: {
                          'id': category['id'],
                          'name': category['name'],
                        },
                        stageName: 'Stage $stageNumber',
                        stageData: stageData,
                        mode: mode,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'Play Now',
                  style: GoogleFonts.vt323(
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}