import 'dart:math';
import 'package:flutter/material.dart';
import '../models/court_layout.dart';
import 'court_painter_base.dart';

class FieldHockeyCourtPainter extends CourtPainterBase {
  final CourtLayout layout;

  const FieldHockeyCourtPainter({this.layout = CourtLayout.full, Color? surface})
      : super(
          lineColor: Colors.white,
          courtColor: surface ?? const Color(0xFF1976D2),
        );

  @override
  void paint(Canvas canvas, Size size) {
    _drawTurf(canvas, size);

    // Blank court: turf only, no markings.
    if (layout == CourtLayout.blank) return;
    if (layout == CourtLayout.indoor) return _paintIndoor(canvas, size);
    if (layout == CourtLayout.hockey5s) return _paintHockey5s(canvas, size);

    if (layout == CourtLayout.half ||
        layout == CourtLayout.halfLeft ||
        layout == CourtLayout.halfRight) {
      final sw = size.width, sh = size.height;
      canvas.save();
      if (layout == CourtLayout.halfRight) {
        canvas.translate(sw, 0);
        canvas.rotate(pi / 2);
        _paintHalf(canvas, Size(sh, sw));
      } else if (layout == CourtLayout.halfLeft) {
        canvas.translate(0, sh);
        canvas.rotate(-pi / 2);
        _paintHalf(canvas, Size(sh, sw));
      } else {
        _paintHalf(canvas, size);
      }
      canvas.restore();
      return;
    }

    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // FIH standard: 91.4m × 55m, portrait = 55m wide × 91.4m tall
    const fieldW = 55.0;
    const fieldH = 91.4;
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

    // ── Outer boundary ──────────────────────────────────────────────────────
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // ── Halfway line ────────────────────────────────────────────────────────
    canvas.drawLine(o(0, fieldH / 2), o(fieldW, fieldH / 2), p);

    // ── 23m lines ───────────────────────────────────────────────────────────
    const line23 = 22.9;
    canvas.drawLine(o(0, line23), o(fieldW, line23), p);
    canvas.drawLine(o(0, fieldH - line23), o(fieldW, fieldH - line23), p);

    // ── Shooting circles (D-arc, radius 14.63m from goal posts) ─────────────
    // Goal is 3.66m wide centered on goal line. The D is formed by arcs
    // centered on each post plus a short straight segment between.
    const goalW = 3.66;
    const arcR = 14.63;
    const goalLeft = (fieldW - goalW) / 2; // 25.67
    const goalRight = goalLeft + goalW;    // 29.33

    void drawD(double baselineY, {required bool bottom}) {
      // Arcs from each post: 90° quarter circle sweeping from baseline to
      // center, then straight segment between top of arcs.
      final postL = o(goalLeft, baselineY);
      final postR = o(goalRight, baselineY);
      final rX = arcR * scX;
      final rY = arcR * scY;
      final leftArcRect = Rect.fromCenter(
          center: postL, width: rX * 2, height: rY * 2);
      final rightArcRect = Rect.fromCenter(
          center: postR, width: rX * 2, height: rY * 2);
      if (bottom) {
        // Home side (bottom): arc opens upward (toward field center)
        canvas.drawArc(leftArcRect, pi, pi / 2, false, p);
        canvas.drawArc(rightArcRect, -pi / 2, pi / 2, false, p);
        canvas.drawLine(
          o(goalLeft, baselineY - arcR),
          o(goalRight, baselineY - arcR),
          p,
        );
      } else {
        // Away side (top): arc opens downward
        canvas.drawArc(leftArcRect, pi / 2, pi / 2, false, p);
        canvas.drawArc(rightArcRect, 0, pi / 2, false, p);
        canvas.drawLine(
          o(goalLeft, baselineY + arcR),
          o(goalRight, baselineY + arcR),
          p,
        );
      }
    }

    drawD(0, bottom: false);        // away/top D
    drawD(fieldH, bottom: true);    // home/bottom D

    // ── Dashed 5m arcs outside the D (short corner reference) ───────────────
    // Drawn as short hash marks at penalty-stroke spot
    canvas.drawCircle(o(fieldW / 2, 6.4), 0.3 * scX,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(o(fieldW / 2, fieldH - 6.4), 0.3 * scX,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    // ── Center spot ─────────────────────────────────────────────────────────
    canvas.drawCircle(o(fieldW / 2, fieldH / 2), 0.3 * scX,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    // ── Goals (3.66m wide × 1.2m deep) ──────────────────────────────────────
    const goalDepth = 1.2;
    drawGoal(
        canvas,
        Rect.fromLTWH(o(goalLeft, -goalDepth).dx, o(goalLeft, -goalDepth).dy,
            goalW * scX, goalDepth * scY),
        pitch: size);
    drawGoal(
        canvas,
        Rect.fromLTWH(o(goalLeft, fieldH).dx, o(goalLeft, fieldH).dy,
            goalW * scX, goalDepth * scY),
        pitch: size);
  }

  /// One end (top 45.7m of the pitch) scaled to fill the board: the goal +
  /// shooting circle (D) at the top, the 23m line below it, and the halfway
  /// line forming the bottom edge.
  void _paintHalf(Canvas canvas, Size size) {
    final p = linePaint;
    final w = size.width;
    final h = size.height;

    // FIH standard: 91.4m × 55m; half = top 45.7m of the 55m-wide pitch.
    const fieldW = 55.0;
    const fieldH = 91.4 / 2; // 45.7
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

    // Outer boundary (halfway line is the bottom edge).
    canvas.drawRect(Rect.fromLTWH(left, top, cw, ch), p);

    // 23m line near the goal end.
    const line23 = 22.9;
    canvas.drawLine(o(0, line23), o(fieldW, line23), p);

    // Shooting circle (D-arc, radius 14.63m from goal posts) at the top.
    const goalW = 3.66;
    const arcR = 14.63;
    const goalLeft = (fieldW - goalW) / 2; // 25.67
    const goalRight = goalLeft + goalW; // 29.33
    final postL = o(goalLeft, 0);
    final postR = o(goalRight, 0);
    final rX = arcR * scX;
    final rY = arcR * scY;
    final leftArcRect =
        Rect.fromCenter(center: postL, width: rX * 2, height: rY * 2);
    final rightArcRect =
        Rect.fromCenter(center: postR, width: rX * 2, height: rY * 2);
    // Arc opens downward (toward field center).
    canvas.drawArc(leftArcRect, pi / 2, pi / 2, false, p);
    canvas.drawArc(rightArcRect, 0, pi / 2, false, p);
    canvas.drawLine(o(goalLeft, arcR), o(goalRight, arcR), p);

    // Penalty-stroke spot.
    canvas.drawCircle(o(fieldW / 2, 6.4), 0.3 * scX,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    // Goal (3.66m wide × 1.2m deep).
    const goalDepth = 1.2;
    drawGoal(
        canvas,
        Rect.fromLTWH(o(goalLeft, -goalDepth).dx, o(goalLeft, -goalDepth).dy,
            goalW * scX, goalDepth * scY),
        pitch: size);
  }

  /// The full pitch's box on this canvas (SportType.fieldRect). The indoor
  /// pitch and the Hockey5s court are drawn inside it, as tall as it, at
  /// their own width — so a board's positions are the same fractions of the
  /// same box whichever pitch is under them, and nothing saved moves.
  static Rect pitchBox(Size size) {
    const ratio = 55.0 / 91.4;
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

  /// Width of the indoor pitch as a share of [pitchBox]'s: 44 x 22 m, the
  /// FIH's recommended (and World Cup) size, inside the 91.4 x 55 m box.
  static const double indoorWidthShare = (22.0 / 44.0) / (55.0 / 91.4);

  /// Width of the Hockey5s court as a share of [pitchBox]'s: the FIH's
  /// standard 40 x 23.76 m court (goal plus five 2 m boards each side).
  static const double hockey5sWidthShare = (23.76 / 40.0) / (55.0 / 91.4);

  /// A pitch of [fieldW] x [fieldH] metres, as tall as [pitchBox] and
  /// centred in it; returns the metres-to-canvas mapping.
  static Offset Function(double, double) _metres(
      Size size, double fieldW, double fieldH) {
    final box = pitchBox(size);
    final ch = box.height;
    final cw = ch * fieldW / fieldH;
    final left = box.center.dx - cw / 2;
    final top = box.top;
    return (x, y) => Offset(left + x * cw / fieldW, top + y * ch / fieldH);
  }

  void _spot(Canvas canvas, Offset at, double r) => canvas.drawCircle(
      at, r, Paint()..color = lineColor..style = PaintingStyle.fill);

  /// A rebound board along [a]→[b], laid just outside the line: a light
  /// strip with a dark edge, so it reads as a raised board, not a line.
  void _board(Canvas canvas, Offset a, Offset b, double thick, Offset out) {
    final n = out * thick;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(b.dx + n.dx, b.dy + n.dy)
      ..lineTo(a.dx + n.dx, a.dy + n.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE9E1C8));
    canvas.drawLine(a + n, b + n,
        Paint()
          ..color = const Color(0x66000000)
          ..strokeWidth = 1.0);
  }

  /// FIH indoor hockey: 44 x 22 m, side-boards along both side-lines, a
  /// centre line, at each end a circle of 9 m quarter-arcs round the posts
  /// of a 3 m goal, the broken line 3 m outside it (30 cm dashes, 2 m gaps,
  /// starting at the top centre) and the penalty spot 7 m out.
  void _paintIndoor(Canvas canvas, Size size) {
    const fw = 22.0, fh = 44.0;
    final o = _metres(size, fw, fh);
    final p = linePaint;
    final scX = (o(1, 0) - o(0, 0)).dx;
    final scY = (o(0, 1) - o(0, 0)).dy;
    // Side-boards, outside the side-lines.
    _board(canvas, o(0, 0), o(0, fh), 0.45 * scX, const Offset(-1, 0));
    _board(canvas, o(fw, 0), o(fw, fh), 0.45 * scX, const Offset(1, 0));
    canvas.drawRect(Rect.fromPoints(o(0, 0), o(fw, fh)), p);
    canvas.drawLine(o(0, fh / 2), o(fw, fh / 2), p);

    const goalW = 3.0, r = 9.0, broken = 12.0;
    const postL = (fw - goalW) / 2, postR = postL + goalW;
    for (final top in [true, false]) {
      // y measured from this end's back-line, into the pitch.
      Offset e(double x, double d) => o(x, top ? d : fh - d);
      // The circle: two quarter-arcs and the 3 m line joining them.
      final pts = <Offset>[];
      for (var i = 0; i <= 24; i++) {
        final t = (pi / 2) * (1 - i / 24);
        pts.add(e(postL - r * sin(t), r * cos(t)));
      }
      for (var i = 0; i <= 24; i++) {
        final t = (pi / 2) * (i / 24);
        pts.add(e(postR + r * sin(t), r * cos(t)));
      }
      canvas.drawPath(Path()..addPolygon(pts, false), p);
      // The broken line, walked out from its top centre both ways.
      for (final side in [-1.0, 1.0]) {
        final post = side < 0 ? postL : postR;
        final line = <Offset>[e(fw / 2, broken)];
        for (var i = 0; i <= 60; i++) {
          final t = (pi / 2) * (i / 60);
          final x = post + side * broken * sin(t);
          if (x < 0 || x > fw) break; // it runs into the side-board
          line.add(e(x, broken * cos(t)));
        }
        _dashed(canvas, line, 0.3 * scY, 2.0 * scY);
      }
      _spot(canvas, e(fw / 2, 7.0), 0.15 * scX + 1.2);
      // The penalty-corner marks on the back-line, 6 m out from each post
      // (30 cm long by the rules; drawn 60 cm so a phone shows them).
      for (final x in [postL - 6.0, postR + 6.0]) {
        canvas.drawLine(e(x, 0), e(x, 0.6), p);
      }
      // Goal: 3 m wide, 1 m deep, outside the back-line.
      final a = e(postL, top ? -1.0 : 0), b = e(postR, top ? 0 : -1.0);
      drawGoal(canvas, Rect.fromPoints(a, b), pitch: size);
    }
  }

  /// FIH Hockey5s: a 40 x 23.76 m court with no circles (a goal can be
  /// scored from anywhere in the attacking half), rebound boards along the
  /// side- and back-lines but not across the goal, the centre line, the
  /// two quarter-lines halfway to each back-line, penalty spots 6.40 m out.
  void _paintHockey5s(Canvas canvas, Size size) {
    const fw = 23.76, fh = 40.0;
    final o = _metres(size, fw, fh);
    final p = linePaint;
    final scX = (o(1, 0) - o(0, 0)).dx;
    final t = 0.4 * scX;
    const goalW = 3.66;
    const postL = (fw - goalW) / 2, postR = postL + goalW;
    _board(canvas, o(0, 0), o(0, fh), t, const Offset(-1, 0));
    _board(canvas, o(fw, 0), o(fw, fh), t, const Offset(1, 0));
    for (final y in [0.0, fh]) {
      final out = Offset(0, y == 0 ? -1 : 1);
      _board(canvas, o(0, y), o(postL, y), t, out);
      _board(canvas, o(postR, y), o(fw, y), t, out);
    }
    canvas.drawRect(Rect.fromPoints(o(0, 0), o(fw, fh)), p);
    canvas.drawLine(o(0, fh / 2), o(fw, fh / 2), p);
    canvas.drawLine(o(0, fh / 4), o(fw, fh / 4), p);
    canvas.drawLine(o(0, fh * 3 / 4), o(fw, fh * 3 / 4), p);
    _spot(canvas, o(fw / 2, 6.4), 0.15 * scX + 1.2);
    _spot(canvas, o(fw / 2, fh - 6.4), 0.15 * scX + 1.2);
    const depth = 1.2;
    drawGoal(canvas, Rect.fromPoints(o(postL, -depth), o(postR, 0)),
        pitch: size);
    drawGoal(canvas, Rect.fromPoints(o(postL, fh), o(postR, fh + depth)),
        pitch: size);
  }

  /// [dash] on, [gap] off, along a polyline, starting with a dash.
  void _dashed(Canvas canvas, List<Offset> pts, double dash, double gap) {
    final p = linePaint;
    var on = true;
    var left = dash;
    for (var i = 1; i < pts.length; i++) {
      var a = pts[i - 1];
      final b = pts[i];
      var seg = (b - a).distance;
      while (seg > 0) {
        final step = min(seg, left);
        final next = a + (b - a) / (b - a).distance * step;
        if (on) canvas.drawLine(a, next, p);
        a = next;
        seg -= step;
        left -= step;
        if (left <= 1e-6) {
          on = !on;
          left = on ? dash : gap;
        }
      }
    }
  }

  void _drawTurf(Canvas canvas, Size size) {
    // Blue water-based astroturf. It has no mowing stripes the way grass
    // does — it is a carpet — but it is laid in rolls, and under floodlights
    // the seams read as faint bands down the pitch. Flat, it was a slab of
    // one blue with white lines drawn on it.
    drawSurface(canvas, size, bands: 12, bandTint: 0.035);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! FieldHockeyCourtPainter ||
      oldDelegate.layout != layout ||
      oldDelegate.courtColor != courtColor;
}
