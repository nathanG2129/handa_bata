import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ArcadeButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ArcadeButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  _ArcadeButtonState createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
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
        width: 350,
        height: 300,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Positioned(
                right: 180,
                child: Text(
                  'AR\nCA\nDE',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(
                    fontSize: 135,
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
                  width: 210,
                  height: 210,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}