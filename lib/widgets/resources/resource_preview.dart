import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:handabatamae/widgets/resources/resource_grid.dart';
import 'package:photo_view/photo_view.dart';

class ResourcePreview extends StatelessWidget {
  final ResourceData data;
  final String category;

  const ResourcePreview({
    super.key,
    required this.data,
    required this.category,
  });

  bool get isVideo => category == 'Videos';

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with zoom capability
            PhotoView(
              imageProvider: AssetImage(data.src),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
            // Close button
            Positioned(
              right: 16,
              top: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Download button
            Positioned(
              right: 16,
              bottom: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  // Implement download functionality
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isVideo ? null : () => _showFullScreenImage(context),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  child: isVideo
                      ? YoutubePlayer(
                          controller: YoutubePlayerController(
                            initialVideoId: data.src,
                            flags: const YoutubePlayerFlags(
                              autoPlay: false,
                              mute: true,
                              hideControls: false,
                            ),
                          ),
                        )
                      : Image.asset(
                          data.thumbnailPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      data.title,
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.reference,
                      style: GoogleFonts.rubik(
                        fontSize: 12,
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