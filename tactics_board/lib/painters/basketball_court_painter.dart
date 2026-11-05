import 'dart:math';
import 'package:flutter/material.dart';
import '../models/court_layout.dart';
import 'court_painter_base.dart';

class BasketballCourtPainter extends CourtPainterBase {
  final CourtLayout layout;

  const BasketballCourtPainter({
    this.layout = CourtLayout.full,
    Color floor = const Color(0xFFD9A867),
  }) : super(
          lineColor: Colors.white,
          courtColor: floor,
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawWood(canvas, size);

    // Blank court: hardwood only, no markings.
    if (layout == CourtLayout.blank) return;

    // Another court than FIBA's: NBA, NCAA or high school.
    if (layout.isOwnPitch) return _paintCourt(canvas, size, _Court.of(layout));

    if (layout == CourtLayout.half) {
      _paintHalfCourt(canvas, size);
      return;
    }

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // FIBA court: 15m wide × 28m long (portrait)
    const courtW = 15.0;
    const courtH = 28.0;
    const ratio = courtW / courtH;

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
    final sc = cw / courtW;

    Offset o(double x, double y) => Offset(left + x * sc, top + y * sc);

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // Center line
    canvas.drawLine(o(0, 14), o(15, 14), p);

    // Center circle (r = 1.8m)
    canvas.drawCircle(o(7.5, 14), 1.8 * sc, p);

    // Both halves
    _drawHalf(canvas, p, o, sc, isTop: true);
    _drawHalf(canvas, p, o, sc, isTop: false);
  }

  /// One basket end (15m × 14m) scaled to fill the board: basket at the top,
  /// the half-court line forming the bottom edge with the centre-circle arc
  /// bulging up into play.
  void _paintHalfCourt(Canvas canvas, Size size) {
    final p = linePaint;
    final w = size.width;
    final h = size.height;

    const courtW = 15.0;
    const halfH = 14.0;
    const ratio = courtW / halfH;

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
    final sc = cw / courtW;
    Offset o(double x, double y) => Offset(left + x * sc, top + y * sc);

    // Outer boundary (half-court line is the bottom edge).
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // Centre-circle arc on the half-court line, opening up into play.
    canvas.drawArc(
      Rect.fromCircle(center: o(7.5, halfH), radius: 1.8 * sc),
      pi,
      pi,
      false,
      p,
    );

    // Reuse the top-half markings (basket, key, three-point arc).
    _drawHalf(canvas, p, o, sc, isTop: true);
  }

  /// The FIBA court's box on this canvas (SportType.fieldRect). The NBA,
  /// NCAA and high-school courts are drawn inside it at their own
  /// proportions — so a board's positions are the same fractions of the
  /// same box whichever court is under them, and nothing saved moves.
  static Rect courtBox(Size size) {
    const ratio = 15.0 / 28.0;
    final w = size.width, h = size.height;
    double cw, ch;
    if (w / h > ratio) {
      ch = h * 0.90;
      cw = ch * ratio;
    } else {
      cw = w * 0.90;
      ch = cw / ratio;
    }
    return Rect.fromLTWH((w - cw) / 2, (h - ch) / 2, cw, ch);
  }

  /// Where a court [c] lies on the canvas: as large as fits in [courtBox]
  /// and centred in it. The 94 ft courts are as tall as the box and a shade
  /// narrower (50/94 against 15/28); the 84 ft high-school court is as
  /// wide as the box and nine tenths of its height.
  static Rect _courtRect(Size size, _Court c) {
    final box = courtBox(size);
    final sc = min(box.width / c.width, box.height / c.length);
    return Rect.fromCenter(
        center: box.center, width: c.width * sc, height: c.length * sc);
  }

