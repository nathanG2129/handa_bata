import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class TutorialPage extends StatelessWidget {
  final String title;
  final List<String> imagePaths;
  final String description;
  final VoidCallback onNext;
  final bool isLastPage;

  const TutorialPage({
    Key? key,
    required this.title,
    required this.imagePaths,
    required this.description,
    required this.onNext,
    this.isLastPage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int _current = 0;

    return Scaffold(
      backgroundColor: const Color(0xFF5E31AD),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextWithShadow(
              text: 'How to Play',
              fontSize: 36,
            ),
            TextWithShadow(
              text: title,
              fontSize: 36,
            ),
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
            ],
            Text(
              description,
              style: GoogleFonts.rubik(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF351B61),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                isLastPage ? 'Start Game' : 'Next',
                style: GoogleFonts.vt323(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
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