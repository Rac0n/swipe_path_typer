

import 'package:flutter/material.dart';

class SwipeTrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  /// Creates a painter for the swipe trail.
  SwipeTrailPainter({
    /// The list of points that form the swipe trail.
    required this.points,
    /// The color of the swipe trail.
    this.color = Colors.black87,
    /// The stroke width of the swipe trail.
    this.strokeWidth = 8.0,
  });


  /// Paints the swipe trail on the canvas.
  @override
  void paint(
    /// The canvas to paint on.
    Canvas canvas,
    /// The size of the canvas.
    Size size
  ) {
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

  /// Indicates whether the painter should repaint when the points change.
  @override
  bool shouldRepaint(
    /// The old delegate to compare against. It updates the painter only if the points have changed.
    covariant SwipeTrailPainter oldDelegate
  ) {
    return oldDelegate.points != points;
  }
}
