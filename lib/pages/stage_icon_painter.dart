import 'package:flutter/material.dart';

class StageIconPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  StageIconPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final path1 = Path()
      ..moveTo(8, 0)
      ..lineTo(4, 0)
      ..lineTo(4, 1)
      ..lineTo(2, 1)
      ..lineTo(2, 2)
      ..lineTo(1, 2)
      ..lineTo(1, 4)
      ..lineTo(0, 4)
      ..lineTo(0, 7)
      ..lineTo(1, 7)
      ..lineTo(1, 9)
      ..lineTo(2, 9)
      ..lineTo(2, 10)
      ..lineTo(4, 10)
      ..lineTo(4, 11)
      ..lineTo(8, 11)
      ..lineTo(8, 10)
      ..lineTo(10, 10)
      ..lineTo(10, 9)
      ..lineTo(11, 9)
      ..lineTo(11, 7)
      ..lineTo(12, 7)
      ..lineTo(12, 4)
      ..lineTo(11, 4)
      ..lineTo(11, 2)
      ..lineTo(10, 2)
      ..lineTo(10, 1)
      ..lineTo(8, 1)
      ..close();

    final path2 = Path()
      ..moveTo(4, 1)
      ..lineTo(8, 1)
      ..lineTo(8, 2)
      ..lineTo(10, 2)
      ..lineTo(10, 4)
      ..lineTo(11, 4)
      ..lineTo(11, 7)
      ..lineTo(10, 7)
      ..lineTo(10, 9)
      ..lineTo(8, 9)
      ..lineTo(8, 10)
      ..lineTo(4, 10)
      ..lineTo(4, 9)
      ..lineTo(2, 9)
      ..lineTo(2, 7)
      ..lineTo(1, 7)
      ..lineTo(1, 4)
      ..lineTo(2, 4)
      ..lineTo(2, 2)
      ..lineTo(4, 2)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}