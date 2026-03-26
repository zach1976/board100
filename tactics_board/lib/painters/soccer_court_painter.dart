import 'dart:math';
import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class SoccerCourtPainter extends CourtPainterBase {
  const SoccerCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF2D8A2D),
        );

  @override
  void paint(Canvas canvas, Size size) {
    // Grass stripes
    _drawGrass(canvas, size);

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // FIFA standard: 105m long × 68m wide, portrait = 68m wide × 105m tall
    const fieldW = 68.0;
    const fieldH = 105.0;
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

    final fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokeThick = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // ── Outer boundary ──────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // ── Halfway line + center circle ─────────────────────────────────────────
    canvas.drawLine(o(0, 52.5), o(68, 52.5), p);
    canvas.drawCircle(o(34, 52.5), 9.15 * scX, p);
    canvas.drawCircle(o(34, 52.5), 0.35 * scX, fillWhite);

    // ── Top penalty area (16.5m deep, 40.32m wide) ──────────────────────────
    const paLeft = (fieldW - 40.32) / 2; // 13.84
    canvas.drawRect(
      Rect.fromLTWH(o(paLeft, 0).dx, o(paLeft, 0).dy, 40.32 * scX, 16.5 * scY),
      p,
    );
    // Top goal area (5.5m deep, 18.32m wide)
    const gaLeft = (fieldW - 18.32) / 2; // 24.84
    canvas.drawRect(
      Rect.fromLTWH(o(gaLeft, 0).dx, o(gaLeft, 0).dy, 18.32 * scX, 5.5 * scY),
      p,
    );
    // Top penalty spot
    canvas.drawCircle(o(34, 11), 0.35 * scX, fillWhite);
    // Top penalty arc (part of 9.15m circle outside penalty area)
    final topArcAngle = asin(5.5 / 9.15); // ≈ 0.644 rad
    final topArcSweep = pi - 2 * topArcAngle;
    canvas.drawArc(
      Rect.fromCircle(center: o(34, 11), radius: 9.15 * scX),
      topArcAngle,
      topArcSweep,
      false,
      p,
    );

    // ── Bottom penalty area ──────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(
          o(paLeft, fieldH - 16.5).dx,
          o(paLeft, fieldH - 16.5).dy,
          40.32 * scX,
          16.5 * scY),
      p,
    );
    // Bottom goal area
    canvas.drawRect(
      Rect.fromLTWH(
          o(gaLeft, fieldH - 5.5).dx,
          o(gaLeft, fieldH - 5.5).dy,
          18.32 * scX,
          5.5 * scY),
      p,
    );
    // Bottom penalty spot
    canvas.drawCircle(o(34, fieldH - 11), 0.35 * scX, fillWhite);
    // Bottom penalty arc
    canvas.drawArc(
      Rect.fromCircle(center: o(34, fieldH - 11), radius: 9.15 * scX),
      pi + topArcAngle,
      topArcSweep,
      false,
      p,
    );

    // ── Corner arcs (r = 1m) ─────────────────────────────────────────────────
    final cr = 1.0 * scX;
    canvas.drawArc(Rect.fromCircle(center: o(0, 0), radius: cr),
        0, pi / 2, false, p);
    canvas.drawArc(Rect.fromCircle(center: o(fieldW, 0), radius: cr),
        pi / 2, pi / 2, false, p);
    canvas.drawArc(Rect.fromCircle(center: o(0, fieldH), radius: cr),
        -pi / 2, pi / 2, false, p);
    canvas.drawArc(Rect.fromCircle(center: o(fieldW, fieldH), radius: cr),
        pi, pi / 2, false, p);

    // ── Goals (7.32m wide × 2.44m deep) ─────────────────────────────────────
    const goalLeft = (fieldW - 7.32) / 2; // 30.34
    const goalDepth = 2.44;
    canvas.drawRect(
      Rect.fromLTWH(
          o(goalLeft, -goalDepth).dx,
          o(goalLeft, -goalDepth).dy,
          7.32 * scX,
          goalDepth * scY),
      strokeThick,
    );
    canvas.drawRect(
      Rect.fromLTWH(
          o(goalLeft, fieldH).dx,
          o(goalLeft, fieldH).dy,
          7.32 * scX,
          goalDepth * scY),
      strokeThick,
    );
  }

  void _drawGrass(Canvas canvas, Size size) {
    const stripeCount = 12;
    final stripeH = size.height / stripeCount;
    const colors = [Color(0xFF2D8A2D), Color(0xFF267526)];
    for (int i = 0; i < stripeCount; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, size.width, stripeH),
        Paint()
          ..color = colors[i % 2]
          ..style = PaintingStyle.fill,
      );
    }
  }
}
