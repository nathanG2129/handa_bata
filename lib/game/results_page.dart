import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/pages/stages_page.dart';

class ResultsPage extends StatelessWidget {
  final int score;
  final double accuracy;
  final int streak;
  final String language;
  final Map<String, dynamic> category;
  final String stageName;
  final Map<String, dynamic> stageData;
  final String mode;
  final int fullyCorrectAnswersCount; // Add this parameter

  const ResultsPage({
    super.key,
    required this.score,
    required this.accuracy,
    required this.streak,
    required this.language,
    required this.category,
    required this.stageName,
    required this.stageData,
    required this.mode,
    required this.fullyCorrectAnswersCount, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    int totalQuestions = stageData['totalQuestions'] ?? 0; // Provide a default value of 0 if null
    int stars = _calculateStars(accuracy, score, totalQuestions);
    print('Stars: $stars');
    print('ResultsPage received category: $category');
    print(stageName);

    // Update the score and stars in Firestore
    _updateScoreAndStarsInFirestore(stars);

    return Scaffold(
      body: Container(
        color: const Color(0xFF5E31AD), // Same background color as GameplayPage
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildReactionWidget(stars),
              const SizedBox(height: 20),
              _buildStarsWidget(stars),
              const SizedBox(height: 20),
              Text(
                'My Performance',
                style: GoogleFonts.vt323(fontSize: 32, color: Colors.white),
              ),
              const SizedBox(height: 20),
              _buildStatisticsWidget(),
              const SizedBox(height: 20),
              _buildButtons(context), // Add the buttons below the statistics
            ],
          ),
        ),
      ),
    );
  }

  int _calculateStars(double accuracy, int score, int totalQuestions) {
    if (accuracy > 0.9 && score == totalQuestions) {
      return 3;
    } else if (score > totalQuestions / 2) {
      return 2;
    } else {
      return 1;
    }
  }

  Widget _buildReactionWidget(int stars) {
    String reaction;
    switch (stars) {
      case 3:
        reaction = 'Great job!';
        break;
      case 2:
        reaction = 'Good effort!';
        break;
      default:
        reaction = 'Keep trying!';
    }
    return TextWithShadow(
      text: reaction,
      fontSize: 48, // Larger font size
    );
  }

  Widget _buildStarsWidget(int stars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: Colors.yellow,
          size: 48,
        );
      }),
    );
  }

  Widget _buildStatisticsWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatisticItem('Score', score.toString()),
        _buildStatisticItem('Accuracy', '${(accuracy * 100).toStringAsFixed(1)}%'),
        _buildStatisticItem('Streak', streak.toString()),
      ],
    );
  }

  Widget _buildStatisticItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1D6E), // Darker shade of the background color
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.rubik(fontSize: 20, color: Colors.white),
          ),
          Text(
            label,
            style: GoogleFonts.rubik(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StagesPage(
                  questName: category['name'], // Use the category name for questName
                  category: {
                    'id': category['id'], // Ensure the category id is passed
                    'name': category['name'],
                  },
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Text color
            backgroundColor: Colors.blue, // Background color
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)), // Rounded corners
            ),
          ),
          child: const Text('Back'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GameplayPage(
                  language: language,
                  category: category,
                  stageName: stageName,
                  stageData: stageData,
                  mode: mode, // Pass the mode
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Text color
            backgroundColor: Colors.green, // Background color
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)), // Rounded corners
            ),
          ),
          child: const Text('Play Again'),
        ),
      ],
    );
  }

  Future<void> _updateScoreAndStarsInFirestore(int stars) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
  
    final docRef = FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .collection('GameSaveData')
        .doc(category['id']);
  
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return;
  
    final data = docSnapshot.data() as Map<String, dynamic>;
    final stageData = data['stageData'] as Map<String, dynamic>;
  
    // Find the correct stage key
    final stageKey = stageData.keys.firstWhere(
      (key) => key.startsWith(category['id']) && key.endsWith(stageName.split(' ').last),
      orElse: () => '',
    ); // Stage not found
  
    if (mode == 'Normal') {
      final currentScore = stageData[stageKey]['scoreNormal'] as int;
      if (fullyCorrectAnswersCount > currentScore) {
        stageData[stageKey]['scoreNormal'] = fullyCorrectAnswersCount;
      }
  
      final normalStageStars = data['normalStageStars'] as List<dynamic>;
      final stageIndex = int.parse(stageKey.replaceAll(category['id'], '')) - 1;
      final currentStars = normalStageStars[stageIndex] as int;
      if (stars > currentStars) {
        normalStageStars[stageIndex] = stars;
      }
    } else if (mode == 'Hard') {
      final currentScore = stageData[stageKey]['scoreHard'] as int;
      if (fullyCorrectAnswersCount > currentScore) {
        stageData[stageKey]['scoreHard'] = fullyCorrectAnswersCount;
      }
  
      final hardStageStars = data['hardStageStars'] as List<dynamic>;
      final stageIndex = int.parse(stageKey.replaceAll(category['id'], '')) - 1;
      final currentStars = hardStageStars[stageIndex] as int;
      if (stars > currentStars) {
        hardStageStars[stageIndex] = stars;
      }
    }
  
    // Update Firestore with the new data
    await docRef.update({
      'stageData': stageData,
      'normalStageStars': data['normalStageStars'],
      'hardStageStars': data['hardStageStars'],
    });
  }
}