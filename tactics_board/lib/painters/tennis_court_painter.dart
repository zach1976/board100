import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class TennisCourtPainter extends CourtPainterBase {
  const TennisCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF1565C0),
        );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), courtPaint);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Full court 23.77m x 10.97m (portrait)
    const courtRatio = 23.77 / 10.97;
    double cw, ch;
    if (h / w > courtRatio) {
      cw = w * 0.85;
      ch = cw * courtRatio;
    } else {
      ch = h * 0.85;
      cw = ch / courtRatio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    final scX = cw / 10.97;
    final scY = ch / 23.77;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary (doubles)
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // Singles sidelines (1.372m from each side)
    canvas.drawLine(o(1.372, 0), o(1.372, 23.77), p);
    canvas.drawLine(o(10.97 - 1.372, 0), o(10.97 - 1.372, 23.77), p);

    // Net (middle) - thick band + bright line
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 23.77 / 2), o(10.97, 23.77 / 2), netBand);
    final netLine = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 23.77 / 2), o(10.97, 23.77 / 2), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 23.77 / 2 - 0.5), o(0, 23.77 / 2 + 0.5), postPaint);
    canvas.drawLine(o(10.97, 23.77 / 2 - 0.5), o(10.97, 23.77 / 2 + 0.5), postPaint);

    // Service lines (6.4m from net)
    canvas.drawLine(o(1.372, 23.77 / 2 - 6.4), o(10.97 - 1.372, 23.77 / 2 - 6.4), p);
    canvas.drawLine(o(1.372, 23.77 / 2 + 6.4), o(10.97 - 1.372, 23.77 / 2 + 6.4), p);

    // Center service line
    canvas.drawLine(o(10.97 / 2, 23.77 / 2 - 6.4), o(10.97 / 2, 23.77 / 2 + 6.4), p);

    // Center marks at baseline
    canvas.drawLine(o(10.97 / 2, 0), o(10.97 / 2, 0.2), p);
    canvas.drawLine(o(10.97 / 2, 23.77 - 0.2), o(10.97 / 2, 23.77), p);
  }
}
