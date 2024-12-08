import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:handabatamae/widgets/resources/resource_grid.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

class ResourcePreview extends StatefulWidget {
  final ResourceData data;
  final String category;

  const ResourcePreview({
    super.key,
    required this.data,
    required this.category,
  });

  @override
  State<ResourcePreview> createState() => _ResourcePreviewState();
}

class _ResourcePreviewState extends State<ResourcePreview> {
  YoutubePlayerController? _controller;
  bool get isVideo => widget.category == 'Videos';

  String getYoutubeThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  void _showFullScreenVideo(BuildContext context) {
    _controller = YoutubePlayerController(
      initialVideoId: widget.data.src,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: false,
        showLiveFullscreenButton: true,
      ),
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0),
      builder: (context) => TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Dialog(
              backgroundColor: Colors.transparent.withOpacity(value * 0.9),
              insetPadding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // YouTube Player
                  Center(
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
                      onPressed: () {
                        _controller?.dispose();
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
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0),
      builder: (context) => TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Dialog(
              backgroundColor: Colors.transparent.withOpacity(value * 0.9),
              insetPadding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image with zoom capability
                  PhotoView(
                    imageProvider: AssetImage(widget.data.src),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    backgroundDecoration: BoxDecoration(
                      color: Colors.black87.withOpacity(value),
                    ),
                  ),
                  
                  // Top bar with title, back and download buttons
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7 * value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          // Back button
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: SvgPicture.string(
                              '''<svg
                                width="32"
                                height="32"
                                fill="white"
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24">
                                <path
                                  d="M10 20H8V4h2v2h2v3h2v2h2v2h-2v2h-2v3h-2v2z"
                                  fill="white"/>
                              </svg>''',
                              width: 32,
                              height: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Title
                          Expanded(
                            child: Text(
                              widget.data.title,
                              style: GoogleFonts.rubik(
                                fontSize: 20,
                                color: Colors.white.withOpacity(value),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Download button
                          InkWell(
                            onTap: () {
                              // Implement download functionality
                            },
                            child: SvgPicture.string(
                              '''<svg
                                width="24"
                                height="24"
                                fill="white"
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24">
                                <path
                                  d="M13 17V3h-2v10H9v-2H7v2h2v2h2v2h2zm8 2v-4h-2v4H5v-4H3v6h18v-2zm-8-6v2h2v-2h2v-2h-2v2h-2z"
                                  fill="white"/>
                              </svg>''',
                              width: 0,
                              height: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    final referenceFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 16.0,
      tablet: 14.0,
      desktop: 22.0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isVideo ? () => _showFullScreenVideo(context) : () => _showFullScreenImage(context),
          child: Column(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Image or Video thumbnail
                        if (isVideo)
                          Image.network(
                            getYoutubeThumbnail(widget.data.src),
                            fit: BoxFit.contain,
                            // Improved error handling
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 320,
                                height: 180,
                                color: Colors.black12,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 320,
                                height: 180,
                                color: Colors.black26,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.video_library,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Video Preview',
                                      style: GoogleFonts.rubik(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        else
                          Image.asset(
                            widget.data.thumbnailPath,  // Use thumbnailPath for preview
                            fit: BoxFit.contain,
                          ),
                        // Play button overlay for videos
                        if (isVideo)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Text information
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.data.title,
                      style: GoogleFonts.rubik(
                        fontSize: titleFontSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data.reference,
                      style: GoogleFonts.rubik(
                        fontSize: referenceFontSize,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 