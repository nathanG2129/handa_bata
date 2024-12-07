import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:handabatamae/game/prerequisite/tutorial_localization.dart';
import 'package:handabatamae/game/prerequisite/tutorial_resources.dart';
import 'package:handabatamae/widgets/learn/carousel_widget.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class TutorialDialog extends StatefulWidget {
  final String questionType;
  final String language;
  final String category;
  final String stageName;

  const TutorialDialog({
    super.key,
    required this.questionType,
    required this.language,
    required this.category,
    required this.stageName,
  });

  @override
  TutorialDialogState createState() => TutorialDialogState();
}

class TutorialDialogState extends State<TutorialDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  YoutubePlayerController? _controller;
  bool _showingEducationalContent = false;
  bool _showingFloodStage3Infographic = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<Widget> _getTutorialImages(String questionType) {
    List<String> imagePaths;
    switch (questionType) {
      case 'Multiple Choice':
        imagePaths = const [
          'assets/instructions/MultipleChoice01.png',
          'assets/instructions/MultipleChoice02.png',
        ];
        break;
      case 'Fill in the Blanks':
        imagePaths = const [
          'assets/instructions/FillinTheBlanks01.png',
          'assets/instructions/FillinTheBlanks02.png',
          'assets/instructions/FillinTheBlanks03.png',
          'assets/instructions/FillinTheBlanks04.png',
        ];
        break;
      case 'Matching Type':
        imagePaths = const [
          'assets/instructions/MatchingType01.png',
          'assets/instructions/MatchingType02.png',
          'assets/instructions/MatchingType03.png',
          'assets/instructions/MatchingType04.png',
          'assets/instructions/MatchingType05.png',
        ];
        break;
      case 'Identification':
        imagePaths = const [
          'assets/instructions/Identification01.png',
          'assets/instructions/Identification02.png',
          'assets/instructions/Identification03.png',
          'assets/instructions/Identification04.png',
        ];
        break;
      default:
        imagePaths = const [];
    }

    return imagePaths.map((path) => Image.asset(path, fit: BoxFit.contain)).toList();
  }

  Widget _buildEducationalContent() {
    String? videoId;
    String? infographicPath;
    String description = '';

    print('Building educational content for:');
    print('Category: ${widget.category}');
    print('Stage Name: ${widget.stageName}');

    final String lowerCategory = widget.category.toLowerCase();
    
    if (lowerCategory.contains('storm')) {
      if (widget.stageName.contains('1')) {
        print('Storm Stage 1: Loading video content');
        videoId = 'uz9sclC3nBE';
        description = 'Alam mo ba? Bagyo';
      } else if (widget.stageName.contains('3')) {
        print('Storm Stage 3: Loading rainfall warning system infographic');
        infographicPath = 'assets/images/infographics/RainfallWarningSystemPayongPAGASA.jpeg';
        description = 'PAGASA Rainfall Warning System';
      } else if (widget.stageName.contains('4')) {
        print('Storm Stage 4: Loading tropical cyclone warning system infographic');
        infographicPath = 'assets/images/infographics/TropicalCycloneWarningSystemPayongPAGASA.jpeg';
        description = 'PAGASA Tropical Cyclone Warning System';
      }
    } else if (lowerCategory.contains('quake')) {
      if (widget.stageName.contains('3')) {
        print('Quake Stage 3: Loading earthquake intensity scale infographic');
        infographicPath = 'assets/images/infographics/PHIVOLCSEarthquakeIntensityScale.jpg';
        description = 'PHIVOLCS Earthquake Intensity Scale';
      } else if (widget.stageName.contains('4')) {
        print('Quake Stage 4: Loading video content');
        videoId = 'XUoYj1fN2Cs';
        description = 'Duck, Cover, and Hold';
      }
    } else if (lowerCategory.contains('drought')) {
      if (widget.stageName.contains('1')) {
        print('Drought Stage 1: Loading infographic');
        infographicPath = 'assets/images/infographics/Drought_Preparedness.jpeg';
        description = 'Drought Preparedness Guide';
      } else if (widget.stageName.contains('4')) {
        print('Drought Stage 4: Loading video content');
        videoId = 'zddS3dJupno';
        description = 'Mga Hakbang sa Pagbuo ng Community Based DRRMP';
      }
    } else if (lowerCategory.contains('flood')) {
      if (widget.stageName.contains('1')) {
        print('Flood Stage 1: Loading video content');
        videoId = 'l0hsjostU_g';
        description = 'Heavy Rainfall and Thunderstorm Warning System';
      } else if (widget.stageName.contains('3')) {
        print('Flood Stage 3: Loading content');
        if (_showingFloodStage3Infographic) {
          infographicPath = 'assets/images/infographics/GabaySaMgaAbiso,Klasipikasyon,AtSukatNgUlan.jpg';
          description = 'Gabay sa mga Abiso, Klasipikasyon, at Sukat ng Ulan';
        } else {
          videoId = 'uys9waXWW3M';
          description = 'Ano-ano ang yellow, orange at red rainfall warning?';
        }
      } else if (widget.stageName.contains('4')) {
        print('Flood Stage 4: Loading heavy rainfall warnings');
        infographicPath = 'assets/images/infographics/HeavyRainfallWarningsByThePhilippineInformationAgency.jpg';
        description = 'Heavy Rainfall Warnings';
      }
    } else if (lowerCategory.contains('volcanic')) {
      if (widget.stageName.contains('1')) {
        print('Volcanic Stage 1: Loading infographic');
        infographicPath = 'assets/images/infographics/VolcanicEruption.jpg';
        description = 'Volcanic Eruption Safety Guide';
      } else if (widget.stageName.contains('4')) {
        print('Volcanic Stage 4: Loading infographic');
        infographicPath = 'assets/images/infographics/EmergencyGoBag.jfif';
        description = 'Emergency Go Bag';
      }
    } else {
      print('No educational content found for this category');
    }

    if (videoId != null) {
      print('Loading video with ID: $videoId');
      return Column(
        children: [
          _buildVideoPlayer(videoId),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.rubik(
              fontSize: 18,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (infographicPath != null) {
      return Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageZoomPage(
                    imagePaths: [infographicPath!],
                    initialIndex: 0,
                  ),
                ),
              );
            },
            child: Image.asset(infographicPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.rubik(
              fontSize: 18,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Container();
  }

  Widget _buildVideoPlayer(String videoId) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.shortestSide >= 600;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    final double videoWidth = isTablet 
        ? screenWidth * 0.6
        : screenWidth * 0.85;
    
    final double videoHeight = videoWidth * 9 / 16;
    final double maxHeight = screenHeight * 0.4;
    final double finalHeight = videoHeight > maxHeight ? maxHeight : videoHeight;

    return GestureDetector(
      onTap: () => _showFullScreenVideo(context, videoId),
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
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
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

  void _showFullScreenVideo(BuildContext context, String videoId) {
    if (_controller == null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          hideControls: false,
          showLiveFullscreenButton: true,
        ),
      );
    }

    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.shortestSide >= 600;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    final double maxVideoWidth = isTablet ? screenWidth * 0.8 : screenWidth;
    final double maxVideoHeight = maxVideoWidth * 9 / 16;
    
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
                    child: SizedBox(
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
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.shortestSide >= 600;
    final double dialogWidth = isTablet ? 450 : 300;
    final double maxDialogHeight = screenSize.height * 0.8;

    return WillPopScope(
      onWillPop: () async {
        await _closeDialog();
        return false;
      },
      child: GestureDetector(
        onTap: _closeDialog,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: Container(
            color: Colors.black.withOpacity(0),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // Prevents tap from propagating
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: dialogWidth,
                      constraints: BoxConstraints(
                        maxHeight: maxDialogHeight,
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: isTablet ? 40.0 : 20.0,
                        vertical: 24.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF351B61),
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Text(
                                _showingEducationalContent
                                    ? TutorialResources.getResourceTypeTitle(
                                        widget.stageName.contains('1') ? 'video' : 'infographic',
                                        widget.language,
                                      )
                                    : TutorialLocalization.getTitle(
                                        'adventure',
                                        widget.questionType.toLowerCase().replaceAll(' ', '_'),
                                        widget.language,
                                      ),
                                style: GoogleFonts.vt323(
                                  color: Colors.white,
                                  fontSize: isTablet ? 28 : 24,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24.0 : 20.0,
                                  vertical: isTablet ? 12.0 : 10.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_showingEducationalContent)
                                      _buildEducationalContent()
                                    else ...[
                                      CarouselWidget(
                                        height: 200,
                                        automatic: true,
                                        contents: _getTutorialImages(widget.questionType),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        TutorialLocalization.getDescription(
                                          'adventure',
                                          widget.questionType.toLowerCase().replaceAll(' ', '_'),
                                          widget.language,
                                        ),
                                        style: GoogleFonts.rubik(
                                          fontSize: isTablet ? 20 : 16,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: const Color(0xFF241242),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 20.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_showingEducationalContent)
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            if (widget.category.toLowerCase().contains('flood') && 
                                                widget.stageName.contains('3')) {
                                              _showingFloodStage3Infographic = !_showingFloodStage3Infographic;
                                            } else {
                                              _showingEducationalContent = false;
                                            }
                                          });
                                        },
                                        child: Text(
                                          widget.category.toLowerCase().contains('flood') && 
                                          widget.stageName.contains('3') && !_showingFloodStage3Infographic
                                              ? 'View Infographic'
                                              : 'Back',
                                          style: GoogleFonts.vt323(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else if (_hasEducationalContent())
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showingEducationalContent = true;
                                        _showingFloodStage3Infographic = false;
                                      });
                                    },
                                    child: Text(
                                      'Learn More',
                                      style: GoogleFonts.vt323(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                TextButton(
                                  onPressed: _closeDialog,
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.vt323(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasEducationalContent() {
    final String lowerCategory = widget.category.toLowerCase();
    final bool hasContent = (widget.stageName.contains('1') && lowerCategory.contains('storm')) ||
           (widget.stageName.contains('3') && lowerCategory.contains('storm')) ||
           (widget.stageName.contains('4') && lowerCategory.contains('storm')) ||
           (widget.stageName.contains('3') && lowerCategory.contains('quake')) ||
           (widget.stageName.contains('4') && lowerCategory.contains('quake')) ||
           (widget.stageName.contains('1') && lowerCategory.contains('drought')) ||
           (widget.stageName.contains('4') && lowerCategory.contains('drought')) ||
           (widget.stageName.contains('1') && lowerCategory.contains('flood')) ||
           (widget.stageName.contains('3') && lowerCategory.contains('flood')) ||
           (widget.stageName.contains('4') && lowerCategory.contains('flood')) ||
           (widget.stageName.contains('1') && lowerCategory.contains('volcanic')) ||
           (widget.stageName.contains('4') && lowerCategory.contains('volcanic'));

    print('Checking for educational content:');
    print('Category: ${widget.category}');
    print('Stage Name: ${widget.stageName}');
    print('Category (lowercase): $lowerCategory');
    print('Has Educational Content: $hasContent');

    return hasContent;
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