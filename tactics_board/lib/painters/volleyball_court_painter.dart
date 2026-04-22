import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class VolleyballCourtPainter extends CourtPainterBase {
  const VolleyballCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF2A5FA0),
        );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), courtPaint);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Full court 18m x 9m (portrait)
    const courtRatio = 18.0 / 9.0;
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

    final scX = cw / 9.0;
    final scY = ch / 18.0;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p..strokeWidth = 3);
    p.strokeWidth = 2;

    // Net (middle) - thick band + bright line
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 9), o(9, 9), netBand);
    final netLine = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 9), o(9, 9), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 8.5), o(0, 9.5), postPaint);
    canvas.drawLine(o(9, 8.5), o(9, 9.5), postPaint);

    // Attack lines (3m from net each side)
    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    drawDashedLine(canvas, dashPaint, o(0, 9 - 3), o(9, 9 - 3));
    drawDashedLine(canvas, dashPaint, o(0, 9 + 3), o(9, 9 + 3));

  }
}
