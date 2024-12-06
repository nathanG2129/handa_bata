import 'package:flutter/material.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/game/prerequisite/tutorial_page.dart';
import 'package:handabatamae/game/prerequisite/tutorial_localization.dart';
import 'package:handabatamae/game/prerequisite/tutorial_resources.dart';

class StormPrerequisiteContent extends StatefulWidget {
  final String stageName;
  final String language;
  final Map<String, String> category;
  final Map<String, dynamic> stageData;
  final String mode;
  final String gamemode;

  const StormPrerequisiteContent({
    super.key,
    required this.stageName,
    required this.language,
    required this.category,
    required this.stageData,
    required this.mode,
    required this.gamemode,
  });

  @override
  StormPrerequisiteContentState createState() => StormPrerequisiteContentState();
}

class StormPrerequisiteContentState extends State<StormPrerequisiteContent> {
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
          onNext: _nextTutorial,
          isFirstPage: true,
          language: widget.language,
          isGameTutorial: true,
        ),
        TutorialPage(
          title: TutorialResources.getResourceTypeTitle('video', widget.language),
          videoId: 'uz9sclC3nBE',
          imagePaths: const [],
          description: 'Alam mo ba? Bagyo',
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
          isFirstPage: true,
          isLastPage: true,
          language: widget.language,
          isGameTutorial: true,
        ),
      ];
    } else if (widget.stageName.contains('3')) {
      tutorials = [
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
        TutorialPage(
          title: TutorialResources.getResourceTypeTitle('infographic', widget.language),
          imagePaths: const ['assets/images/infographics/RainfallWarningSystemPayongPAGASA.jpeg'],
          description: 'PAGASA Rainfall Warning System',
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
        TutorialPage(
          title: TutorialResources.getResourceTypeTitle('infographic', widget.language),
          imagePaths: const ['assets/images/infographics/TropicalCycloneWarningSystemPayongPAGASA.jpeg'],
          description: 'PAGASA Tropical Cyclone Warning System',
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
    } else {
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