  /// A full court of [c]: boundary, division line, centre circle, and the
  /// same markings at both ends.
  void _paintCourt(Canvas canvas, Size size, _Court c) {
    final p = linePaint;
    final r = _courtRect(size, c);
    final sc = r.width / c.width;
    Offset o(double x, double y) => Offset(r.left + x * sc, r.top + y * sc);

    canvas.drawRect(r, p);
    canvas.drawLine(o(0, c.length / 2), o(c.width, c.length / 2), p);
    final centre = o(c.width / 2, c.length / 2);
    canvas.drawCircle(centre, c.circleR * sc, p);
    if (c.innerCircleR > 0) canvas.drawCircle(centre, c.innerCircleR * sc, p);

    _drawEnd(canvas, p, o, sc, c, isTop: true);
    _drawEnd(canvas, p, o, sc, c, isTop: false);
  }

  /// One basket end of [c]: the key and free-throw line with its
  /// semicircle, the backboard and rim, the three-point arc with its
  /// corner lines, and the restricted-area arc where the court has one.
  void _drawEnd(Canvas canvas, Paint p, Offset Function(double, double) o,
      double sc, _Court c,
      {required bool isTop}) {
    final cx = c.width / 2;
    // x across the court, d in from this end's baseline.
    Offset e(double x, double d) => o(x, isTop ? d : c.length - d);
    // Where a semicircle that opens towards mid-court starts.
    final toward = isTop ? 0.0 : pi;

    // The key, its far edge the free-throw line.
    canvas.drawRect(
        Rect.fromPoints(e(cx - c.keyW / 2, 0), e(cx + c.keyW / 2, c.keyD)), p);
    canvas.drawArc(Rect.fromCircle(center: e(cx, c.keyD), radius: c.ftR * sc),
        toward, pi, false, p);

    // Backboard and rim.
    canvas.drawLine(e(cx - c.bbW / 2, c.bbDist), e(cx + c.bbW / 2, c.bbDist), p);
    final rimC = e(cx, c.basketDist);
    canvas.drawCircle(
        rimC,
        _Court.rimR * sc,
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = p.strokeWidth);

    // Three-point line: straight from the baseline, parallel to the
    // sideline, up to where the arc round the basket reaches it.
    final dxCorner = cx - c.cornerX;
    final arcYOffset =
        sqrt(max(0.0, c.threeR * c.threeR - dxCorner * dxCorner));
    final cornerLineLen = c.basketDist + arcYOffset;
    canvas.drawLine(e(c.cornerX, 0), e(c.cornerX, cornerLineLen), p);
    canvas.drawLine(
        e(c.width - c.cornerX, 0), e(c.width - c.cornerX, cornerLineLen), p);
    final a = atan2(arcYOffset, dxCorner);
    canvas.drawArc(Rect.fromCircle(center: rimC, radius: c.threeR * sc),
        isTop ? a : -(pi - a), pi - 2 * a, false, p);

    // Restricted area.
    if (c.restrictedR > 0) {
      canvas.drawArc(Rect.fromCircle(center: rimC, radius: c.restrictedR * sc),
          toward, pi, false, p);
    }
  }

