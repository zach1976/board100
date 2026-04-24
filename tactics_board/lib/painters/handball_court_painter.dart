import 'dart:math';
import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class HandballCourtPainter extends CourtPainterBase {
  const HandballCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF1565C0),
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawFloor(canvas, size);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // IHF: 40m × 20m. Portrait = 20 wide × 40 tall.
    const fieldW = 20.0;
    const fieldH = 40.0;
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

    // ── Outer boundary ─────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // ── Halfway line ───────────────────────────────────────────────────────
    canvas.drawLine(o(0, fieldH / 2), o(fieldW, fieldH / 2), p);

    // Goal area + 9m line are derived from the 3m goal posts.
    const goalW = 3.0;
    const goal6 = 6.0;
    const goal9 = 9.0;
    const goalLeft = (fieldW - goalW) / 2;   // 8.5
    const goalRight = goalLeft + goalW;       // 11.5

    final dashed = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    void drawZone(double goalY, {required bool bottom}) {
      // 6m line — solid
      _drawCrescent(canvas, o, goalLeft, goalRight, goalY, goal6,
          bottom: bottom, paint: p);
      // 9m line — dashed
      _drawCrescent(canvas, o, goalLeft, goalRight, goalY, goal9,
          bottom: bottom, paint: dashed, dashed: true);
      // Penalty mark at 7m
      final dy = bottom ? -7.0 : 7.0;
      canvas.drawLine(
        o(fieldW / 2 - 0.5, goalY + dy),
        o(fieldW / 2 + 0.5, goalY + dy),
        p,
      );
      // 4m line (goalkeeper restraining line)
      final dy4 = bottom ? -4.0 : 4.0;
      canvas.drawLine(
        o(fieldW / 2 - 0.075, goalY + dy4),
        o(fieldW / 2 + 0.075, goalY + dy4),
        p,
      );
    }

    drawZone(0, bottom: false);          // top goal
    drawZone(fieldH, bottom: true);      // bottom goal

    // ── Goals (3m wide × ~1m deep, drawn as small rectangle outside line) ─
    const goalDepth = 1.0;
    final goalPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(o(goalLeft, -goalDepth).dx, o(goalLeft, -goalDepth).dy,
          goalW * scX, goalDepth * scY),
      goalPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(o(goalLeft, fieldH).dx, o(goalLeft, fieldH).dy,
          goalW * scX, goalDepth * scY),
      goalPaint,
    );

    // ── Center spot ────────────────────────────────────────────────────────
    canvas.drawCircle(o(fieldW / 2, fieldH / 2), 0.25 * scX,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  /// Draws a goal-area-style crescent: arc from each post (radius `r`),
  /// joined by a straight segment between the arc tops.
  void _drawCrescent(
    Canvas canvas,
    Offset Function(double, double) o,
    double goalLeft,
    double goalRight,
    double goalY,
    double r, {
    required bool bottom,
    required Paint paint,
    bool dashed = false,
  }) {
    final postL = o(goalLeft, goalY);
    final postR = o(goalRight, goalY);
    final scX = (o(1, 0).dx - o(0, 0).dx);
    final scY = (o(0, 1).dy - o(0, 0).dy);
    final rX = r * scX;
    final rY = r * scY;
    final leftRect = Rect.fromCenter(center: postL, width: rX * 2, height: rY * 2);
    final rightRect = Rect.fromCenter(center: postR, width: rX * 2, height: rY * 2);

    if (bottom) {
      // arcs open upward (toward field center)
      _drawArcMaybeDashed(canvas, leftRect, pi, pi / 2, paint, dashed);
      _drawArcMaybeDashed(canvas, rightRect, -pi / 2, pi / 2, paint, dashed);
      _drawLineMaybeDashed(canvas,
          o(goalLeft, goalY - r), o(goalRight, goalY - r), paint, dashed);
    } else {
      _drawArcMaybeDashed(canvas, leftRect, pi / 2, pi / 2, paint, dashed);
      _drawArcMaybeDashed(canvas, rightRect, 0, pi / 2, paint, dashed);
      _drawLineMaybeDashed(canvas,
          o(goalLeft, goalY + r), o(goalRight, goalY + r), paint, dashed);
    }
  }

  void _drawArcMaybeDashed(
      Canvas canvas, Rect rect, double start, double sweep, Paint p, bool dashed) {
    if (!dashed) {
      canvas.drawArc(rect, start, sweep, false, p);
      return;
    }
    const segs = 18;
    for (int i = 0; i < segs; i += 2) {
      canvas.drawArc(rect, start + sweep * i / segs, sweep / segs, false, p);
    }
  }

  void _drawLineMaybeDashed(
      Canvas canvas, Offset a, Offset b, Paint p, bool dashed) {
    if (!dashed) {
      canvas.drawLine(a, b, p);
      return;
    }
    const dash = 4.0;
    const gap = 4.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    double t = 0;
    while (t < total) {
      final t2 = (t + dash).clamp(0, total);
      canvas.drawLine(a + dir * t, a + dir * t2.toDouble(), p);
      t += dash + gap;
    }
  }

  void _drawFloor(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1565C0)..style = PaintingStyle.fill,
    );
  }
}
