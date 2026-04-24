import 'dart:math';
import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class FieldHockeyCourtPainter extends CourtPainterBase {
  const FieldHockeyCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF1976D2),
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawTurf(canvas, size);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // FIH standard: 91.4m × 55m, portrait = 55m wide × 91.4m tall
    const fieldW = 55.0;
    const fieldH = 91.4;
    const ratio = fieldW / fieldH;

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

    final scX = cw / fieldW;
    final scY = ch / fieldH;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    final strokeThick = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // ── Outer boundary ──────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // ── Halfway line ────────────────────────────────────────────────────────
    canvas.drawLine(o(0, fieldH / 2), o(fieldW, fieldH / 2), p);

    // ── 23m lines ───────────────────────────────────────────────────────────
    const line23 = 22.9;
    canvas.drawLine(o(0, line23), o(fieldW, line23), p);
    canvas.drawLine(o(0, fieldH - line23), o(fieldW, fieldH - line23), p);

    // ── Shooting circles (D-arc, radius 14.63m from goal posts) ─────────────
    // Goal is 3.66m wide centered on goal line. The D is formed by arcs
    // centered on each post plus a short straight segment between.
    const goalW = 3.66;
    const arcR = 14.63;
    const goalLeft = (fieldW - goalW) / 2; // 25.67
    const goalRight = goalLeft + goalW;    // 29.33

    void drawD(double baselineY, {required bool bottom}) {
      // Arcs from each post: 90° quarter circle sweeping from baseline to
      // center, then straight segment between top of arcs.
      final postL = o(goalLeft, baselineY);
      final postR = o(goalRight, baselineY);
      final rX = arcR * scX;
      final rY = arcR * scY;
      final leftArcRect = Rect.fromCenter(
          center: postL, width: rX * 2, height: rY * 2);
      final rightArcRect = Rect.fromCenter(
          center: postR, width: rX * 2, height: rY * 2);
      if (bottom) {
        // Home side (bottom): arc opens upward (toward field center)
        canvas.drawArc(leftArcRect, pi, pi / 2, false, p);
        canvas.drawArc(rightArcRect, -pi / 2, pi / 2, false, p);
        canvas.drawLine(
          o(goalLeft, baselineY - arcR),
          o(goalRight, baselineY - arcR),
          p,
        );
      } else {
        // Away side (top): arc opens downward
        canvas.drawArc(leftArcRect, pi / 2, pi / 2, false, p);
        canvas.drawArc(rightArcRect, 0, pi / 2, false, p);
        canvas.drawLine(
          o(goalLeft, baselineY + arcR),
          o(goalRight, baselineY + arcR),
          p,
        );
      }
    }

    drawD(0, bottom: false);        // away/top D
    drawD(fieldH, bottom: true);    // home/bottom D

    // ── Dashed 5m arcs outside the D (short corner reference) ───────────────
    // Drawn as short hash marks at penalty-stroke spot
    canvas.drawCircle(o(fieldW / 2, 6.4), 0.3 * scX,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(o(fieldW / 2, fieldH - 6.4), 0.3 * scX,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    // ── Center spot ─────────────────────────────────────────────────────────
    canvas.drawCircle(o(fieldW / 2, fieldH / 2), 0.3 * scX,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    // ── Goals (3.66m wide × 1.2m deep) ──────────────────────────────────────
    const goalDepth = 1.2;
    canvas.drawRect(
      Rect.fromLTWH(
          o(goalLeft, -goalDepth).dx,
          o(goalLeft, -goalDepth).dy,
          goalW * scX,
          goalDepth * scY),
      strokeThick,
    );
    canvas.drawRect(
      Rect.fromLTWH(
          o(goalLeft, fieldH).dx,
          o(goalLeft, fieldH).dy,
          goalW * scX,
          goalDepth * scY),
      strokeThick,
    );
  }

  void _drawTurf(Canvas canvas, Size size) {
    // Blue astroturf — solid, no stripes (modern FIH international)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1976D2)..style = PaintingStyle.fill,
    );
  }
}
