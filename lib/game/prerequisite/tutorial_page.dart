import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';

class TutorialPage extends StatefulWidget {
  final String title;
  final List<String> imagePaths;
  final String description;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final bool isLastPage;
  final bool isFirstPage;

  const TutorialPage({
    super.key,
    required this.title,
    required this.imagePaths,
    required this.description,
    required this.onNext,
    this.onBack,
    this.isLastPage = false,
    this.isFirstPage = true,
  });

  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!widget.isFirstPage && widget.onBack != null) {
          widget.onBack!();
          return false;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF5E31AD),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const TextWithShadow(
                text: 'How to Play',
                fontSize: 36,
              ),
              TextWithShadow(
                text: widget.title,
                fontSize: 36,
              ),
              const SizedBox(height: 20),
              if (widget.imagePaths.isNotEmpty) ...[
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200.0,
                    enableInfiniteScroll: false,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _current = index;
                      });
                    },
                  ),
                  items: widget.imagePaths.map((imagePath) {
                    return Builder(
                      builder: (BuildContext context) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageZoomPage(
                                  imagePaths: widget.imagePaths,
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
                  children: widget.imagePaths.map((url) {
                    int index = widget.imagePaths.indexOf(url);
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.description,
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!widget.isFirstPage) ...[
                    Button3D(
                      onPressed: widget.onBack!,
                      backgroundColor: const Color(0xFF351B61),
                      width: 120,
                      child: Text(
                        'Back',
                        style: GoogleFonts.vt323(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                  Button3D(
                    onPressed: widget.onNext,
                    backgroundColor: const Color(0xFF351B61),
                    width: 120,
                    child: Text(
                      widget.isLastPage ? 'Start Game' : 'Next',
                      style: GoogleFonts.vt323(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageZoomPage extends StatelessWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const ImageZoomPage({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

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