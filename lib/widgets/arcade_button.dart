import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart'; // Import responsive_framework

class ArcadeButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ArcadeButton({super.key, required this.onPressed});

  @override
  ArcadeButtonState createState() => ArcadeButtonState();
}

class ArcadeButtonState extends State<ArcadeButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
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
        width: ResponsiveValue<double>(
          context,
          defaultValue: 250.0,
          conditionalValues: [
            Condition.smallerThan(name: MOBILE, value: 180.0),
            Condition.largerThan(name: TABLET, value: 300.0),
          ],
        ).value,
        height: ResponsiveValue<double>(
          context,
          defaultValue: 200.0,
          conditionalValues: [
            Condition.smallerThan(name: MOBILE, value: 130.0),
            Condition.largerThan(name: TABLET, value: 250.0),
          ],
        ).value,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 165),
          curve: Curves.easeInOut,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Positioned(
                right: 120,
                child: Text(
                  'AR\nCA\nDE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(
                    fontSize: ResponsiveValue<double>(
                      context,
                      defaultValue: 100.0,
                      conditionalValues: [
                        Condition.smallerThan(name: MOBILE, value: 70.0),
                        Condition.largerThan(name: TABLET, value: 120.0),
                      ],
                    ).value,
                    height: 0.7,
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        offset: Offset(0, 5.0), // Shadow only at the bottom
                        blurRadius: 5.0,
                        color: Color(0xFF241242), // Updated shadow color
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: SvgPicture.asset(
                  'assets/characters/KloudArcade.svg',
                  width: ResponsiveValue<double>(
                    context,
                    defaultValue: 150.0,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 100.0),
                      Condition.largerThan(name: TABLET, value: 200.0),
                    ],
                  ).value,
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: 150.0,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 100.0),
                      Condition.largerThan(name: TABLET, value: 200.0),
                    ],
                  ).value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}