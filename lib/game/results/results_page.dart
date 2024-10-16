import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/pages/stages_page.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:soundpool/soundpool.dart'; // Import soundpool package
import 'question_widgets.dart';
import 'results_widgets.dart';

class ResultsPage extends StatefulWidget {
  final int score;
  final double accuracy;
  final int streak;
  final String language;
  final Map<String, dynamic> category;
  final String stageName;
  final Map<String, dynamic> stageData;
  final String mode;
  final String gamemode;
  final int fullyCorrectAnswersCount; // Add this parameter
  final List<Map<String, dynamic>> answeredQuestions; // Add this parameter

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
    required this.gamemode, // Add this parameter
    required this.fullyCorrectAnswersCount, // Add this parameter
    required this.answeredQuestions, 
  });

  @override
  ResultsPageState createState() => ResultsPageState();
}

class ResultsPageState extends State<ResultsPage> {
  late Soundpool _soundpool;
  late int _soundIdFail;
  late int _soundId1Star;
  late int _soundId2Stars;
  late int _soundId3Stars;
  bool _soundsLoaded = false;

  @override
  void initState() {
    super.initState();
    _soundpool = Soundpool.fromOptions(options: const SoundpoolOptions(streamType: StreamType.music));
    _loadSounds();
  }

  int _calculateStars(double accuracy, int score, int totalQuestions) {
    if (accuracy > 0.9 && score == totalQuestions) { // Adjust the condition to reflect the correct answers count
      return 3;
    } else if (score > totalQuestions / 2) { // Adjust the condition to reflect the correct answers count
      return 2;
    } else {
      return 1;
    }
  }

