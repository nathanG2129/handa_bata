import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:handabatamae/utils/responsive_utils.dart';

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
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        // Calculate responsive sizes
        final arrowSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 28.0,
          tablet: 32.0,
          desktop: 36.0,
        );

        final arrowPadding = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 12.0,
          tablet: 16.0,
          desktop: 20.0,
        );

        final dotSize = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        );

        final borderWidth = ResponsiveUtils.valueByDevice(
          context: context,
          mobile: 2.0,
          tablet: 2.5,
          desktop: 3.0,
        );

        // Calculate aspect ratio container width based on height
        final containerWidth = widget.height * (16 / 9);
        
        // Calculate arrow container width (smaller than before)
        final arrowContainerWidth = arrowSize + (arrowPadding * 2);
        
        // Calculate total width including smaller arrow space
        final totalWidth = containerWidth + (arrowContainerWidth * 2);

        return Column(
          children: [
            SizedBox(
              height: widget.height,
              width: totalWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Carousel content with border
                  Container(
                    width: containerWidth,
                    margin: widget.padding,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: borderWidth,
                      ),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemCount: widget.contents.length,
                          itemBuilder: (context, index) {
                            return widget.contents[index];
                          },
                        ),
                      ),
                    ),
                  ),
                  // Navigation arrows with container
                  Positioned.fill(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: arrowContainerWidth,
                          alignment: Alignment.center,
                          child: IconButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: Transform.rotate(
                              angle: 3.14159,
                              child: SvgPicture.string(
                                _getArrowSvg(),
                                width: arrowSize,
                                height: arrowSize,
                                color: const Color(0xFF241242),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: arrowContainerWidth,
                          alignment: Alignment.center,
                          child: IconButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: SvgPicture.string(
                              _getArrowSvg(),
                              width: arrowSize,
                              height: arrowSize,
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
                    width: dotSize,
                    height: dotSize,
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
      },
    );
  }
} 