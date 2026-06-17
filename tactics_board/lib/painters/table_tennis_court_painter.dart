import 'package:flutter/material.dart';
import '../models/court_layout.dart';
import 'court_painter_base.dart';

class TableTennisCourtPainter extends CourtPainterBase {
  final CourtLayout layout;

  const TableTennisCourtPainter({this.layout = CourtLayout.full, Color? surface})
      : super(
          lineColor: Colors.white,
          courtColor: surface ?? const Color(0xFF1E4874),
        );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF0E3452)..style = PaintingStyle.fill);

    if (layout == CourtLayout.half) {
      _paintHalf(canvas, size);
      return;
    }

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Table: 2.74m x 1.525m (portrait)
    const tableRatio = 2.74 / 1.525;
    double tw, th;
    if (h / w > tableRatio) {
      tw = w * 0.65;
      th = tw * tableRatio;
    } else {
      th = h * 0.55;
      tw = th / tableRatio;
    }
    final left = (w - tw) / 2;
    final top = (h - th) / 2;

    // Table surface
    canvas.drawRect(
      Rect.fromLTWH(left, top, tw, th),
      Paint()..color = courtColor..style = PaintingStyle.fill,
    );

    // Blank court: surface only, no markings.
    if (layout == CourtLayout.blank) return;

    final scX = tw / 1.525;
    final scY = th / 2.74;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary (thick)
    canvas.drawRect(Rect.fromLTWH(left, top, tw, th), p..strokeWidth = 3);
    p.strokeWidth = 2;

    // Center service line (doubles only)
    canvas.drawLine(o(0.7625, 0), o(0.7625, 2.74),
        Paint()..strokeWidth = 1..color = Colors.white.withValues(alpha: 0.7)..style = PaintingStyle.stroke);

    // Net - thick band + bright line
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 1.37), o(1.525, 1.37), netBand);
    final netLine = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 1.37), o(1.525, 1.37), netLine);
    // Net posts (extend slightly outside table)
    final postPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(-0.04, 1.25), o(-0.04, 1.49), postPaint);
    canvas.drawLine(o(1.565, 1.25), o(1.565, 1.49), postPaint);
  }

  /// One end of the table filling the canvas: net at the TOP edge, end line at
  /// the BOTTOM edge. Half table is 1.525m wide × 1.37m deep. The centre
  /// service line is kept (it runs the full depth of the half).
  void _paintHalf(Canvas canvas, Size size) {
    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Half table: 1.525m wide × 1.37m deep (portrait).
    const fieldW = 1.525;
    const fieldH = 2.74 / 2; // 1.37
    const tableRatio = fieldH / fieldW;
    double tw, th;
    if (h / w > tableRatio) {
      tw = w * 0.65;
      th = tw * tableRatio;
    } else {
      th = h * 0.55;
      tw = th / tableRatio;
    }
    final left = (w - tw) / 2;
    final top = (h - th) / 2;

    // Table surface
    canvas.drawRect(
      Rect.fromLTWH(left, top, tw, th),
      Paint()..color = courtColor..style = PaintingStyle.fill,
    );

    final scX = tw / fieldW;
    final scY = th / fieldH;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary (thick)
    canvas.drawRect(Rect.fromLTWH(left, top, tw, th), p..strokeWidth = 3);
    p.strokeWidth = 2;

    // Center service line (doubles only) — full depth of the half
    canvas.drawLine(o(0.7625, 0), o(0.7625, fieldH),
        Paint()..strokeWidth = 1..color = Colors.white.withValues(alpha: 0.7)..style = PaintingStyle.stroke);

    // Net — thick band + bright line along the TOP edge
    final netBand = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 0), o(1.525, 0), netBand);
    final netLine = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 0), o(1.525, 0), netLine);
    // Net posts (extend slightly outside table)
    final postPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(-0.04, -0.12), o(-0.04, 0.12), postPaint);
    canvas.drawLine(o(1.565, -0.12), o(1.565, 0.12), postPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! TableTennisCourtPainter ||
      oldDelegate.layout != layout ||
      oldDelegate.courtColor != courtColor;
}
