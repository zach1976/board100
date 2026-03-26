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

    // NBA court 28m x 15m (landscape)
    const courtRatio = 28.0 / 15.0;
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

    final scX = cw / 28.0;
    final scY = ch / 15.0;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // Center line
    canvas.drawLine(o(14, 0), o(14, 15), p);

    // Center circle r=1.8m
    canvas.drawCircle(o(14, 7.5), 1.8 * scX, p);

    // Three-point arcs (simplified, NBA: 7.24m from basket)
    // Left basket at x=1.575, right basket at x=26.425, both at y=7.5
    _drawBasket(canvas, p, o, scX, scY, 1.575, 7.5, isLeft: true);
    _drawBasket(canvas, p, o, scX, scY, 28 - 1.575, 7.5, isLeft: false);
  }

  void _drawBasket(Canvas canvas, Paint p, Offset Function(double, double) o,
      double scX, double scY, double bx, double by,
      {required bool isLeft}) {
    // Key (paint) box: 4.9m wide x 5.8m deep
    final keyW = 4.9;
    final keyD = 5.8;
    if (isLeft) {
      canvas.drawRect(
        Rect.fromLTWH(
          o(bx, by - keyW / 2).dx,
          o(bx, by - keyW / 2).dy,
          keyD * scX,
          keyW * scY,
        ),
        p,
      );
      // Free-throw circle
      canvas.drawCircle(o(bx + keyD, by), 1.8 * scX, p);
      // Three-point arc
      // Straight parts (corner 3)
      canvas.drawLine(o(bx, by - 6.6), o(bx + 6.32, by - 6.6), p);
      canvas.drawLine(o(bx, by + 6.6), o(bx + 6.32, by + 6.6), p);
      // Arc
      final arcRect = Rect.fromCircle(
        center: o(bx, by),
        radius: 7.24 * scX,
      );
      canvas.drawArc(arcRect, -1.17, 2.34, false, p);
      // Basket
      canvas.drawCircle(o(bx + 1.575, by), 0.23 * scX,
          Paint()..color = Colors.orange..style = PaintingStyle.fill);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(
          o(bx - keyD, by - keyW / 2).dx,
          o(bx - keyD, by - keyW / 2).dy,
          keyD * scX,
          keyW * scY,
        ),
        p,
      );
      canvas.drawCircle(o(bx - keyD, by), 1.8 * scX, p);
      canvas.drawLine(o(bx, by - 6.6), o(bx - 6.32, by - 6.6), p);
      canvas.drawLine(o(bx, by + 6.6), o(bx - 6.32, by + 6.6), p);
      final arcRect = Rect.fromCircle(
        center: o(bx, by),
        radius: 7.24 * scX,
      );
      canvas.drawArc(arcRect, -1.97, 2.34, false, p);
      canvas.drawCircle(o(bx - 1.575, by), 0.23 * scX,
          Paint()..color = Colors.orange..style = PaintingStyle.fill);
    }
  }
}
