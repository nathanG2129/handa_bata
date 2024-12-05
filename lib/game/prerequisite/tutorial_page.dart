import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/widgets/learn/carousel_widget.dart';
import 'package:handabatamae/game/prerequisite/tutorial_localization.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TutorialPage extends StatefulWidget {
  final String title;
  final List<String> imagePaths;
  final String description;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final bool isLastPage;
  final bool isFirstPage;
  final String language;
  final String? videoId;
  final bool isGameTutorial;

  const TutorialPage({
    super.key,
    required this.title,
    required this.imagePaths,
    required this.description,
    required this.onNext,
    this.onBack,
    this.isLastPage = false,
    this.isFirstPage = true,
    required this.language,
    this.videoId,
    this.isGameTutorial = false,
  });

  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  int _current = 0;
  YoutubePlayerController? _controller;
  // ignore: unused_field
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    // Don't initialize video player immediately
  }

  void _initializeVideoPlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        hideControls: false,
        showLiveFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.shortestSide >= 600;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Calculate dimensions based on screen size and device type
    final double videoWidth = isTablet 
        ? screenWidth * 0.6  // 60% of screen width for tablets
        : screenWidth * 0.85; // 85% of screen width for phones
    
    final double videoHeight = videoWidth * 9 / 16; // Maintain 16:9 aspect ratio
    
    // Ensure height doesn't exceed screen height
    final double maxHeight = screenHeight * 0.4; // Max 40% of screen height
    final double finalHeight = videoHeight > maxHeight ? maxHeight : videoHeight;

    return GestureDetector(
      onTap: () => _showFullScreenVideo(context),
      child: Container(
        height: finalHeight,
        width: videoWidth,
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 32.0 : 16.0,
          vertical: 8.0,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Play button overlay
            Container(
              width: isTablet ? 80 : 60,
              height: isTablet ? 80 : 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: isTablet ? 60 : 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenVideo(BuildContext context) {
    if (_controller == null) {
      _initializeVideoPlayer();
    }

    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.shortestSide >= 600;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Calculate dimensions for full-screen mode
    final double maxVideoWidth = isTablet ? screenWidth * 0.8 : screenWidth;
    final double maxVideoHeight = maxVideoWidth * 9 / 16;
    
    // Ensure video doesn't exceed screen height
    final double finalVideoHeight = maxVideoHeight > screenHeight * 0.9 
        ? screenHeight * 0.9 
        : maxVideoHeight;
    final double finalVideoWidth = finalVideoHeight * 16 / 9;

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Dialog(
              backgroundColor: Colors.black,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Container(
                      width: finalVideoWidth,
                      height: finalVideoHeight,
                      child: YoutubePlayer(
                        controller: _controller!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.red,
                        progressColors: const ProgressBarColors(
                          playedColor: Colors.red,
                          handleColor: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        _controller?.dispose();
                        _controller = null;
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      _controller?.dispose();
      _controller = null;
    });
  }

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
              if (widget.isGameTutorial) ...[
                TextWithShadow(
                  text: TutorialLocalization.getUIText('headers', 'how_to_play', widget.language),
                  fontSize: 36,
                ),
              ],
              TextWithShadow(
                text: widget.title,
                fontSize: 36,
              ),
              const SizedBox(height: 20),
              if (widget.videoId != null) ...[
                _buildVideoPlayer(),
              ] else if (widget.imagePaths.isNotEmpty) ...[
                CarouselWidget(
                  height: 200,
                  automatic: false,
                  contents: _buildCarouselContents(),
                ),
              ],
              const SizedBox(height: 20),
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
                      child: Text(
                        TutorialLocalization.getUIText('buttons', 'back', widget.language),
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
                    child: Text(
                      widget.isLastPage 
                        ? TutorialLocalization.getUIText('buttons', 'start_game', widget.language)
                        : TutorialLocalization.getUIText('buttons', 'next', widget.language),
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

  List<Widget> _buildCarouselContents() {
    return widget.imagePaths.map((imagePath) {
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
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.fill,
            ),
          ),
        ),
      );
    }).toList();
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          PhotoViewGallery.builder(
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
          // Close button at top-right
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}