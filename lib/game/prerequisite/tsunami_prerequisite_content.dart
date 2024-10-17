import 'package:flutter/material.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:handabatamae/game/prerequisite/tutorial_page.dart';

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

    if (widget.stageName.contains('Arcade')) {
      tutorials = [
        TutorialPage(
          title: 'Multiple Choice',
          imagePaths: const [
            'assets/instructions/MultipleChoice01.jpg',
            'assets/instructions/MultipleChoice02.jpg',
          ],
          description: 'Read the question carefully and choose the correct answer. Avoid incorrect answers, or Kladis and Kloud\'s health bars will decrease.',
          onNext: _nextTutorial,
        ),
        TutorialPage(
          title: 'Identification',
          imagePaths: const [
            'assets/instructions/Identification01.jpg',
            'assets/instructions/Identification02.jpg',
            'assets/instructions/Identification03.jpg',
            'assets/instructions/Identification04.jpg',
          ],
          description: 'Select a letter one at a time to form an answer. Your answer will be checked instantly once you fill in the last tile. Answer carefully to prevent Kladis and Kloud\'s health bar from going down.',
          onNext: _nextTutorial,
        ),
        TutorialPage(
          title: 'Fill in the Blanks',
          imagePaths: const [
            'assets/instructions/FillinTheBlanks01.jpg',
            'assets/instructions/FillinTheBlanks02.jpg',
            'assets/instructions/FillinTheBlanks03.jpg',
            'assets/instructions/FillinTheBlanks04.jpg',
            'assets/instructions/FillinTheBlanks05.jpg',
            'assets/instructions/FillinTheBlanks06.jpg',
          ],
          description: 'Fill in the blanks with the correct letters to complete the word. Avoid incorrect answers, or Kladis and Kloud\'s health bars will decrease.',
          onNext: _nextTutorial,
        ),
        TutorialPage(
          title: 'Matching Type',
          imagePaths: const [
            'assets/instructions/MatchingType01.jpg',
            'assets/instructions/MatchingType02.jpg',
            'assets/instructions/MatchingType03.jpg',
            'assets/instructions/MatchingType04.jpg',
            'assets/instructions/MatchingType05.jpg',
          ],
          description: 'Match the items correctly to their corresponding pairs. Avoid incorrect matches, or Kladis and Kloud\'s health bars will decrease.',
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
        ),
      ];
    } else if (widget.stageName.contains('1')) {
      tutorials = [
        TutorialPage(
          title: 'Multiple Choice',
          imagePaths: const [
            'assets/instructions/MultipleChoice01.jpg',
            'assets/instructions/MultipleChoice02.jpg',
          ],
          description: 'Read the question carefully and choose the correct answer. Avoid incorrect answers, or Kladis and Kloud\'s health bars will decrease.',
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
        ),
      ];
    } else if (widget.stageName.contains('2')) {
      tutorials = [
        TutorialPage(
          title: 'Identification',
          imagePaths: const [
            'assets/instructions/Identification01.jpg',
            'assets/instructions/Identification02.jpg',
            'assets/instructions/Identification03.jpg',
            'assets/instructions/Identification04.jpg',
          ],
          description: 'Select a letter one at a time to form an answer. Your answer will be checked instantly once you fill in the last tile. Answer carefully to prevent Kladis and Kloud\'s health bar from going down.',
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
        ),
      ];
    } else if (widget.stageName.contains('3')) {
      tutorials = [
        TutorialPage(
          title: 'Fill in the Blanks',
          imagePaths: const [
            'assets/instructions/FillinTheBlanks01.jpg',
            'assets/instructions/FillinTheBlanks02.jpg',
            'assets/instructions/FillinTheBlanks03.jpg',
            'assets/instructions/FillinTheBlanks04.jpg',
            'assets/instructions/FillinTheBlanks05.jpg',
            'assets/instructions/FillinTheBlanks06.jpg',
          ],
          description: 'Fill in the blanks with the correct letters to complete the word. Avoid incorrect answers, or Kladis and Kloud\'s health bars will decrease.',
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
        ),
      ];
    } else if (widget.stageName.contains('4')) {
      tutorials = [
        TutorialPage(
          title: 'Matching Type',
          imagePaths: const [
            'assets/instructions/MatchingType01.jpg',
            'assets/instructions/MatchingType02.jpg',
            'assets/instructions/MatchingType03.jpg',
            'assets/instructions/MatchingType04.jpg',
            'assets/instructions/MatchingType05.jpg',
          ],
          description: 'Match the items correctly to their corresponding pairs. Avoid incorrect matches, or Kladis and Kloud\'s health bars will decrease.',
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
        ),
      ];
    } else {
      tutorials = [
        TutorialPage(
          title: 'Unknown Stage',
          imagePaths: const [],
          description: 'No tutorial available for this stage.',
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
        ),
      ];
    }

    return tutorials[_currentTutorial];
  }
}