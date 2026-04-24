import 'dart:math';
import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class BeachTennisCourtPainter extends CourtPainterBase {
  const BeachTennisCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFFEAC478),
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawSand(canvas, size);

    final w = size.width;
    final h = size.height;

    // ITF beach tennis court: 16m × 8m. Portrait → 8 wide × 16 tall.
    const fieldW = 8.0;
    const fieldH = 16.0;
    const ratio = fieldW / fieldH;

    double cw, ch;
    if (w / h > ratio) {
      ch = h * 0.85;
      cw = ch * ratio;
    } else {
      cw = w * 0.85;
      ch = cw / ratio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    final scX = cw / fieldW;
    Offset o(double x, double y) => Offset(left + x * (cw / fieldW), top + y * (ch / fieldH));

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // Court boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), line);

    // Net line — dashed across center
    final netPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    drawDashedLine(canvas, netPaint,
        o(0, fieldH / 2), o(fieldW, fieldH / 2),
        dashLength: 8, gapLength: 5);

    // Net posts (small tabs extending just outside the court at the net line)
    final postPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(-0.25, fieldH / 2), o(0, fieldH / 2), postPaint);
    canvas.drawLine(o(fieldW, fieldH / 2), o(fieldW + 0.25, fieldH / 2), postPaint);

    // Subtle serve-target dots along baselines (visual aid only)
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(o(fieldW / 2, 0), 0.10 * scX, dot);
    canvas.drawCircle(o(fieldW / 2, fieldH), 0.10 * scX, dot);
  }

  void _drawSand(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFEAC478)..style = PaintingStyle.fill,
    );
    // Sand speckles — scattered tiny dots for sand texture
    final speckle = Paint()
      ..color = const Color(0xFFB88848).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final rnd = Random(42);
    final count = (size.width * size.height / 1200).round();
    for (int i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.8, speckle);
    }
  }
}