  Future<void> _loadSounds() async {
    _soundIdFail = await _soundpool.load(await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_descend_fail_negative.mp3'));
    _soundId1Star = await _soundpool.load(await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_001.mp3'));
    _soundId2Stars = await _soundpool.load(await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_004.mp3'));
    _soundId3Stars = await _soundpool.load(await rootBundle.load('assets/sound/result/zapsplat_multimedia_game_retro_musical_level_complete_007.mp3'));
    setState(() {
      _soundsLoaded = true;
    });
    _playSoundBasedOnStars();
  }

  void _playSoundBasedOnStars() {
    int stars = _calculateStars(widget.accuracy, widget.score, widget.stageData['totalQuestions'] ?? 0);
    switch (stars) {
      case 0:
        _soundpool.play(_soundIdFail);
        break;
      case 1:
        _soundpool.play(_soundId1Star);
        break;
      case 2:
        _soundpool.play(_soundId2Stars);
        break;
      case 3:
        _soundpool.play(_soundId3Stars);
        break;
    }
  }

  Future<void> _updateScoreAndStarsInFirestore(int stars) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('User')
        .doc(user.uid)
        .collection('GameSaveData')
        .doc(widget.category['id']);

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return;

    final data = docSnapshot.data() as Map<String, dynamic>;
    final stageData = data['stageData'] as Map<String, dynamic>;

    // Find the correct stage key
    final stageKey = stageData.keys.firstWhere(
      (key) => key.startsWith(widget.category['id']) && key.endsWith(widget.stageName.split(' ').last),
      orElse: () => '',
    ); // Stage not found

    if (widget.mode == 'Normal') {
      final currentScore = stageData[stageKey]['scoreNormal'] as int;
      if (widget.score > currentScore) { // Use the correct answers count as the score
        stageData[stageKey]['scoreNormal'] = widget.score; // Update with the correct answers count
      }

      final normalStageStars = data['normalStageStars'] as List<dynamic>;
      final stageIndex = int.parse(stageKey.replaceAll(widget.category['id'], '')) - 1;
      final currentStars = normalStageStars[stageIndex] as int;
      if (stars > currentStars) {
        normalStageStars[stageIndex] = stars;
      }
    } else if (widget.mode == 'Hard') {
      final currentScore = stageData[stageKey]['scoreHard'] as int;
      if (widget.score > currentScore) { // Use the correct answers count as the score
        stageData[stageKey]['scoreHard'] = widget.score; // Update with the correct answers count
      }

      final hardStageStars = data['hardStageStars'] as List<dynamic>;
      final stageIndex = int.parse(stageKey.replaceAll(widget.category['id'], '')) - 1;
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

  @override
  Widget build(BuildContext context) {
    int totalQuestions = widget.stageData['totalQuestions'] ?? 0; // Provide a default value of 0 if null
    int stars = _calculateStars(widget.accuracy, widget.score, totalQuestions);

    // Update the score and stars in Firestore
    _updateScoreAndStarsInFirestore(stars);

    return Scaffold(
      body: _soundsLoaded
          ? ResponsiveBreakpoints(
              breakpoints: const [
                Breakpoint(start: 0, end: 450, name: MOBILE),
                Breakpoint(start: 451, end: 800, name: TABLET),
                Breakpoint(start: 801, end: 1920, name: DESKTOP),
                Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
              child: MaxWidthBox(
                maxWidth: 1200,
                child: ResponsiveScaledBox(
                  width: ResponsiveValue<double>(context, conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 450),
                    const Condition.between(start: 800, end: 1100, value: 800),
                    const Condition.between(start: 1000, end: 1200, value: 1000),
                  ]).value,
                  child: Container(
                    color: const Color(0xFF5E31AD), // Same background color as GameplayPage
                    child: SafeArea(
                      child: SingleChildScrollView( // Make the entire content scrollable
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 175),
                            buildReactionWidget(stars),
                            const SizedBox(height: 20),
                            buildStarsWidget(stars),
                            const SizedBox(height: 20),
                            Text(
                              'My Performance',
                              style: GoogleFonts.vt323(fontSize: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            buildStatisticsWidget(widget.score, widget.accuracy, widget.streak),
                            const SizedBox(height: 50),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StagesPage(
                                          questName: widget.category['name'], // Use the category name for questName
                                          category: {
                                            'id': widget.category['id'], // Ensure the category id is passed
                                            'name': widget.category['name'],
                                          }, selectedLanguage: widget.language,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white, // Text color
                                    backgroundColor: const Color(0xFF351b61), // Background color
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF1A0D30), // Much darker border color
                                      width: 4, // Thicker border width for bottom
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  ),
                                  child: const Text('Back'),
                                ),
                                const SizedBox(width: 25),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GameplayPage(
                                          language: widget.language,
                                          category: widget.category,
                                          stageName: widget.stageName,
                                          stageData: widget.stageData,
                                          mode: widget.mode, // Pass the mode
                                          gamemode: widget.gamemode,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black, // Text color
                                    backgroundColor: const Color(0xFFF1B33A), // Background color
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF8B5A00), // Much darker border color
                                      width: 4, // Thicker border width for bottom
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  ),
                                  child: const Text('Play Again'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 50),
                          Text(
                            'Stage Questions',
                            style: GoogleFonts.vt323(fontSize: 32, color: Colors.white),
                          ),
                          const SizedBox(height: 10), // Add some space before the questions
                          _buildAnsweredQuestionsWidget(context), // Move this line here
                          const SizedBox(height: 50), // Add some space before the questions
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
          ) : Container(
              color: const Color(0xFF5E31AD), // Same background color as GameplayPage
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }

  Widget _buildAnsweredQuestionsWidget(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75, // Set width to 75% of the screen width
      child: Column(
        children: widget.answeredQuestions.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> question = entry.value;
          if (question['type'] == 'Multiple Choice') {
            return buildMultipleChoiceQuestionWidget(context, index, question);
          } else if (question['type'] == 'Identification') {
            return buildIdentificationQuestionWidget(context, index, question);
          } else if (question['type'] == 'Fill in the Blanks') {
            return buildFillInTheBlanksQuestionWidget(context, index, question);
          } else {
             return buildMatchingTypeQuestionWidget(context, index, question);
          }
        }).toList(),
      ),
    );
  }
}