import 'package:flutter/material.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/game/prerequisite/tutorial_page.dart';
import 'package:handabatamae/game/prerequisite/tutorial_localization.dart';

class TsunamiPrerequisiteContent extends StatefulWidget {
  final String stageName;
  final String language;
  final Map<String, String> category;
  final Map<String, dynamic> stageData;
  final String mode;
  final String gamemode;

  const TsunamiPrerequisiteContent({
    super.key,
    required this.stageName,
    required this.language,
    required this.category,
    required this.stageData,
    required this.mode,
    required this.gamemode,
  });

  @override
  TsunamiPrerequisiteContentState createState() => TsunamiPrerequisiteContentState();
}

class TsunamiPrerequisiteContentState extends State<TsunamiPrerequisiteContent> {
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
            'assets/instructions/MultipleChoice01.jpg',
            'assets/instructions/MultipleChoice02.jpg',
          ],
          description: TutorialLocalization.getDescription(mode, 'multiple_choice', widget.language),
          onNext: _nextTutorial,
          isFirstPage: true,
          language: widget.language,
        ),
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'identification', widget.language),
          imagePaths: const [
            'assets/instructions/Identification01.jpg',
            'assets/instructions/Identification02.jpg',
            'assets/instructions/Identification03.jpg',
            'assets/instructions/Identification04.jpg',
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
            'assets/instructions/FillinTheBlanks01.jpg',
            'assets/instructions/FillinTheBlanks02.jpg',
            'assets/instructions/FillinTheBlanks03.jpg',
            'assets/instructions/FillinTheBlanks04.jpg',
            'assets/instructions/FillinTheBlanks05.jpg',
            'assets/instructions/FillinTheBlanks06.jpg',
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
            'assets/instructions/MatchingType01.jpg',
            'assets/instructions/MatchingType02.jpg',
            'assets/instructions/MatchingType03.jpg',
            'assets/instructions/MatchingType04.jpg',
            'assets/instructions/MatchingType05.jpg',
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
            'assets/instructions/MultipleChoice01.jpg',
            'assets/instructions/MultipleChoice02.jpg',
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
          isLastPage: true,
          language: widget.language,
        ),
      ];
    } else if (widget.stageName.contains('2')) {
      tutorials = [
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'identification', widget.language),
          imagePaths: const [
            'assets/instructions/Identification01.jpg',
            'assets/instructions/Identification02.jpg',
            'assets/instructions/Identification03.jpg',
            'assets/instructions/Identification04.jpg',
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
        ),
      ];
    } else if (widget.stageName.contains('3')) {
      tutorials = [
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'matching_type', widget.language),
          imagePaths: const [
            'assets/instructions/MatchingType01.jpg',
            'assets/instructions/MatchingType02.jpg',
            'assets/instructions/MatchingType03.jpg',
            'assets/instructions/MatchingType04.jpg',
            'assets/instructions/MatchingType05.jpg',
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
          isLastPage: true,
          language: widget.language,
        ),
      ];
    } else if (widget.stageName.contains('5')) {
      tutorials = [
        TutorialPage(
          title: TutorialLocalization.getTitle(mode, 'fill_in_blanks', widget.language),
          imagePaths: const [
            'assets/instructions/FillinTheBlanks01.jpg',
            'assets/instructions/FillinTheBlanks02.jpg',
            'assets/instructions/FillinTheBlanks03.jpg',
            'assets/instructions/FillinTheBlanks04.jpg',
          ],
          description: TutorialLocalization.getDescription(mode, 'fill_in_blanks', widget.language),
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