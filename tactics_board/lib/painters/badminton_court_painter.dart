import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class BadmintonCourtPainter extends CourtPainterBase {
  const BadmintonCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF2E7D3F),
        );

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), courtPaint);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Court dimensions (real: 13.4m x 6.1m  → portrait orientation)
    // We render portrait: width=6.1, height=13.4 mapped to canvas
    const courtRatio = 13.4 / 6.1;
    double cw, ch;
    if (h / w > courtRatio) {
      cw = w * 0.88;
      ch = cw * courtRatio;
    } else {
      ch = h * 0.88;
      cw = ch / courtRatio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    // Scale factors
    final scX = cw / 6.1;
    final scY = ch / 13.4;

    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // Net (middle) - thick band + bright line
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 6.7), o(6.1, 6.7), netBand);
    final netLine = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 6.7), o(6.1, 6.7), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 6.7 - 0.3), o(0, 6.7 + 0.3), postPaint);
    canvas.drawLine(o(6.1, 6.7 - 0.3), o(6.1, 6.7 + 0.3), postPaint);

    // Short service lines (1.98m from net)
    canvas.drawLine(o(0, 6.7 - 1.98), o(6.1, 6.7 - 1.98), p);
    canvas.drawLine(o(0, 6.7 + 1.98), o(6.1, 6.7 + 1.98), p);

    // Center line (full length)
    canvas.drawLine(o(3.05, 0), o(3.05, 13.4), p);

    // Long service line for doubles (0.76m from back)
    canvas.drawLine(o(0, 0.76), o(6.1, 0.76), p);
    canvas.drawLine(o(0, 13.4 - 0.76), o(6.1, 13.4 - 0.76), p);

    // Singles sidelines (0.46m from each side)
    canvas.drawLine(o(0.46, 0), o(0.46, 13.4), p);
    canvas.drawLine(o(6.1 - 0.46, 0), o(6.1 - 0.46, 13.4), p);

  }
}
