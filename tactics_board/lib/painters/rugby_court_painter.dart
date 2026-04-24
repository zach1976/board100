import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class RugbyCourtPainter extends CourtPainterBase {
  const RugbyCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF2E7D32),
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrass(canvas, size);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Total field including in-goals: 70m wide × 144m tall
    // (100m playing area + 22m in-goal each end)
    const fieldW = 70.0;
    const fieldH = 144.0;
    const inGoal = 22.0;
    const ratio = fieldW / fieldH;

    double cw, ch;
    if (w / h > ratio) {
      ch = h * 0.92;
      cw = ch * ratio;
    } else {
      cw = w * 0.92;
      ch = cw / ratio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    final scX = cw / fieldW;
    final scY = ch / fieldH;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // ── Outer touch & dead-ball lines (full boundary) ───────────────────────
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // ── Try lines (solid) ───────────────────────────────────────────────────
    canvas.drawLine(o(0, inGoal), o(fieldW, inGoal), p);
    canvas.drawLine(o(0, fieldH - inGoal), o(fieldW, fieldH - inGoal), p);

    // ── Halfway line ────────────────────────────────────────────────────────
    canvas.drawLine(o(0, fieldH / 2), o(fieldW, fieldH / 2), p);

    // ── 22m lines (solid) ───────────────────────────────────────────────────
    canvas.drawLine(o(0, inGoal + 22), o(fieldW, inGoal + 22), p);
    canvas.drawLine(o(0, fieldH - inGoal - 22), o(fieldW, fieldH - inGoal - 22), p);

    // ── 10m lines (dashed, 10m from halfway) ────────────────────────────────
    _drawDashedHorizontal(canvas, o(0, fieldH / 2 - 10).dy, left, left + cw, p);
    _drawDashedHorizontal(canvas, o(0, fieldH / 2 + 10).dy, left, left + cw, p);

    // ── 5m & 15m lines (dashed, parallel to touchlines for lineouts) ────────
    final tryY1 = o(0, inGoal).dy;
    final tryY2 = o(0, fieldH - inGoal).dy;
    for (final dx in [5.0, 15.0, fieldW - 15.0, fieldW - 5.0]) {
      _drawDashedVertical(canvas, o(dx, 0).dx, tryY1, tryY2, p);
    }

    // ── Goal posts (H-shaped) on each try line ──────────────────────────────
    const postWidth = 5.6;          // distance between posts
    const crossbarHeight = 3.0;     // crossbar height (3m above ground)
    const postExtension = 8.0;      // visual height of posts above crossbar
    final postLeft = (fieldW - postWidth) / 2;
    final postRight = postLeft + postWidth;

    final postPaint = Paint()
      ..color = Colors.yellow.shade300
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    void drawPosts(double tryYm, {required bool home}) {
      // Crossbar offset toward in-goal (visual representation)
      final dir = home ? 1 : -1;
      final crossY = tryYm + dir * crossbarHeight;
      final tipY = tryYm + dir * (crossbarHeight + postExtension);
      // Two uprights from try line outward
      canvas.drawLine(o(postLeft, tryYm), o(postLeft, tipY), postPaint);
      canvas.drawLine(o(postRight, tryYm), o(postRight, tipY), postPaint);
      // Crossbar
      canvas.drawLine(o(postLeft, crossY), o(postRight, crossY), postPaint);
    }
    drawPosts(inGoal, home: false);             // away posts (top)
    drawPosts(fieldH - inGoal, home: true);     // home posts (bottom)
  }

  void _drawGrass(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.fill,
    );
    // Mowing stripes — alternate horizontal bands
    final stripe = Paint()
      ..color = const Color(0xFF338838).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final bandH = size.height / 12;
    for (int i = 0; i < 12; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(0, i * bandH, size.width, bandH),
          stripe,
        );
      }
    }
  }

  void _drawDashedHorizontal(
      Canvas canvas, double y, double x1, double x2, Paint p) {
    const dash = 4.0;
    const gap = 6.0;
    double x = x1;
    while (x < x2) {
      final end = (x + dash).clamp(x1, x2);
      canvas.drawLine(Offset(x, y), Offset(end, y), p);
      x += dash + gap;
    }
  }

  void _drawDashedVertical(
      Canvas canvas, double x, double y1, double y2, Paint p) {
    const dash = 4.0;
    const gap = 6.0;
    double y = y1;
    while (y < y2) {
      final end = (y + dash).clamp(y1, y2);
      canvas.drawLine(Offset(x, y), Offset(x, end), p);
      y += dash + gap;
    }
  }
}
