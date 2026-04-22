import 'dart:math';
import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class BasketballCourtPainter extends CourtPainterBase {
  const BasketballCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFFD9A867),
        );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), courtPaint);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // FIBA court: 15m wide × 28m long (portrait)
    const courtW = 15.0;
    const courtH = 28.0;
    const ratio = courtW / courtH;

    double cw, ch;
    if (w / h > ratio) {
      ch = h * 0.90;
      cw = ch * ratio;
    } else {
      cw = w * 0.90;
      ch = cw / ratio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;
    final sc = cw / courtW;

    Offset o(double x, double y) => Offset(left + x * sc, top + y * sc);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // Center line
    canvas.drawLine(o(0, 14), o(15, 14), p);

    // Center circle (r = 1.8m)
    canvas.drawCircle(o(7.5, 14), 1.8 * sc, p);

    // Both halves
    _drawHalf(canvas, p, o, sc, isTop: true);
    _drawHalf(canvas, p, o, sc, isTop: false);
  }

  void _drawHalf(Canvas canvas, Paint p, Offset Function(double, double) o,
      double sc, {required bool isTop}) {
    const cx = 7.5;
    const courtW = 15.0;
    const keyBaseW = 6.0; // key width at baseline (trapezoid)
    const keyFtW = 3.6; // key width at free throw line (trapezoid)
    const keyD = 5.8; // key depth
    const basketDist = 1.575;
    const bbDist = 1.2;
    const threeR = 6.75;
    const cornerX = 0.9;

    final dxCorner = cx - cornerX;
    final arcYOffset = sqrt(threeR * threeR - dxCorner * dxCorner);
    final cornerLineLen = basketDist + arcYOffset;

    if (isTop) {
      // --- TOP HALF ---

      // Trapezoidal key (wide at baseline, narrow at free throw line)
      final keyPath = Path()
        ..moveTo(o(cx - keyBaseW / 2, 0).dx, o(0, 0).dy)
        ..lineTo(o(cx - keyFtW / 2, keyD).dx, o(0, keyD).dy)
        ..lineTo(o(cx + keyFtW / 2, keyD).dx, o(0, keyD).dy)
        ..lineTo(o(cx + keyBaseW / 2, 0).dx, o(0, 0).dy);
      canvas.drawPath(keyPath, p);
      // Free throw line (top of key)
      canvas.drawLine(o(cx - keyFtW / 2, keyD), o(cx + keyFtW / 2, keyD), p);

      // Free throw semicircle (opens downward toward mid-court)
      final ftCenter = o(cx, keyD);
      canvas.drawArc(Rect.fromCircle(center: ftCenter, radius: 1.8 * sc), 0, pi, false, p);

      // Backboard
      canvas.drawLine(o(cx - 0.9, bbDist), o(cx + 0.9, bbDist), p);

      // Basket rim
      final rimC = o(cx, basketDist);
      canvas.drawCircle(rimC, 0.225 * sc, Paint()..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = p.strokeWidth);

      // Three-point corner lines (from baseline going down)
      canvas.drawLine(o(cornerX, 0), o(cornerX, cornerLineLen), p);
      canvas.drawLine(o(courtW - cornerX, 0), o(courtW - cornerX, cornerLineLen), p);

      // Three-point arc
      final arcCenter = o(cx, basketDist);
      final arcR = threeR * sc;
      // Angle from center to right corner endpoint
      final rightAngle = atan2(arcYOffset * sc, dxCorner * sc); // positive y = downward
      // Arc from rightAngle sweeping to (π - rightAngle)
      canvas.drawArc(
        Rect.fromCircle(center: arcCenter, radius: arcR),
        rightAngle,
        pi - 2 * rightAngle,
        false,
        p,
      );

      // Restricted area (no-charge semicircle r=1.25m)
      canvas.drawArc(Rect.fromCircle(center: rimC, radius: 1.25 * sc), 0, pi, false, p);

    } else {
      // --- BOTTOM HALF ---

      // Trapezoidal key
      final keyPath = Path()
        ..moveTo(o(cx - keyBaseW / 2, 28).dx, o(0, 28).dy)
        ..lineTo(o(cx - keyFtW / 2, 28 - keyD).dx, o(0, 28 - keyD).dy)
        ..lineTo(o(cx + keyFtW / 2, 28 - keyD).dx, o(0, 28 - keyD).dy)
        ..lineTo(o(cx + keyBaseW / 2, 28).dx, o(0, 28).dy);
      canvas.drawPath(keyPath, p);
      canvas.drawLine(o(cx - keyFtW / 2, 28 - keyD), o(cx + keyFtW / 2, 28 - keyD), p);

      // Free throw semicircle (opens upward toward mid-court)
      final ftCenter = o(cx, 28 - keyD);
      canvas.drawArc(Rect.fromCircle(center: ftCenter, radius: 1.8 * sc), pi, pi, false, p);

      // Backboard
      canvas.drawLine(o(cx - 0.9, 28 - bbDist), o(cx + 0.9, 28 - bbDist), p);

      // Basket rim
      final rimC = o(cx, 28 - basketDist);
      canvas.drawCircle(rimC, 0.225 * sc, Paint()..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = p.strokeWidth);

      // Three-point corner lines (from baseline going up)
      canvas.drawLine(o(cornerX, 28), o(cornerX, 28 - cornerLineLen), p);
      canvas.drawLine(o(courtW - cornerX, 28), o(courtW - cornerX, 28 - cornerLineLen), p);

      // Three-point arc
      final arcCenter = o(cx, 28 - basketDist);
      final arcR = threeR * sc;
      final rightAngle = atan2(arcYOffset * sc, dxCorner * sc);
      // Arc opens upward (negative y direction)
      canvas.drawArc(
        Rect.fromCircle(center: arcCenter, radius: arcR),
        -(pi - rightAngle),
        pi - 2 * rightAngle,
        false,
        p,
      );

      // Restricted area
      canvas.drawArc(Rect.fromCircle(center: rimC, radius: 1.25 * sc), pi, pi, false, p);
    }
  }
}
