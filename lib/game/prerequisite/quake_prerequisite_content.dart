import 'package:flutter/material.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/game/prerequisite/tutorial_page.dart';
import 'package:handabatamae/game/prerequisite/tutorial_localization.dart';
import 'package:handabatamae/game/prerequisite/tutorial_resources.dart';

class QuakePrerequisiteContent extends StatefulWidget {
  final String stageName;
  final String language;
  final Map<String, String> category;
  final Map<String, dynamic> stageData;
  final String mode;
  final String gamemode;

  const QuakePrerequisiteContent({
    super.key,
    required this.stageName,
    required this.language,
    required this.category,
    required this.stageData,
    required this.mode,
    required this.gamemode,
  });

  @override
  QuakePrerequisiteContentState createState() => QuakePrerequisiteContentState();
}

class QuakePrerequisiteContentState extends State<QuakePrerequisiteContent> {
  int _currentTutorial = 0;

  void _nextTutorial() {
    setState(() {
      _currentTutorial++;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tutorials;
    String mode = widget.stageName.contains('Arcade') ? 'arcade' : 'adventure';

    if (widget.stageName.contains('Arcade')) {
      tutorials = [
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'multiple_choice', widget.language),
          imagePaths: const [
            'assets/instructions/MultipleChoice01.png',
            'assets/instructions/MultipleChoice02.png',
          ],
          description: TutorialLocalization.getDescription(mode, 'multiple_choice', widget.language),
          onNext: _nextTutorial,
          isFirstPage: true,
          language: widget.language,
          isGameTutorial: true,
        ),
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'identification', widget.language),
          imagePaths: const [
            'assets/instructions/Identification01.png',
            'assets/instructions/Identification02.png',
            'assets/instructions/Identification03.png',
            'assets/instructions/Identification04.png',
          ],
          description: TutorialLocalization.getDescription(mode, 'identification', widget.language),
          onNext: _nextTutorial,
          onBack: () => setState(() => _currentTutorial--),
          isFirstPage: false,
          language: widget.language,
          isGameTutorial: true,
        ),
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'fill_in_blanks', widget.language),
          imagePaths: const [
            'assets/instructions/FillinTheBlanks01.png',
            'assets/instructions/FillinTheBlanks02.png',
            'assets/instructions/FillinTheBlanks03.png',
            'assets/instructions/FillinTheBlanks04.png',
            'assets/instructions/FillinTheBlanks05.png',
            'assets/instructions/FillinTheBlanks06.png',
          ],
          description: TutorialLocalization.getDescription(mode, 'fill_in_blanks', widget.language),
          onNext: _nextTutorial,
          onBack: () => setState(() => _currentTutorial--),
          isFirstPage: false,
          language: widget.language,
          isGameTutorial: true,
        ),
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'matching_type', widget.language),
          imagePaths: const [
            'assets/instructions/MatchingType01.png',
            'assets/instructions/MatchingType02.png',
            'assets/instructions/MatchingType03.png',
            'assets/instructions/MatchingType04.png',
            'assets/instructions/MatchingType05.png',
          ],
          description: TutorialLocalization.getDescription(mode, 'matching_type', widget.language),
          onNext: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameplayPage(
                  language: widget.language,
                  category: widget.category,
                  stageName: widget.stageName,
                  stageData: widget.stageData,
                  mode: widget.mode,
                  gamemode: widget.gamemode,
                ),
              ),
            );
          },
          onBack: () => setState(() => _currentTutorial--),
          isFirstPage: false,
          isLastPage: true,
          language: widget.language,
          isGameTutorial: true,
        ),
      ];
    } else if (widget.stageName.contains('1')) {
      tutorials = [
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'multiple_choice', widget.language),
          imagePaths: const [
            'assets/instructions/MultipleChoice01.png',
            'assets/instructions/MultipleChoice02.png',
          ],
          description: TutorialLocalization.getDescription(mode, 'multiple_choice', widget.language),
          onNext: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameplayPage(
                  language: widget.language,
                  category: widget.category,
                  stageName: widget.stageName,
                  stageData: widget.stageData,
                  mode: widget.mode,
                  gamemode: widget.gamemode,
                ),
              ),
            );
          },
          isFirstPage: true,
          isLastPage: true,
          language: widget.language,
          isGameTutorial: true,
        ),
      ];
    } else if (widget.stageName.contains('2')) {
      tutorials = [
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'identification', widget.language),
          imagePaths: const [
            'assets/instructions/Identification01.png',
            'assets/instructions/Identification02.png',
            'assets/instructions/Identification03.png',
            'assets/instructions/Identification04.png',
          ],
          description: TutorialLocalization.getDescription(mode, 'identification', widget.language),
          onNext: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameplayPage(
                  language: widget.language,
                  category: widget.category,
                  stageName: widget.stageName,
                  stageData: widget.stageData,
                  mode: widget.mode,
                  gamemode: widget.gamemode,
                ),
              ),
            );
          },
          isLastPage: true,
          language: widget.language,
          isGameTutorial: true,
        ),
      ];
    } else if (widget.stageName.contains('3')) {
      tutorials = [
        // Fill in the Blanks Tutorial
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'fill_in_blanks', widget.language),
          imagePaths: const [
            'assets/instructions/FillinTheBlanks01.png',
            'assets/instructions/FillinTheBlanks02.png',
            'assets/instructions/FillinTheBlanks03.png',
            'assets/instructions/FillinTheBlanks04.png',
          ],
          description: TutorialLocalization.getDescription(mode, 'fill_in_blanks', widget.language),
          onNext: _nextTutorial,
          isFirstPage: true,
          language: widget.language,
          isGameTutorial: true,
        ),
        // PHIVOLCS Earthquake Intensity Scale Infographic
        TutorialPage(
          title: TutorialResources.getResourceTypeTitle('infographic', widget.language),
          imagePaths: const ['assets/images/infographics/PHIVOLCSEarthquakeIntensityScale.jpg'],
          description: 'PHIVOLCS Earthquake Intensity Scale',
          onNext: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameplayPage(
                  language: widget.language,
                  category: widget.category,
                  stageName: widget.stageName,
                  stageData: widget.stageData,
                  mode: widget.mode,
                  gamemode: widget.gamemode,
                ),
              ),
            );
          },
          onBack: () => setState(() => _currentTutorial--),
          isFirstPage: false,
          isLastPage: true,
          language: widget.language,
          isGameTutorial: false,
        ),
      ];
    } else if (widget.stageName.contains('4')) {
      tutorials = [
        // Matching Type Tutorial
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'matching_type', widget.language),
          imagePaths: const [
            'assets/instructions/MatchingType01.png',
            'assets/instructions/MatchingType02.png',
            'assets/instructions/MatchingType03.png',
            'assets/instructions/MatchingType04.png',
            'assets/instructions/MatchingType05.png',
          ],
          description: TutorialLocalization.getDescription(mode, 'matching_type', widget.language),
          onNext: _nextTutorial,
          isFirstPage: true,
          language: widget.language,
          isGameTutorial: true,
        ),
        // Earthquake Educational Video
        TutorialPage(
          title: TutorialResources.getResourceTypeTitle('video', widget.language),
          videoId: 'XUoYj1fN2Cs',
          imagePaths: const [],
          description: 'Duck, Cover, and Hold',
          onNext: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameplayPage(
                  language: widget.language,
                  category: widget.category,
                  stageName: widget.stageName,
                  stageData: widget.stageData,
                  mode: widget.mode,
                  gamemode: widget.gamemode,
                ),
              ),
            );
          },
          onBack: () => setState(() => _currentTutorial--),
          isFirstPage: false,
          isLastPage: true,
          language: widget.language,
          isGameTutorial: false,
        ),
      ];
    } else if (widget.stageName.contains('6')) {
      tutorials = [
        // Earthquake Educational Video
        TutorialPage(
          title: TutorialResources.getResourceTypeTitle('video', widget.language),
          videoId: 'zplJvqDQrVw',
          imagePaths: const [],
          description: 'When is the time to evacuate?',
          onNext: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameplayPage(
                  language: widget.language,
                  category: widget.category,
                  stageName: widget.stageName,
                  stageData: widget.stageData,
                  mode: widget.mode,
                  gamemode: widget.gamemode,
                ),
              ),
            );
          },
          isFirstPage: true,
          isLastPage: true,
          language: widget.language,
          isGameTutorial: false,
        ),
      ];
    } else {
      // For stages without tutorials (5, 7, or any other stage)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameplayPage(
              language: widget.language,
              category: widget.category,
              stageName: widget.stageName,
              stageData: widget.stageData,
              mode: widget.mode,
              gamemode: widget.gamemode,
            ),
          ),
        );
      });
      return Container();
    }

    return tutorials[_currentTutorial];
  }
}