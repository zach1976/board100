import 'dart:math';
import 'package:flutter/material.dart';
import '../models/court_layout.dart';
import 'court_painter_base.dart';

class BeachTennisCourtPainter extends CourtPainterBase {
  final CourtLayout layout;

  const BeachTennisCourtPainter({this.layout = CourtLayout.full, Color? surface})
      : super(
          lineColor: Colors.white,
          courtColor: surface ?? const Color(0xFFEAC478),
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawSand(canvas, size);

    if (layout == CourtLayout.blank) return;

    if (layout == CourtLayout.half) {
      _paintHalf(canvas, size);
      return;
    }

    final w = size.width;
    final h = size.height;

    // ITF beach tennis court: 16m × 8m. Portrait → 8 wide × 16 tall.
    const fieldW = 8.0;
    const fieldH = 16.0;
    const ratio = fieldW / fieldH;

    // At SportType.fieldRect's 0.84 (tools/drills/engine.py COURT) — room
    // behind the far baseline.
    double cw, ch;
    if (w / h > ratio) {
      ch = h * 0.84;
      cw = ch * ratio;
    } else {
      cw = w * 0.84;
      ch = cw / ratio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    Offset o(double x, double y) => Offset(left + x * (cw / fieldW), top + y * (ch / fieldH));

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // Court boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), line);

    // Singles court, 4.5 m wide inside the 8 m doubles court (ITF beach
    // tennis rules). Lighter than the boundary: most play is doubles, and a
    // singles game is the one place these lines are the edge.
    final singles = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final x in const [1.75, 6.25]) {
      canvas.drawLine(o(x, 0), o(x, fieldH), singles);
    }

    // Net: the same band, mesh and tape as the tennis court — a faint
    // dashed line read as a centre line, not a 1.70 m net.
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, fieldH / 2), o(fieldW, fieldH / 2), netBand);
    drawNetMesh(canvas, o(0, fieldH / 2), o(fieldW, fieldH / 2), 10);
    final netLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, fieldH / 2), o(fieldW, fieldH / 2), netLine);
    final postPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, fieldH / 2 - 0.4), o(0, fieldH / 2 + 0.4), postPaint);
    canvas.drawLine(o(fieldW, fieldH / 2 - 0.4), o(fieldW, fieldH / 2 + 0.4), postPaint);
  }

  /// One side of the net filling the canvas: net at the TOP edge, baseline at
  /// the BOTTOM edge. Home half is 8m wide × 8m deep.
  void _paintHalf(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Half of the 8 × 16 court → 8 wide × 8 deep.
    const fieldW = 8.0;
    const fieldH = 8.0;
    const ratio = fieldW / fieldH;

    double cw, ch;
    if (w / h > ratio) {
      ch = h * 0.85;
      cw = ch * ratio;
    } else {
      cw = w * 0.85;
      ch = cw / ratio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    Offset o(double x, double y) => Offset(left + x * (cw / fieldW), top + y * (ch / fieldH));

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // Court boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), line);

    // Singles court, 4.5 m wide inside the 8 m doubles court (ITF beach
    // tennis rules). Lighter than the boundary: most play is doubles, and a
    // singles game is the one place these lines are the edge.
    final singles = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final x in const [1.75, 6.25]) {
      canvas.drawLine(o(x, 0), o(x, fieldH), singles);
    }

    // Net: the same band, mesh and tape as the tennis court — a faint
    // dashed line read as a centre line, not a 1.70 m net.
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 0), o(fieldW, 0), netBand);
    drawNetMesh(canvas, o(0, 0), o(fieldW, 0), 10);
    final netLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 0), o(fieldW, 0), netLine);
    final postPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, -0.4), o(0, 0.4), postPaint);
    canvas.drawLine(o(fieldW, -0.4), o(fieldW, 0.4), postPaint);
  }

  void _drawSand(Canvas canvas, Size size) {
    // Sand, lit from above like every other surface. No bands: nobody lays sand in strips.
    drawSurface(canvas, size);
    // Sand speckles — scattered tiny dots for sand texture
    final speckle = Paint()
      ..color = const Color(0xFFB88848).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final rnd = Random(42);
    final count = (size.width * size.height / 1200).round();
    for (int i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.8, speckle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! BeachTennisCourtPainter ||
      oldDelegate.layout != layout ||
      oldDelegate.courtColor != courtColor;
}
