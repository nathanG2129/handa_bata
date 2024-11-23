import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        // Get responsive values for border widths
        final borderWidth = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 2.0,
          tablet: 3.0,
          desktop: 4.0,
        );

        final bottomBorderWidth = ResponsiveUtils.valueByDevice<double>(
          context: context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        );

        // Scale the child widget (which contains the text)
        final scaledChild = DefaultTextStyle(
          style: GoogleFonts.vt323(
            fontSize: ResponsiveUtils.valueByDevice<double>(
              context: context,
              mobile: 20.0,
              tablet: 24.0,
              desktop: 28.0,
            ),
            color: Colors.white,
          ),
          child: widget.child,
        );

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
                top: BorderSide(width: borderWidth, color: widget.borderColor),
                left: BorderSide(width: borderWidth, color: widget.borderColor),
                right: BorderSide(width: borderWidth, color: widget.borderColor),
                bottom: BorderSide(
                  width: _isPressed ? borderWidth : bottomBorderWidth,
                  color: widget.borderColor,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(
                      ResponsiveUtils.valueByDevice<double>(
                        context: context,
                        mobile: 8.0,
                        tablet: 12.0,
                        desktop: 16.0,
                      ),
                    ),
                    child: scaledChild,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}