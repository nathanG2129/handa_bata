import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HoverableText extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const HoverableText({required this.text, required this.onTap, super.key});

  @override
  _HoverableTextState createState() => _HoverableTextState();
}

class _HoverableTextState extends State<HoverableText> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: 20,
            decoration: _isHovering ? TextDecoration.underline : TextDecoration.none,
            decorationColor: Colors.white,
            decorationThickness: 2.0, // Thicker underline
          ),
        ),
      ),
    );
  }
}