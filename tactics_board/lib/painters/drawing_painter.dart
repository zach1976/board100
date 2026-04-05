import 'dart:math';
import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final String? selectedStrokeId;

  const DrawingPainter({required this.strokes, this.currentStroke, this.selectedStrokeId});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (selectedStrokeId != null && stroke.id == selectedStrokeId) {
        // Draw glow behind selected stroke
        final glowPaint = Paint()
          ..color = Colors.yellow.withValues(alpha: 0.4)
          ..strokeWidth = stroke.width + 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final path = _buildPath(stroke);
        canvas.drawPath(path, glowPaint);
      }
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
  }

  Path _buildPath(DrawingStroke stroke) {
    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      if (i == 1) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      } else {
        final mid = (stroke.points[i - 1] + stroke.points[i]) / 2;
        path.quadraticBezierTo(stroke.points[i - 1].dx, stroke.points[i - 1].dy, mid.dx, mid.dy);
      }
    }
    path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
    return path;
  }

  void _paintStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      if (i == 1) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      } else {
        final mid = (stroke.points[i - 1] + stroke.points[i]) / 2;
        path.quadraticBezierTo(
          stroke.points[i - 1].dx,
          stroke.points[i - 1].dy,
          mid.dx,
          mid.dy,
        );
      }
    }
    // Close to last point
    path.lineTo(stroke.points.last.dx, stroke.points.last.dy);

    if (stroke.style == StrokeStyle.dashed) {
      _drawDashedPath(canvas, paint, path);
    } else {
      canvas.drawPath(path, paint);
    }

    // Draw arrow
    if (stroke.arrow != ArrowStyle.none && stroke.points.length >= 2) {
      _drawArrowHead(canvas, paint, stroke.points, stroke.arrow);
    }
  }

  void _drawDashedPath(Canvas canvas, Paint paint, Path path) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double start = 0;
      bool draw = true;
      const dashLen = 12.0;
      const gapLen = 8.0;
      while (start < metric.length) {
        final seg = draw ? dashLen : gapLen;
        final end = (start + seg).clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        start = end;
        draw = !draw;
      }
    }
  }

  void _drawArrowHead(
      Canvas canvas, Paint paint, List<Offset> points, ArrowStyle arrow) {
    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    if (arrow == ArrowStyle.end || arrow == ArrowStyle.both) {
      final dir = _stableDirection(points, fromEnd: true);
      _arrowAt(canvas, arrowPaint, points.last, dir, paint.strokeWidth);
    }
    if (arrow == ArrowStyle.both && points.length >= 2) {
      final dir = _stableDirection(points, fromEnd: false);
      _arrowAt(canvas, arrowPaint, points.first, dir, paint.strokeWidth);
    }
  }

  /// Get a stable direction angle by looking at a segment farther back,
  /// not just the last two (often jittery) points.
  double _stableDirection(List<Offset> points, {required bool fromEnd}) {
    const minDist = 20.0; // look back at least 20px for stable angle
    if (fromEnd) {
      final tip = points.last;
      for (int i = points.length - 2; i >= 0; i--) {
        if ((points[i] - tip).distance >= minDist) {
          return atan2(tip.dy - points[i].dy, tip.dx - points[i].dx);
        }
      }
      final p = points[max(0, points.length - 2)];
      return atan2(tip.dy - p.dy, tip.dx - p.dx);
    } else {
      final tip = points.first;
      for (int i = 1; i < points.length; i++) {
        if ((points[i] - tip).distance >= minDist) {
          return atan2(tip.dy - points[i].dy, tip.dx - points[i].dx);
        }
      }
      final p = points[min(1, points.length - 1)];
      return atan2(tip.dy - p.dy, tip.dx - p.dx);
    }
  }

  void _arrowAt(Canvas canvas, Paint paint, Offset tip, double angle, double width) {
    final arrowSize = (width * 2.5 + 4).clamp(10.0, 22.0);
    final spread = pi / 5; // 36 degrees each side
    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * cos(angle - spread),
      tip.dy - arrowSize * sin(angle - spread),
    );
    path.lineTo(
      tip.dx - arrowSize * cos(angle + spread),
      tip.dy - arrowSize * sin(angle + spread),
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.currentStroke != currentStroke || oldDelegate.selectedStrokeId != selectedStrokeId;
}
