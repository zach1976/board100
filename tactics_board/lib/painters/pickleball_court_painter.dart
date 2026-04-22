import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class PickleballCourtPainter extends CourtPainterBase {
  const PickleballCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF2A6DA8),
        );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), courtPaint);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Court: 13.41m x 6.1m (portrait)
    const courtRatio = 13.41 / 6.1;
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

    final scX = cw / 6.1;
    final scY = ch / 13.41;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p..strokeWidth = 3);
    p.strokeWidth = 2;

    // Net (middle) - thick band + bright line
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 13.41 / 2), o(6.1, 13.41 / 2), netBand);
    final netLine = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 13.41 / 2), o(6.1, 13.41 / 2), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 13.41 / 2 - 0.4), o(0, 13.41 / 2 + 0.4), postPaint);
    canvas.drawLine(o(6.1, 13.41 / 2 - 0.4), o(6.1, 13.41 / 2 + 0.4), postPaint);

    // Non-volley zone (kitchen) - 2.13m from net each side
    // Top half
    canvas.drawRect(
      Rect.fromLTWH(
        o(0, 13.41 / 2 - 2.13).dx,
        o(0, 13.41 / 2 - 2.13).dy,
        cw,
        2.13 * scY,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(o(0, 13.41 / 2 - 2.13), o(6.1, 13.41 / 2 - 2.13), p);

    // Bottom half kitchen
    canvas.drawRect(
      Rect.fromLTWH(
        o(0, 13.41 / 2).dx,
        o(0, 13.41 / 2).dy,
        cw,
        2.13 * scY,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(o(0, 13.41 / 2 + 2.13), o(6.1, 13.41 / 2 + 2.13), p);

    // Center line (service boxes)
    canvas.drawLine(o(3.05, 0), o(3.05, 13.41 / 2 - 2.13), p);
    canvas.drawLine(o(3.05, 13.41 / 2 + 2.13), o(3.05, 13.41), p);
  }
}
