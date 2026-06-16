import 'dart:math';
import 'package:flutter/material.dart';
import 'court_painter_base.dart';

/// Pitch layout variants offered in the "Field Type" picker.
///
/// New values are appended (never reordered) because the selection is
/// persisted by enum index. `half` keeps the goal at the top; `halfLeft` /
/// `halfRight` rotate that same half-pitch so the goal faces left / right.
enum SoccerFieldType { full, half, blank, halfLeft, halfRight }

/// A selectable grass colourway. The pitch is drawn with two alternating
/// stripe shades, so each turf option carries its own pair plus a swatch
/// colour for the picker dot.
class SoccerTurf {
  final Color swatch;
  final Color stripeA;
  final Color stripeB;
  const SoccerTurf(
      {required this.swatch, required this.stripeA, required this.stripeB});
}

/// Reproduces the original hard-coded colours exactly, so the default pitch is
/// visually unchanged. Also the painter's const default turf.
const SoccerTurf kDefaultSoccerTurf = SoccerTurf(
    swatch: Color(0xFF2D8A2D),
    stripeA: Color(0xFF2E7B30),
    stripeB: Color(0xFF2A7430));

const List<SoccerTurf> kSoccerTurfs = [
  kDefaultSoccerTurf, // Classic green
  SoccerTurf(
      swatch: Color(0xFF1E6B26),
      stripeA: Color(0xFF1F5E22),
      stripeB: Color(0xFF1B5520)), // Dark green
  SoccerTurf(
      swatch: Color(0xFF1C7C74),
      stripeA: Color(0xFF1C6E68),
      stripeB: Color(0xFF19655F)), // Teal turf
  SoccerTurf(
      swatch: Color(0xFF8A8550),
      stripeA: Color(0xFF7C784A),
      stripeB: Color(0xFF726E44)), // Dry olive
  SoccerTurf(
      swatch: Color(0xFF5A6066),
      stripeA: Color(0xFF53585E),
      stripeB: Color(0xFF4C5157)), // Grey
];

class SoccerCourtPainter extends CourtPainterBase {
  // Softer off-white reduces glare while staying high-contrast on grass.
  static const Color _softLine = Color(0xE6F1F4F0);

  final SoccerFieldType fieldType;
  final SoccerTurf turf;

  const SoccerCourtPainter({
    this.fieldType = SoccerFieldType.full,
    this.turf = kDefaultSoccerTurf,
  }) : super(
          lineColor: _softLine,
          courtColor: const Color(0xFF2D8A2D),
        );

  @override
  void paint(Canvas canvas, Size size) {
    // Grass stripes
    _drawGrass(canvas, size);

    // Blank pitch: grass only, no markings.
    if (fieldType == SoccerFieldType.blank) {
      _drawVignette(canvas, size);
      return;
    }

    if (fieldType == SoccerFieldType.half ||
        fieldType == SoccerFieldType.halfLeft ||
        fieldType == SoccerFieldType.halfRight) {
      final w = size.width;
      final h = size.height;
      canvas.save();
      if (fieldType == SoccerFieldType.halfRight) {
        // Rotate 90° clockwise: the top goal end swings to the right edge.
        canvas.translate(w, 0);
        canvas.rotate(pi / 2);
        _paintHalf(canvas, Size(h, w));
      } else if (fieldType == SoccerFieldType.halfLeft) {
        // Rotate 90° anti-clockwise: the goal end swings to the left edge.
        canvas.translate(0, h);
        canvas.rotate(-pi / 2);
        _paintHalf(canvas, Size(h, w));
      } else {
        _paintHalf(canvas, size);
      }
      canvas.restore();
      _drawVignette(canvas, size);
      return;
    }

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
      ..color = _softLine
      ..style = PaintingStyle.fill;
    final strokeThick = Paint()
      ..color = _softLine
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

    // ── Vignette: subtle radial darkening toward edges to focus the eye on
    //     the center of the field. Drawn last so it sits on top of the lines.
    _drawVignette(canvas, size);
  }

  void _drawGrass(Canvas canvas, Size size) {
    // Lower contrast between stripes to reduce visual noise.
    const stripeCount = 12;
    final stripeH = size.height / stripeCount;
    final colors = [turf.stripeA, turf.stripeB];
    for (int i = 0; i < stripeCount; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, size.width, stripeH),
        Paint()
          ..color = colors[i % 2]
          ..style = PaintingStyle.fill,
      );
    }
  }

  /// Attacking half: one goal end at the top, the halfway line forming the
  /// bottom boundary with the centre-circle arc bulging up into play.
  void _paintHalf(Canvas canvas, Size size) {
    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // Top 52.5m of the 68m-wide pitch.
    const fieldW = 68.0;
    const fieldH = 52.5;
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
      ..color = _softLine
      ..style = PaintingStyle.fill;
    final strokeThick = Paint()
      ..color = _softLine
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Outer boundary (halfway line is the bottom edge).
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // Centre circle (upper half) + centre spot on the halfway line.
    canvas.drawArc(
      Rect.fromCircle(center: o(34, fieldH), radius: 9.15 * scX),
      pi,
      pi,
      false,
      p,
    );
    canvas.drawCircle(o(34, fieldH), 0.35 * scX, fillWhite);

    // Top penalty area (16.5m deep, 40.32m wide) + goal area.
    const paLeft = (fieldW - 40.32) / 2; // 13.84
    canvas.drawRect(
      Rect.fromLTWH(o(paLeft, 0).dx, o(paLeft, 0).dy, 40.32 * scX, 16.5 * scY),
      p,
    );
    const gaLeft = (fieldW - 18.32) / 2; // 24.84
    canvas.drawRect(
      Rect.fromLTWH(o(gaLeft, 0).dx, o(gaLeft, 0).dy, 18.32 * scX, 5.5 * scY),
      p,
    );
    canvas.drawCircle(o(34, 11), 0.35 * scX, fillWhite);
    final topArcAngle = asin(5.5 / 9.15);
    final topArcSweep = pi - 2 * topArcAngle;
    canvas.drawArc(
      Rect.fromCircle(center: o(34, 11), radius: 9.15 * scX),
      topArcAngle,
      topArcSweep,
      false,
      p,
    );

    // Top corner arcs (r = 1m).
    final cr = 1.0 * scX;
    canvas.drawArc(Rect.fromCircle(center: o(0, 0), radius: cr),
        0, pi / 2, false, p);
    canvas.drawArc(Rect.fromCircle(center: o(fieldW, 0), radius: cr),
        pi / 2, pi / 2, false, p);

    // Goal (7.32m wide × 2.44m deep).
    const goalLeft = (fieldW - 7.32) / 2; // 30.34
    const goalDepth = 2.44;
    canvas.drawRect(
      Rect.fromLTWH(o(goalLeft, -goalDepth).dx, o(goalLeft, -goalDepth).dy,
          7.32 * scX, goalDepth * scY),
      strokeThick,
    );
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shader = RadialGradient(
      center: Alignment.center,
      radius: 0.85,
      colors: const [
        Color(0x00000000),
        Color(0x33000000), // ~20% black at edges
      ],
      stops: const [0.65, 1.0],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  // Base returns false unconditionally; repaint when the layout or grass
  // colour actually changes so the picker updates the board live.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! SoccerCourtPainter ||
        oldDelegate.fieldType != fieldType ||
        oldDelegate.turf != turf;
  }
}
