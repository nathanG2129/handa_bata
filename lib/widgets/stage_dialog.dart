import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart'; // Import the GameplayPage

void showStageDialog(
  BuildContext context,
  int stageNumber,
  Map<String, String> category,
  int numberOfQuestions,
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
                  bool isFilled = index < stars;
                  return Icon(
                    isFilled ? Icons.star : Icons.star_border,
                    color: Colors.yellow,
                    size: 36,
                  );
                }),
              ),
              const SizedBox(height: 20),
              Text(
                'Personal Best: $personalBest / $numberOfQuestions',
                style: GoogleFonts.vt323(
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  print('Navigating to GameplayPage with category: $category and mode: $mode');
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