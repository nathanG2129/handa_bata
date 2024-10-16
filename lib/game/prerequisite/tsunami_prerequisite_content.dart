import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

Widget buildTsunamiPrerequisiteContent(BuildContext context, String stageName, String language, Map<String, String> category, Map<String, dynamic> stageData, String mode, String gamemode) {
  int _current = 0;
  List<String> imagePaths;

  if (stageName.contains('1')) {
    imagePaths = [
      'assets/instructions/MultipleChoice01.jpg',
      'assets/instructions/MultipleChoice02.jpg',
    ];
  } else if (stageName.contains('2')) {
    imagePaths = [
      'assets/instructions/Identification01.jpg',
      'assets/instructions/Identification02.jpg',
      'assets/instructions/Identification03.jpg',
      'assets/instructions/Identification04.jpg',
    ];
  } else if (stageName.contains('3')) {
    imagePaths = [
      'assets/instructions/FillinTheBlanks01.jpg',
      'assets/instructions/FillinTheBlanks02.jpg',
      'assets/instructions/FillinTheBlanks03.jpg',
      'assets/instructions/FillinTheBlanks04.jpg',
      'assets/instructions/FillinTheBlanks05.jpg',
      'assets/instructions/FillinTheBlanks06.jpg',
    ];
  } else if (stageName.contains('4')) {
    imagePaths = [
      'assets/instructions/MatchingType01.jpg',
      'assets/instructions/MatchingType02.jpg',
      'assets/instructions/MatchingType03.jpg',
      'assets/instructions/MatchingType04.jpg',
      'assets/instructions/MatchingType05.jpg',
    ];
  } else {
    imagePaths = [];
  }

  return Scaffold(
    backgroundColor: const Color(0xFF5E31AD),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (stageName.contains('1')) ...[
            const TextWithShadow(
              text: 'How to Play',
              fontSize: 36,
            ),
            const TextWithShadow(
              text: 'Multiple Choice',
              fontSize: 36,
            ),
          ] else if (stageName.contains('2')) ...[
            const TextWithShadow(
              text: 'How to Play',
              fontSize: 36,
            ),
            const TextWithShadow(
              text: 'Identification',
              fontSize: 36,
            ),
          ] else if (stageName.contains('3')) ...[
            const TextWithShadow(
              text: 'How to Play',
              fontSize: 36,
            ),
            const TextWithShadow(
              text: 'Fill in the Blanks',
              fontSize: 36,
            ),
          ] else if (stageName.contains('4')) ...[
            const TextWithShadow(
              text: 'How to Play',
              fontSize: 36,
            ),
            const TextWithShadow(
              text: 'Matching Type',
              fontSize: 36,
            ),
          ] else ...[
            Text(
              'How to Play Stage $stageName',
              style: GoogleFonts.vt323(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          if (imagePaths.isNotEmpty) ...[
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                enableInfiniteScroll: false,
                onPageChanged: (index, reason) {
                  _current = index;
                },
              ),
              items: imagePaths.map((imagePath) {
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageZoomPage(
                              imagePaths: imagePaths,
                              initialIndex: _current,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: imagePaths.map((url) {
                int index = imagePaths.indexOf(url);
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _current == index ? Colors.black : Colors.grey,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (stageName.contains('1')) ...[
              Text(
                'Read the question carefully and choose the correct answer. Avoid incorrect answers, or Kladis and Kloud\'s health bars will decrease.',
                style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ] else if (stageName.contains('2')) ...[
              Text(
                'Select a letter one at a time to form an answer. Your answer will be checked instantly once you fill in the last tile. Answer carefully to prevent Kladis and Kloud\'s health bar from going down.',
                style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ] else if (stageName.contains('3')) ...[
              Text(
                'Fill in the blanks with the correct letters to complete the word. Avoid incorrect answers, or Kladis and Kloud\'s health bars will decrease.',
                style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ] else if (stageName.contains('4')) ...[
              Text(
                'Match the items correctly to their corresponding pairs. Avoid incorrect matches, or Kladis and Kloud\'s health bars will decrease.',
                style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ],
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => GameplayPage(
                    language: language,
                    category: category,
                    stageName: stageName,
                    stageData: stageData,
                    mode: mode,
                    gamemode: gamemode,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF351B61),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              'Start Game',
              style: GoogleFonts.vt323(fontSize: 24),
            ),
          ),
        ],
      ),
    ),
  );
}

class ImageZoomPage extends StatelessWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const ImageZoomPage({
    Key? key,
    required this.imagePaths,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoViewGallery.builder(
        itemCount: imagePaths.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: AssetImage(imagePaths[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        pageController: PageController(initialPage: initialIndex),
      ),
    );
  }
}