import 'package:flutter/material.dart';

abstract class CourtPainterBase extends CustomPainter {
  final Color lineColor;
  final Color courtColor;

  const CourtPainterBase({
    this.lineColor = Colors.white,
    this.courtColor = const Color(0xFF1B5E20),
  });

  Paint get linePaint => Paint()
    ..color = lineColor
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  Paint get courtPaint => Paint()
    ..color = courtColor
    ..style = PaintingStyle.fill;

  void drawDashedLine(Canvas canvas, Paint paint, Offset p1, Offset p2,
      {double dashLength = 8, double gapLength = 5}) {
    final total = (p2 - p1).distance;
    final dir = (p2 - p1) / total;
    double drawn = 0;
    bool drawing = true;
    while (drawn < total) {
      final segLen = drawing
          ? dashLength.clamp(0, total - drawn)
          : gapLength.clamp(0, total - drawn);
      if (drawing) {
        canvas.drawLine(
          p1 + dir * drawn,
          p1 + dir * (drawn + segLen),
          paint,
        );
      }
      drawn += segLen;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
