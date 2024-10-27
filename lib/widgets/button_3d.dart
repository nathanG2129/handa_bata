import 'package:flutter/material.dart';

class Button3D extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double width;
  final double height;

  const Button3D({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = const Color(0xFF351b61),
    this.borderColor = Colors.black,
    this.width = double.infinity,
    this.height = 50.0,
  });

  @override
  State<Button3D> createState() => _Button3DState();
}

class _Button3DState extends State<Button3D> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 1),
        transform: Matrix4.translationValues(
          0,
          _isPressed ? 8.0 : 0.0,  // Move down when pressed
          0,
        ),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border(
            top: BorderSide(width: 2.0, color: widget.borderColor),
            left: BorderSide(width: 4.0, color: widget.borderColor),
            right: BorderSide(width: 4.0, color: widget.borderColor),
            bottom: BorderSide(
              width: _isPressed ? 2.0 : 14.0,  // Border changes when pressed
              color: widget.borderColor,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            splashColor: Colors.transparent, // Remove ripple effect
            highlightColor: Colors.transparent, // Remove highlight effect
            child: Center(
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}