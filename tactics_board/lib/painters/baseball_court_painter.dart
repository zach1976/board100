import 'dart:math';
import 'package:flutter/material.dart';
import 'court_painter_base.dart';

class BaseballCourtPainter extends CourtPainterBase {
  const BaseballCourtPainter()
      : super(
          lineColor: Colors.white,
          courtColor: const Color(0xFF2E7D32),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Square field, scaled.
    final side = (w < h ? w : h) * 0.95;
    final left = (w - side) / 2;
    final top = (h - side) / 2;
    final field = Rect.fromLTWH(left, top, side, side);

    // Home plate at bottom-center, baselines extend at 45° to first/third.
    // Use field-local coords [0..1] × side.
    Offset f(double x, double y) => Offset(left + x * side, top + y * side);

    // ── Outfield grass background ─────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1E5A1E)..style = PaintingStyle.fill,
    );

    // Mowing pattern — concentric arcs centered at home plate
    final home = f(0.50, 0.92);
    final stripe = Paint()
      ..color = const Color(0xFF338838).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final r = side * (0.20 + i * 0.13);
      final rect = Rect.fromCircle(center: home, radius: r);
      if (i.isEven) {
        canvas.drawArc(rect, pi, pi, true, stripe);
      }
    }

    // Foul territory shading — outside the foul lines (light brown)
    final foulPaint = Paint()
      ..color = const Color(0xFF8B6F47).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Foul lines from home: NW (3B-LF) and NE (1B-RF)
    final foulNW = f(0.04, 0.32); // far end of left foul line
    final foulNE = f(0.96, 0.32); // far end of right foul line

    // Left foul wedge (between left edge and 3B-LF foul line)
    final leftWedge = Path()
      ..moveTo(home.dx, home.dy)
      ..lineTo(left, home.dy)
      ..lineTo(left, top)
      ..lineTo(foulNW.dx, foulNW.dy)
      ..close();
    canvas.drawPath(leftWedge, foulPaint);

    // Right foul wedge
    final rightWedge = Path()
      ..moveTo(home.dx, home.dy)
      ..lineTo(left + side, home.dy)
      ..lineTo(left + side, top)
      ..lineTo(foulNE.dx, foulNE.dy)
      ..close();
    canvas.drawPath(rightWedge, foulPaint);

    // ── Outfield warning track / fence arc ────────────────────────────────
    final fenceR = side * 0.78;
    final fenceRect = Rect.fromCircle(center: home, radius: fenceR);
    canvas.drawArc(
      fenceRect,
      pi + pi / 4,         // 225°
      pi / 2,              // 90° sweep (covers outfield)
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // ── Infield dirt (skinned area between baselines + arc) ───────────────
    final dirt = Paint()
      ..color = const Color(0xFFB07A4C)
      ..style = PaintingStyle.fill;

    final infieldR = side * 0.34;
    final infieldRect = Rect.fromCircle(center: home, radius: infieldR);
    final dirtPath = Path()
      ..moveTo(home.dx, home.dy)
      ..arcTo(infieldRect, pi + pi / 4, pi / 2, false)
      ..close();
    canvas.drawPath(dirtPath, dirt);

    // ── Infield grass cutout (interior of diamond stays grass) ────────────
    final b1 = f(0.68, 0.74);  // 1B
    final b2 = f(0.50, 0.56);  // 2B
    final b3 = f(0.32, 0.74);  // 3B
    final mound = f(0.50, 0.78);

    final grassCut = Path()
      ..moveTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..lineTo(b3.dx, b3.dy)
      ..close();
    // Subtract grass cutout to keep dirt only along basepaths.
    // Using saveLayer then drawPath with blendmode:
    canvas.drawPath(
      grassCut,
      Paint()..color = const Color(0xFF1E5A1E)..style = PaintingStyle.fill,
    );

    // Pitcher's mound dirt circle
    canvas.drawCircle(
      mound,
      side * 0.045,
      Paint()..color = const Color(0xFFB07A4C)..style = PaintingStyle.fill,
    );

    // ── Foul lines ────────────────────────────────────────────────────────
    final lineP = linePaint..strokeWidth = 2.0;
    canvas.drawLine(home, foulNW, lineP);
    canvas.drawLine(home, foulNE, lineP);

    // Basepaths (chalk lines connecting bases)
    canvas.drawLine(home, b1, lineP);
    canvas.drawLine(home, b3, lineP);
    canvas.drawLine(b1, b2, lineP);
    canvas.drawLine(b2, b3, lineP);

    // ── Bases (white squares) ─────────────────────────────────────────────
    final baseSize = side * 0.022;
    final basePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final baseStroke = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final b in [b1, b2, b3]) {
      final rect = Rect.fromCenter(center: b, width: baseSize * 2, height: baseSize * 2);
      canvas.drawRect(rect, basePaint);
      canvas.drawRect(rect, baseStroke);
    }

    // Home plate (pentagon)
    final hp = Path();
    final hw = baseSize * 1.4;
    hp.moveTo(home.dx - hw, home.dy - hw * 0.4);
    hp.lineTo(home.dx + hw, home.dy - hw * 0.4);
    hp.lineTo(home.dx + hw, home.dy + hw * 0.4);
    hp.lineTo(home.dx, home.dy + hw);
    hp.lineTo(home.dx - hw, home.dy + hw * 0.4);
    hp.close();
    canvas.drawPath(hp, basePaint);
    canvas.drawPath(hp, baseStroke);

    // Pitcher's plate (rubber)
    canvas.drawRect(
      Rect.fromCenter(center: mound, width: side * 0.04, height: side * 0.008),
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );

    // Outer field boundary (subtle)
    canvas.drawRect(field, Paint()..color = Colors.white.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 1);
  }
}
