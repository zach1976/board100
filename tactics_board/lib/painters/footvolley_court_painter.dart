import 'dart:math';
import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class FootvolleyCourtPainter extends CourtPainterBase {
  const FootvolleyCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFFE5B880),
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawSand(canvas, size);

    final w = size.width;
    final h = size.height;

    // Beach court: 18m × 9m (same as beach volleyball). Portrait → 9 × 18.
    const fieldW = 9.0;
    const fieldH = 18.0;
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
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    // Court boundary (thick "ribbon" lines are typical on beach courts)
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), line);

    // Net — thicker, darker dashed line (footvolley net is tall & visible)
    final netPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke;
    drawDashedLine(canvas, netPaint,
        o(0, fieldH / 2), o(fieldW, fieldH / 2),
        dashLength: 10, gapLength: 5);

    // Net band shading (slight rectangle above center line to suggest net mesh)
    final band = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(o(0, fieldH / 2 - 0.20).dx, o(0, fieldH / 2 - 0.20).dy,
          cw, 0.40 * (ch / fieldH)),
      band,
    );

    // Net posts — short tabs extending just outside the court
    canvas.drawLine(o(-0.30, fieldH / 2), o(0, fieldH / 2), netPaint);
    canvas.drawLine(o(fieldW, fieldH / 2), o(fieldW + 0.30, fieldH / 2), netPaint);

    // Center service mark on each baseline
    final dot = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(o(fieldW / 2, 0), 0.12 * scX, dot);
    canvas.drawCircle(o(fieldW / 2, fieldH), 0.12 * scX, dot);
  }

  void _drawSand(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE5B880)..style = PaintingStyle.fill,
    );
    // Sand speckles for texture
    final speckle = Paint()
      ..color = const Color(0xFFA87240).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final rnd = Random(17);
    final count = (size.width * size.height / 1100).round();
    for (int i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.9, speckle);
    }
  }
}
