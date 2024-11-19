import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SpriteAnimation extends StatefulWidget {
  final String spritePath;
  final int frameCount;
  final int row;
  final double frameWidth;
  final double frameHeight;
  final Duration duration;
  final bool isLooping;
  final double scale;
  final int startFrame;

  const SpriteAnimation({
    super.key,
    required this.spritePath,
    required this.frameCount,
    required this.row,
    required this.frameWidth,
    required this.frameHeight,
    required this.duration,
    this.isLooping = false,
    this.scale = 4.0,
    this.startFrame = 0,
  });

  @override
  State<SpriteAnimation> createState() => _SpriteAnimationState();
}

class _SpriteAnimationState extends State<SpriteAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _frameAnimation;
  late ImageProvider _spriteImage;
  late ImageStream _imageStream;
  late ImageInfo? _imageInfo;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadImage();
  }

  void _initAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _frameAnimation = IntTween(
      begin: 0,
      end: widget.frameCount - 1,
    ).animate(_controller);

    if (widget.isLooping) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  void _loadImage() {
    _spriteImage = AssetImage(widget.spritePath);
    _imageStream = _spriteImage.resolve(const ImageConfiguration());
    
    _imageStream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _imageInfo = info;
        _isImageLoaded = true;
      });
    }));
  }

  @override
  void dispose() {
    _controller.dispose();
    _imageStream.removeListener(ImageStreamListener((ImageInfo info, bool _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isImageLoaded) {
      return SizedBox(
        width: widget.frameWidth * widget.scale,
        height: widget.frameHeight * widget.scale,
      );
    }

    return AnimatedBuilder(
      animation: _frameAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(
            widget.frameWidth * widget.scale,
            widget.frameHeight * widget.scale,
          ),
          painter: _SpritePainter(
            image: _imageInfo!.image,
            frameIndex: _frameAnimation.value,
            row: widget.row,
            frameWidth: widget.frameWidth,
            frameHeight: widget.frameHeight,
            scale: widget.scale,
            startFrame: widget.startFrame,
          ),
        );
      },
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frameIndex;
  final int row;
  final double frameWidth;
  final double frameHeight;
  final double scale;
  final int startFrame;

  _SpritePainter({
    required this.image,
    required this.frameIndex,
    required this.row,
    required this.frameWidth,
    required this.frameHeight,
    required this.scale,
    required this.startFrame,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.none;  // For pixel perfect rendering

    // Add debug print to verify frame calculations
    print('🎨 Drawing frame $frameIndex at row $row');
    print('🎨 Source rect: x=${frameIndex * frameWidth}, y=${row * frameHeight}');

    final Rect src = Rect.fromLTWH(
      (frameIndex + startFrame) * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );

    final Rect dst = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(_SpritePainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex;
  }
} 