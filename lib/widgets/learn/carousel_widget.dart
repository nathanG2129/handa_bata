import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

class CarouselWidget extends StatefulWidget {
  final List<Widget> contents;
  final bool automatic;
  final double height;
  final EdgeInsets padding;

  const CarouselWidget({
    super.key,
    required this.contents,
    this.automatic = true,
    this.height = 300,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  CarouselWidgetState createState() => CarouselWidgetState();
}

class CarouselWidgetState extends State<CarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.automatic) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentIndex < widget.contents.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _getArrowSvg() {
    return '''
      <svg
        width="32"
        height="32"
        fill="white"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
      >
        <path
          d="M10 20H8V4h2v2h2v3h2v2h2v2h-2v2h-2v3h-2v2z"
          fill="currentColor"
        />
      </svg>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              // Carousel content with border
              Positioned.fill(
                left: 40, // Space for arrows
                right: 40,
                child: Container(
                  margin: widget.padding,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: widget.contents.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(0),
                          child: Center(
                            child: widget.contents[index],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Navigation arrows
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: IconButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: Transform.rotate(
                          angle: 3.14159, // 180 degrees in radians
                          child: SvgPicture.string(
                            _getArrowSvg(),
                            width: 32,
                            height: 32,
                            color: const Color(0xFF241242),
                          ),
                        ),
                      ),
                    ),
                    // Next button
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: SvgPicture.string(
                          _getArrowSvg(),
                          width: 32,
                          height: 32,
                          color: const Color(0xFF241242),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Navigation dots
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.contents.length,
            (index) => GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? Colors.black
                      : Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 