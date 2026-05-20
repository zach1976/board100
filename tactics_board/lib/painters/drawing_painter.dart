import 'dart:math';
import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final String? selectedStrokeId;
  /// IDs of strokes included in the multi-select set. Drawn with the same
  /// glow as the single-select highlight, but in a green tint so it reads
  /// as part of a group selection rather than the focused single edit.
  final Set<String> multiSelectStrokeIds;

  const DrawingPainter({
    required this.strokes,
    this.currentStroke,
    this.selectedStrokeId,
    this.multiSelectStrokeIds = const {},
  });

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
      } else if (multiSelectStrokeIds.contains(stroke.id)) {
        final glowPaint = Paint()
          ..color = const Color(0xFF00C2B2).withValues(alpha: 0.55)
          ..strokeWidth = stroke.width + 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawPath(_buildPath(stroke), glowPaint);
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

    // Use a square (butt) cap when an arrow is attached so the rounded
    // cap doesn't blob past the arrow tip on thick strokes — the arrow
    // triangle covers the join. Round cap stays for plain strokes.
    final hasEndArrow =
        stroke.arrow == ArrowStyle.end || stroke.arrow == ArrowStyle.both;
    final hasStartArrow = stroke.arrow == ArrowStyle.both;
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap =
          (hasEndArrow || hasStartArrow) ? StrokeCap.butt : StrokeCap.round
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

    // Trim the path so the arrow head replaces the last (and optionally
    // first) chunk of the line. Prevents thick-stroke blob where the
    // round cap pokes past the arrow tip and gives the arrow a clean
    // triangular silhouette instead of one stacked on a wider tail.
    Path drawPath = path;
    if (hasEndArrow || hasStartArrow) {
      final arrowSize = _arrowSize(stroke.width);
      final trim = arrowSize * 0.55;
      drawPath = _trimEnds(
        path,
        trimStart: hasStartArrow ? trim : 0,
        trimEnd: hasEndArrow ? trim : 0,
      );
    }

    if (stroke.style == StrokeStyle.dashed) {
      _drawDashedPath(canvas, paint, drawPath);
    } else {
      canvas.drawPath(drawPath, paint);
    }

    // Draw arrow
    if (stroke.arrow != ArrowStyle.none && stroke.points.length >= 2) {
      _drawArrowHead(canvas, paint, stroke.points, stroke.arrow);
    }
  }

  /// Trim [path] by removing [trimStart] units off the front and
  /// [trimEnd] off the tail. Returns an empty path if the trim would
  /// consume the entire stroke.
  Path _trimEnds(Path path, {double trimStart = 0, double trimEnd = 0}) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      final start = trimStart.clamp(0.0, metric.length);
      final end = (metric.length - trimEnd).clamp(start, metric.length);
      if (end <= start) continue;
      out.addPath(metric.extractPath(start, end), Offset.zero);
    }
    return out;
  }

  /// Arrowhead size as a function of stroke width — scales linearly
  /// (roughly 3× width) so thick strokes get visibly larger arrows. The
  /// small +4 keeps thin strokes from disappearing into a tiny tip and
  /// the upper clamp keeps absurdly wide strokes (which we don't allow
  /// today anyway) from producing comic-book arrows.
  double _arrowSize(double strokeWidth) =>
      (strokeWidth * 3 + 4).clamp(12.0, 50.0);

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
    final arrowSize = _arrowSize(width);
    // Slightly narrower spread (28°) so thick strokes don't end in a
    // squat triangle; pairs with the longer body trim for a sharper
    // pointer silhouette.
    const spread = pi * 28 / 180;
    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * cos(angle - spread),
      tip.dy - arrowSize * sin(angle - spread),
    );
    // Notch the base in slightly along the line direction so the arrow
    // blends with the trimmed stroke body instead of presenting a flat
    // wide base. Notch depth ≈ stroke width / 2.
    final notch = width * 0.5;
    path.lineTo(
      tip.dx - (arrowSize - notch) * cos(angle),
      tip.dy - (arrowSize - notch) * sin(angle),
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
      oldDelegate.strokes != strokes ||
      oldDelegate.currentStroke != currentStroke ||
      oldDelegate.selectedStrokeId != selectedStrokeId ||
      oldDelegate.multiSelectStrokeIds != multiSelectStrokeIds;
}