  // Base returns false unconditionally; repaint when the layout or floor colour
  // changes so the picker updates the board live.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! BasketballCourtPainter ||
        oldDelegate.layout != layout ||
        oldDelegate.courtColor != courtColor;
  }

  /// Maple-floor texture — replaces the flat single-tone fill: faint vertical
  /// plank seams plus a centre-lit vignette so the court reads as a real
  /// hardwood surface with depth, not a plastic slab.
  void _drawWood(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), courtPaint);

    // Plank seams — thin, low-contrast vertical lines.
    const plankCount = 24;
    final plankW = w / plankCount;
    final seam = Paint()
      ..color = const Color(0x12000000)
      ..strokeWidth = 1.0;
    for (int i = 1; i < plankCount; i++) {
      canvas.drawLine(Offset(i * plankW, 0), Offset(i * plankW, h), seam);
    }

    // Centre-lit vignette — brighter middle, deeper edges, for depth.
    final shader = const RadialGradient(
      center: Alignment.center,
      radius: 0.95,
      colors: [Color(0x1FFFFFFF), Color(0x00000000), Color(0x2B000000)],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _drawHalf(Canvas canvas, Paint p, Offset Function(double, double) o,
      double sc, {required bool isTop}) {
    const cx = 7.5;
    const courtW = 15.0;
    // FIBA since 2010: a rectangle 4.9 m wide. The 6.0→3.6 m trapezoid was
    // the old rule, and the board drew it under a store page promising an
    // accurate court. Both ends kept as names so the path below is unchanged.
    const keyBaseW = 4.9; // key width at the baseline
    const keyFtW = 4.9; // key width at the free-throw line
    const keyD = 5.8; // key depth
    const basketDist = 1.575;
    const bbDist = 1.2;
    const threeR = 6.75;
    const cornerX = 0.9;

    final dxCorner = cx - cornerX;
    final arcYOffset = sqrt(threeR * threeR - dxCorner * dxCorner);
    final cornerLineLen = basketDist + arcYOffset;

    if (isTop) {
      // --- TOP HALF ---

      // The key: a 4.9 m rectangle (FIBA)
      final keyPath = Path()
        ..moveTo(o(cx - keyBaseW / 2, 0).dx, o(0, 0).dy)
        ..lineTo(o(cx - keyFtW / 2, keyD).dx, o(0, keyD).dy)
        ..lineTo(o(cx + keyFtW / 2, keyD).dx, o(0, keyD).dy)
        ..lineTo(o(cx + keyBaseW / 2, 0).dx, o(0, 0).dy);
      canvas.drawPath(keyPath, p);
      // Free throw line (top of key)
      canvas.drawLine(o(cx - keyFtW / 2, keyD), o(cx + keyFtW / 2, keyD), p);

      // Free throw semicircle (opens downward toward mid-court)
      final ftCenter = o(cx, keyD);
      canvas.drawArc(Rect.fromCircle(center: ftCenter, radius: 1.8 * sc), 0, pi, false, p);

      // Backboard
      canvas.drawLine(o(cx - 0.9, bbDist), o(cx + 0.9, bbDist), p);

      // Basket rim
      final rimC = o(cx, basketDist);
      canvas.drawCircle(rimC, 0.225 * sc, Paint()..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = p.strokeWidth);

      // Three-point corner lines (from baseline going down)
      canvas.drawLine(o(cornerX, 0), o(cornerX, cornerLineLen), p);
      canvas.drawLine(o(courtW - cornerX, 0), o(courtW - cornerX, cornerLineLen), p);

      // Three-point arc
      final arcCenter = o(cx, basketDist);
      final arcR = threeR * sc;
      // Angle from center to right corner endpoint
      final rightAngle = atan2(arcYOffset * sc, dxCorner * sc); // positive y = downward
      // Arc from rightAngle sweeping to (π - rightAngle)
      canvas.drawArc(
        Rect.fromCircle(center: arcCenter, radius: arcR),
        rightAngle,
        pi - 2 * rightAngle,
        false,
        p,
      );

      // Restricted area (no-charge semicircle r=1.25m)
      canvas.drawArc(Rect.fromCircle(center: rimC, radius: 1.25 * sc), 0, pi, false, p);

    } else {
      // --- BOTTOM HALF ---

      // The key
      final keyPath = Path()
        ..moveTo(o(cx - keyBaseW / 2, 28).dx, o(0, 28).dy)
        ..lineTo(o(cx - keyFtW / 2, 28 - keyD).dx, o(0, 28 - keyD).dy)
        ..lineTo(o(cx + keyFtW / 2, 28 - keyD).dx, o(0, 28 - keyD).dy)
        ..lineTo(o(cx + keyBaseW / 2, 28).dx, o(0, 28).dy);
      canvas.drawPath(keyPath, p);
      canvas.drawLine(o(cx - keyFtW / 2, 28 - keyD), o(cx + keyFtW / 2, 28 - keyD), p);

      // Free throw semicircle (opens upward toward mid-court)
      final ftCenter = o(cx, 28 - keyD);
      canvas.drawArc(Rect.fromCircle(center: ftCenter, radius: 1.8 * sc), pi, pi, false, p);

      // Backboard
      canvas.drawLine(o(cx - 0.9, 28 - bbDist), o(cx + 0.9, 28 - bbDist), p);

      // Basket rim
      final rimC = o(cx, 28 - basketDist);
      canvas.drawCircle(rimC, 0.225 * sc, Paint()..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = p.strokeWidth);

      // Three-point corner lines (from baseline going up)
      canvas.drawLine(o(cornerX, 28), o(cornerX, 28 - cornerLineLen), p);
      canvas.drawLine(o(courtW - cornerX, 28), o(courtW - cornerX, 28 - cornerLineLen), p);

      // Three-point arc
      final arcCenter = o(cx, 28 - basketDist);
      final arcR = threeR * sc;
      final rightAngle = atan2(arcYOffset * sc, dxCorner * sc);
      // Arc opens upward (negative y direction)
      canvas.drawArc(
        Rect.fromCircle(center: arcCenter, radius: arcR),
        -(pi - rightAngle),
        pi - 2 * rightAngle,
        false,
        p,
      );

      // Restricted area
      canvas.drawArc(Rect.fromCircle(center: rimC, radius: 1.25 * sc), pi, pi, false, p);
    }
  }
}

