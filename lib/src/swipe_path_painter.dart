

import 'package:flutter/material.dart';

class SwipeTrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  SwipeTrailPainter({
    required this.points,
    this.color = Colors.black87,
    this.strokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SwipeTrailPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
