import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart'; // Import the GameplayPage

void showStageDialog(BuildContext context, int stageNumber, String questName, int numberOfQuestions, Map<String, dynamic> stageData) {
  // Convert questName to plural form
  String pluralQuestName = questName.endsWith('s') ? questName : '${questName}s';

  showDialog(
    context: context,
    barrierDismissible: true, // Make the dialog disappear when a user touches outside
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black, width: 2), // Black border
        ),
        child: Container(
          width: 350, // Make the dialog rectangular
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  'Stage $stageNumber',
                  style: GoogleFonts.vt323(
                    fontSize: 48, // Larger font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'About $pluralQuestName',
                style: GoogleFonts.vt323(
                  fontSize: 36, // Larger font size
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  // Replace with actual logic to determine if the star should be filled
                  bool isFilled = index < 2; // Example: 2 out of 3 stars filled
                  return Icon(
                    isFilled ? Icons.star : Icons.star_border,
                    color: Colors.yellow,
                    size: 36, // Larger icon size
                  );
                }),
              ),
              const SizedBox(height: 20),
              Text(
                'Personal Best: 0 / $numberOfQuestions', // Replace with actual personal best data
                style: GoogleFonts.vt323(
                  fontSize: 24, // Larger font size
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GameplayPage(
                        language: 'en', // Replace with actual language
                        category: questName, // Replace with actual category
                        stageName: 'Stage $stageNumber', // Replace with actual stage name
                        stageData: stageData, // Pass the stage data
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, // Text color
                  backgroundColor: Colors.blue, // Background color
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), // Larger button size
                ),
                child: Text(
                  'Play Now',
                  style: GoogleFonts.vt323(
                    fontSize: 24, // Larger font size
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