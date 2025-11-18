import 'package:flutter/material.dart';

/// A custom painter that draws the swipe trail during gesture typing.
///
/// This painter creates a smooth, continuous line that follows the user's
/// finger or mouse as they swipe across tiles. The trail provides visual
/// feedback about the swipe path.
///
/// The painter automatically optimizes repainting by checking if the points
/// have changed before redrawing.
///
/// Example:
/// ```dart
/// CustomPaint(
///   painter: SwipeTrailPainter(
///     points: swipePoints,
///     color: Colors.blue,
///     strokeWidth: 8.0,
///   ),
/// )
/// ```
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
  ///
  /// Creates a path connecting all points and draws it with rounded caps
  /// for a smooth appearance. Returns early if there are fewer than 2 points.
  ///
  /// Parameters:
  @override
  void paint(

      /// The canvas to paint on.
      Canvas canvas,

      /// The size of the canvas.
      Size size) {
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

  /// Determines whether the painter should repaint.
  ///
  /// Returns `true` if the points have changed since the last paint,
  /// triggering a repaint. This optimization prevents unnecessary redraws.
  ///
  /// Parameters:
  @override
  bool shouldRepaint(

      /// The old delegate to compare against. It updates the painter only if the points have changed.
      covariant SwipeTrailPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
