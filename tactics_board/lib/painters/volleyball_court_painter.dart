import 'package:flutter/material.dart';
import '../models/court_layout.dart';
import 'court_painter_base.dart';

class VolleyballCourtPainter extends CourtPainterBase {
  final CourtLayout layout;

  const VolleyballCourtPainter({this.layout = CourtLayout.full, Color? surface})
      : super(
          lineColor: Colors.white,
          courtColor: surface ?? const Color(0xFF2A5FA0),
        );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), courtPaint);

    // Blank court: surface only, no markings.
    if (layout == CourtLayout.blank) return;

    if (layout == CourtLayout.half) {
      _paintHalf(canvas, size);
      return;
    }

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Full court 18m x 9m (portrait)
    const courtRatio = 18.0 / 9.0;
    double cw, ch;
    if (h / w > courtRatio) {
      cw = w * 0.85;
      ch = cw * courtRatio;
    } else {
      ch = h * 0.85;
      cw = ch / courtRatio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    final scX = cw / 9.0;
    final scY = ch / 18.0;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p..strokeWidth = 3);
    p.strokeWidth = 2;

    // Net (middle) - thick band + bright line
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 9), o(9, 9), netBand);
    final netLine = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 9), o(9, 9), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 8.5), o(0, 9.5), postPaint);
    canvas.drawLine(o(9, 8.5), o(9, 9.5), postPaint);

    // Attack lines (3m from net each side)
    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    drawDashedLine(canvas, dashPaint, o(0, 9 - 3), o(9, 9 - 3));
    drawDashedLine(canvas, dashPaint, o(0, 9 + 3), o(9, 9 + 3));

  }

  /// One side of the net filling the canvas: net at the TOP edge, baseline at
  /// the BOTTOM edge. Home half is 9m wide × 9m deep.
  void _paintHalf(Canvas canvas, Size size) {
    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Half court 9m wide × 9m deep (net → baseline).
    const fieldW = 9.0;
    const fieldH = 9.0;
    const courtRatio = fieldH / fieldW;
    double cw, ch;
    if (h / w > courtRatio) {
      cw = w * 0.85;
      ch = cw * courtRatio;
    } else {
      ch = h * 0.85;
      cw = ch / courtRatio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;

    final scX = cw / fieldW;
    final scY = ch / fieldH;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p..strokeWidth = 3);
    p.strokeWidth = 2;

    // Net (top edge) - thick band + bright line
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 0), o(9, 0), netBand);
    final netLine = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 0), o(9, 0), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, -0.5), o(0, 0.5), postPaint);
    canvas.drawLine(o(9, -0.5), o(9, 0.5), postPaint);

    // Attack line (3m from net)
    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    drawDashedLine(canvas, dashPaint, o(0, 3), o(9, 3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! VolleyballCourtPainter ||
      oldDelegate.layout != layout ||
      oldDelegate.courtColor != courtColor;
}
