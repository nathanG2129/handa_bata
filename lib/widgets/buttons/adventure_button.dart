import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AdventureButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AdventureButton({super.key, required this.onPressed});

  @override
  AdventureButtonState createState() => AdventureButtonState();
}

class AdventureButtonState extends State<AdventureButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        final buttonWidth = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 300,
          tablet: 350,
          desktop: 400,
        );

        final buttonHeight = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 250,
          tablet: 300,
          desktop: 350,
        );

        final fontSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 100,
          tablet: 120,
          desktop: 135,
        );

        final imageSize = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 170,
          tablet: 190,
          desktop: 210,
        );

        final textOffset = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 135,
          tablet: 150,
          desktop: 180,
        );

        return GestureDetector(
          onTapDown: (_) {
            setState(() {
              _scale = 1.1;
            });
          },
          onTapUp: (_) {
            setState(() {
              _scale = 1.0;
            });
            widget.onPressed();
          },
          onTapCancel: () {
            setState(() {
              _scale = 1.0;
            });
          },
          child: SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 165),
              curve: Curves.easeInOut,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: textOffset,
                    child: Text(
                      'ADV\nENT\nURE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.vt323(
                        fontSize: fontSize,
                        height: 0.7,
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            offset: Offset(0, 5.0),
                            blurRadius: 5.0,
                            color: Color(0xFF241242),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    child: SvgPicture.asset(
                      'assets/characters/KladisAdventure.svg',
                      width: imageSize,
                      height: imageSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}