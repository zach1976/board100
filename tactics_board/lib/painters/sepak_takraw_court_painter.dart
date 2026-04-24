import 'dart:math';
import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class SepakTakrawCourtPainter extends CourtPainterBase {
  const SepakTakrawCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF1565C0),
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawFloor(canvas, size);

    final w = size.width;
    final h = size.height;

    // ISTAF court: 13.4m × 6.1m. Portrait → 6.1 wide × 13.4 tall.
    const fieldW = 6.1;
    const fieldH = 13.4;
    const ratio = fieldW / fieldH;

    double cw, ch;
    if (w / h > ratio) {
      ch = h * 0.88;
      cw = ch * ratio;
    } else {
      cw = w * 0.88;
      ch = cw / ratio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    final scX = cw / fieldW;
    final scY = ch / fieldH;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Court boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), line);

    // Center / net line (solid white)
    canvas.drawLine(o(0, fieldH / 2), o(fieldW, fieldH / 2), line);

    // Net representation — short dashes along the center line
    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    drawDashedLine(canvas, netPaint,
        o(0, fieldH / 2), o(fieldW, fieldH / 2),
        dashLength: 6, gapLength: 4);

    // Service circles (0.3m radius) centered at 2.45m from each back line
    const svcR = 0.30;
    final svcHomeY = fieldH - 2.45; // 10.95
    final svcAwayY = 2.45;
    canvas.drawCircle(o(fieldW / 2, svcHomeY), svcR * scX, line);
    canvas.drawCircle(o(fieldW / 2, svcAwayY), svcR * scX, line);

    // Quarter circles (0.9m radius) at each end of the center line
    const qR = 0.90;
    // Home side (lower half) — arcs open downward into home court
    canvas.drawArc(
      Rect.fromCircle(center: o(0, fieldH / 2), radius: qR * scX),
      0, pi / 2, false, line,
    );
    canvas.drawArc(
      Rect.fromCircle(center: o(fieldW, fieldH / 2), radius: qR * scX),
      pi / 2, pi / 2, false, line,
    );
    // Away side (upper half) — arcs open upward into away court
    canvas.drawArc(
      Rect.fromCircle(center: o(0, fieldH / 2), radius: qR * scX),
      -pi / 2, pi / 2, false, line,
    );
    canvas.drawArc(
      Rect.fromCircle(center: o(fieldW, fieldH / 2), radius: qR * scX),
      pi, pi / 2, false, line,
    );
  }

  void _drawFloor(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1565C0)..style = PaintingStyle.fill,
    );
    // Subtle hardwood/sport-floor stripes
    final stripe = Paint()
      ..color = const Color(0xFF0D47A1).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final laneH = size.height / 14;
    for (int i = 0; i < 14; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(0, i * laneH, size.width, laneH),
          stripe,
        );
      }
    }
  }
}
