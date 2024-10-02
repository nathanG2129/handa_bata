import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AdventureButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AdventureButton({super.key, required this.onPressed});

  @override
  _AdventureButtonState createState() => _AdventureButtonState();
}

class _AdventureButtonState extends State<AdventureButton> {
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
          duration: const Duration(milliseconds: 165),
          curve: Curves.easeInOut,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: 160,
                child: Text(
                  'ADV\nENT\nURE',
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
                left: 0,
                child: SvgPicture.asset(
                  'assets/characters/KladisAdventure.svg',
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