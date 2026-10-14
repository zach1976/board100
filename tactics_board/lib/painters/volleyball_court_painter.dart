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
    // Blank court: surface only, no markings.
    if (layout == CourtLayout.blank) {
      drawSurface(canvas, size, bands: 10, bandTint: 0.03);
      return;
    }

    if (layout == CourtLayout.half) {
      _paintHalf(canvas, size);
      return;
    }

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Full court 18m x 9m (portrait), at SportType.fieldRect's 0.84
    // (tools/drills/engine.py COURT) — room behind the far end line.
    const courtRatio = 18.0 / 9.0;
    double cw, ch;
    if (h / w > courtRatio) {
      cw = w * 0.84;
      ch = cw * courtRatio;
    } else {
      ch = h * 0.84;
      cw = ch / courtRatio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;
    _floor(canvas, size, Rect.fromLTWH(left, top, cw, ch));

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
    drawNetMesh(canvas, o(0, 9), o(9, 9), 12);
    final netLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 9), o(9, 9), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFF37474F)
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

  /// The floor: the court in its own colour, the free zone round it in
  /// another, the way an FIVB hall is laid — an orange court sits in a blue
  /// free zone, a blue one in orange. One colour for the whole canvas read
  /// as a court with no edge; the lines were the only thing saying where
  /// the free zone began. The net tape is white, as the rules have it.
  void _floor(Canvas canvas, Size size, Rect court) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = freeZoneFor(courtColor)..style = PaintingStyle.fill);
    canvas.save();
    canvas.clipRect(court);
    // An indoor sport floor, laid in strips and lit from above.
    drawSurface(canvas, size, bands: 10, bandTint: 0.03);
    canvas.restore();
  }

  /// The free-zone colour that goes with a court colour: the FIVB pairings
  /// for the orange and blue surfaces, a lighter shade of the same for any
  /// other.
  static Color freeZoneFor(Color court) {
    if (court == const Color(0xFFF57F17)) return const Color(0xFF2A5FA0);
    if (court == const Color(0xFF1565C0)) return const Color(0xFFE67E22);
    final hsl = HSLColor.fromColor(court);
    return hsl.withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0)).toColor();
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
    _floor(canvas, size, Rect.fromLTWH(left, top, cw, ch));

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
    drawNetMesh(canvas, o(0, 0), o(9, 0), 12);
    final netLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 0), o(9, 0), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFF37474F)
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
