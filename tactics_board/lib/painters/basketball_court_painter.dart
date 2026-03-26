import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class BasketballCourtPainter extends CourtPainterBase {
  const BasketballCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFFB5651D),
        );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), courtPaint);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // NBA court 15m x 28m (portrait)
    const courtRatio = 15.0 / 28.0;
    double cw, ch;
    if (w / h > courtRatio) {
      ch = h * 0.88;
      cw = ch * courtRatio;
    } else {
      cw = w * 0.88;
      ch = cw / courtRatio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    // Uniform scale: sc = cw/15 = ch/28
    final sc = cw / 15.0;
    Offset o(double x, double y) => Offset(left + x * sc, top + y * sc);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // Center line (horizontal at y=14)
    canvas.drawLine(o(0, 14), o(15, 14), p);

    // Center circle r=1.8m
    canvas.drawCircle(o(7.5, 14), 1.8 * sc, p);

    // Top basket (opens downward), bottom basket (opens upward)
    _drawBasket(canvas, p, o, sc, 7.5, 1.575, isTop: true);
    _drawBasket(canvas, p, o, sc, 7.5, 28 - 1.575, isTop: false);
  }

  void _drawBasket(Canvas canvas, Paint p, Offset Function(double, double) o,
      double sc, double bx, double by,
      {required bool isTop}) {
    const keyW = 4.9; // key width (horizontal)
    const keyD = 5.8; // key depth (vertical)

    if (isTop) {
      // Key box
      canvas.drawRect(
        Rect.fromLTWH(
          o(bx - keyW / 2, by).dx,
          o(bx - keyW / 2, by).dy,
          keyW * sc,
          keyD * sc,
        ),
        p,
      );
      // Free throw circle
      canvas.drawCircle(o(bx, by + keyD), 1.8 * sc, p);
      // Corner 3 lines (vertical)
      canvas.drawLine(o(bx - 6.6, by), o(bx - 6.6, by + 6.32), p);
      canvas.drawLine(o(bx + 6.6, by), o(bx + 6.6, by + 6.32), p);
      // Three-point arc (opens downward, centered around π/2)
      final arcRect = Rect.fromCircle(center: o(bx, by), radius: 7.24 * sc);
      canvas.drawArc(arcRect, 0.40, 2.34, false, p);
      // Basket rim
      canvas.drawCircle(
        o(bx, by + 1.575),
        0.23 * sc,
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill,
      );
    } else {
      // Key box
      canvas.drawRect(
        Rect.fromLTWH(
          o(bx - keyW / 2, by - keyD).dx,
          o(bx - keyW / 2, by - keyD).dy,
          keyW * sc,
          keyD * sc,
        ),
        p,
      );
      // Free throw circle
      canvas.drawCircle(o(bx, by - keyD), 1.8 * sc, p);
      // Corner 3 lines (vertical)
      canvas.drawLine(o(bx - 6.6, by), o(bx - 6.6, by - 6.32), p);
      canvas.drawLine(o(bx + 6.6, by), o(bx + 6.6, by - 6.32), p);
      // Three-point arc (opens upward, centered around -π/2)
      final arcRect = Rect.fromCircle(center: o(bx, by), radius: 7.24 * sc);
      canvas.drawArc(arcRect, -2.74, 2.34, false, p);
      // Basket rim
      canvas.drawCircle(
        o(bx, by - 1.575),
        0.23 * sc,
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill,
      );
    }
  }
}
