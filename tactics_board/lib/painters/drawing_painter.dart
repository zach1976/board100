import 'dart:math';
import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;

  const DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
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
      final p1 = points[points.length - 2];
      final p2 = points.last;
      _arrowAt(canvas, arrowPaint, p1, p2, paint.strokeWidth);
    }
    if (arrow == ArrowStyle.both && points.length >= 2) {
      final p1 = points[1];
      final p2 = points.first;
      _arrowAt(canvas, arrowPaint, p1, p2, paint.strokeWidth);
    }
  }

  void _arrowAt(Canvas canvas, Paint paint, Offset from, Offset to, double width) {
    final angle = atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowSize = width * 4 + 6;
    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(
      to.dx - arrowSize * cos(angle - pi / 6),
      to.dy - arrowSize * sin(angle - pi / 6),
    );
    path.lineTo(
      to.dx - arrowSize * cos(angle + pi / 6),
      to.dy - arrowSize * sin(angle + pi / 6),
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.currentStroke != currentStroke;
}
