import 'package:flutter/material.dart';
import '../models/court_layout.dart';
import 'court_painter_base.dart';

class PickleballCourtPainter extends CourtPainterBase {
  final CourtLayout layout;

  const PickleballCourtPainter({this.layout = CourtLayout.full, Color? surface})
      : super(
          lineColor: Colors.white,
          courtColor: surface ?? const Color(0xFF2A6DA8),
        );

  @override
  void paint(Canvas canvas, Size size) {
    // Blank court: surface only, no markings.
    if (layout == CourtLayout.blank) return drawSurface(canvas, size);

    // Half court: one side of the net filling the board.
    if (layout == CourtLayout.half) {
      _paintHalf(canvas, size);
      return;
    }

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Court: 13.41m x 6.1m (portrait), at SportType.fieldRect's 0.82
    // (tools/drills/engine.py COURT) — room behind the far baseline.
    const courtRatio = 13.41 / 6.1;
    double cw, ch;
    if (h / w > courtRatio) {
      cw = w * 0.82;
      ch = cw * courtRatio;
    } else {
      ch = h * 0.82;
      cw = ch / courtRatio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;
    _floor(canvas, size, Rect.fromLTWH(left, top, cw, ch));

    final scX = cw / 6.1;
    final scY = ch / 13.41;
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p..strokeWidth = 3);
    p.strokeWidth = 2;

    // Net (middle) - thick band + bright line
    final netBand = Paint()
      ..color = const Color(0xFF20252B).withValues(alpha: 0.55)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 13.41 / 2), o(6.1, 13.41 / 2), netBand);
    drawNetMesh(canvas, o(0, 13.41 / 2), o(6.1, 13.41 / 2), 10);
    final netLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 13.41 / 2), o(6.1, 13.41 / 2), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFF20252B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 13.41 / 2 - 0.4), o(0, 13.41 / 2 + 0.4), postPaint);
    canvas.drawLine(o(6.1, 13.41 / 2 - 0.4), o(6.1, 13.41 / 2 + 0.4), postPaint);

    // Non-volley zone (kitchen) - 2.13m from net each side
    // Top half
    canvas.drawRect(
      Rect.fromLTWH(
        o(0, 13.41 / 2 - 2.13).dx,
        o(0, 13.41 / 2 - 2.13).dy,
        cw,
        2.13 * scY,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(o(0, 13.41 / 2 - 2.13), o(6.1, 13.41 / 2 - 2.13), p);

    // Bottom half kitchen
    canvas.drawRect(
      Rect.fromLTWH(
        o(0, 13.41 / 2).dx,
        o(0, 13.41 / 2).dy,
        cw,
        2.13 * scY,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(o(0, 13.41 / 2 + 2.13), o(6.1, 13.41 / 2 + 2.13), p);

    // Center line (service boxes)
    canvas.drawLine(o(3.05, 0), o(3.05, 13.41 / 2 - 2.13), p);
    canvas.drawLine(o(3.05, 13.41 / 2 + 2.13), o(3.05, 13.41), p);
  }

  /// The surface: the court in its own colour inside a surround of another,
  /// the way a dedicated pickleball court is painted — blue inside green
  /// most often, green inside blue on some. One colour to the edge of the
  /// canvas read as a badminton court. The net is black with a white tape.
  void _floor(Canvas canvas, Size size, Rect court) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = surroundFor(courtColor)..style = PaintingStyle.fill);
    canvas.save();
    canvas.clipRect(court);
    // A hard court: one poured surface, so no strips — only the light.
    drawSurface(canvas, size);
    canvas.restore();
  }

  /// The surround colour that goes with a court colour: green round the
  /// blue, blue round the green, a lighter shade of itself round any other.
  static Color surroundFor(Color court) {
    if (court == const Color(0xFF1769B4)) return const Color(0xFF36875D);
    if (court == const Color(0xFF2E7D32)) return const Color(0xFF1769B4);
    final hsl = HSLColor.fromColor(court);
    return hsl.withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0)).toColor();
  }

  // Half court: home side only (net at top edge, baseline at bottom).
  void _paintHalf(Canvas canvas, Size size) {
    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Half of the court: 6.1m wide x 6.705m deep (net to baseline).
    const halfLen = 13.41 / 2;
    const courtRatio = halfLen / 6.1;
    double cw, ch;
    if (h / w > courtRatio) {
      cw = w * 0.88;
      ch = cw * courtRatio;
    } else {
      ch = h * 0.88;
      cw = ch / courtRatio;
    }
    final left = (w - cw) / 2;
    final top = (h - ch) / 2;
    _floor(canvas, size, Rect.fromLTWH(left, top, cw, ch));

    final scX = cw / 6.1;
    final scY = ch / halfLen;
    // y = 0 is the net (top edge); y = halfLen is the baseline (bottom edge).
    Offset o(double x, double y) => Offset(left + x * scX, top + y * scY);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p..strokeWidth = 3);
    p.strokeWidth = 2;

    // Net (top edge) - thick band + bright line
    final netBand = Paint()
      ..color = const Color(0xFF20252B).withValues(alpha: 0.55)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 0), o(6.1, 0), netBand);
    drawNetMesh(canvas, o(0, 0), o(6.1, 0), 10);
    final netLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, 0), o(6.1, 0), netLine);
    // Net posts
    final postPaint = Paint()
      ..color = const Color(0xFF20252B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(o(0, -0.4), o(0, 0.4), postPaint);
    canvas.drawLine(o(6.1, -0.4), o(6.1, 0.4), postPaint);

    // Non-volley zone (kitchen) - 2.13m from net
    canvas.drawRect(
      Rect.fromLTWH(
        o(0, 0).dx,
        o(0, 0).dy,
        cw,
        2.13 * scY,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawLine(o(0, 2.13), o(6.1, 2.13), p);

    // Center line (service boxes) - kitchen line to baseline
    canvas.drawLine(o(3.05, 2.13), o(3.05, halfLen), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! PickleballCourtPainter ||
      oldDelegate.layout != layout ||
      oldDelegate.courtColor != courtColor;
}