/// A court's measurements in feet, portrait: [width] across, [length] end
/// to end, and the rest in from a baseline — the key's width and depth (its
/// far edge the free-throw line), the free-throw circle, the centre circle
/// and the inner one the NBA paints, the backboard's distance and width, the
/// basket's centre, the three-point arc and its corner lines' distance from
/// the sideline, and the restricted-area arc (0: none).
class _Court {
  final double width, length, keyW, keyD, ftR, circleR, innerCircleR;
  final double bbDist, bbW, basketDist, threeR, cornerX, restrictedR;

  /// An 18 in rim.
  static const double rimR = 0.75;

  const _Court({
    required this.width,
    required this.length,
    required this.keyW,
    required this.keyD,
    required this.ftR,
    required this.circleR,
    this.innerCircleR = 0,
    required this.bbDist,
    required this.bbW,
    required this.basketDist,
    required this.threeR,
    required this.cornerX,
    required this.restrictedR,
  });

  /// NBA: 94 x 50 ft, a 16 ft key, the free-throw line 15 ft from the
  /// backboard (4 ft in), the rim's centre 15 in before that, a 6 ft
  /// free-throw circle, the centre circle 6 ft round a 2 ft one, the
  /// three-point arc 23 ft 9 in from the basket meeting lines 3 ft from the
  /// sideline (22 ft from the basket), the restricted area 4 ft.
  static const nba = _Court(
    width: 50, length: 94, keyW: 16, keyD: 19, ftR: 6,
    circleR: 6, innerCircleR: 2, bbDist: 4, bbW: 6, basketDist: 5.25,
    threeR: 23.75, cornerX: 3, restrictedR: 4,
  );

  /// NCAA men's (2024 rules): the NBA court with a 12 ft key and the FIBA
  /// arc, 22 ft 1¾ in, meeting lines 3 ft 4⅛ in from the sideline.
  static const ncaa = _Court(
    width: 50, length: 94, keyW: 12, keyD: 19, ftR: 6,
    circleR: 6, bbDist: 4, bbW: 6, basketDist: 5.25,
    threeR: 22 + 1.75 / 12, cornerX: 3 + 4.125 / 12, restrictedR: 4,
  );

  /// NFHS high school: 84 x 50 ft, a 12 ft key, the 19 ft 9 in arc meeting
  /// lines 5 ft 3 in from the sideline level with the basket, and no
  /// restricted-area arc (a state option, left off).
  static const highSchool = _Court(
    width: 50, length: 84, keyW: 12, keyD: 19, ftR: 6,
    circleR: 6, bbDist: 4, bbW: 6, basketDist: 5.25,
    threeR: 19.75, cornerX: 5.25, restrictedR: 0,
  );

  static _Court of(CourtLayout layout) => switch (layout) {
        CourtLayout.nba => nba,
        CourtLayout.ncaa => ncaa,
        _ => highSchool,
      };
}
