import 'dart:math';
import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final String? selectedStrokeId;
  /// IDs of strokes included in the multi-select set. Drawn with the same
  /// glow as the single-select highlight, but in a green tint so it reads
  /// as part of a group selection rather than the focused single edit.
  final Set<String> multiSelectStrokeIds;

  const DrawingPainter({
    required this.strokes,
    this.currentStroke,
    this.selectedStrokeId,
    this.multiSelectStrokeIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (selectedStrokeId != null && stroke.id == selectedStrokeId) {
        // Draw glow behind selected stroke
        final glowPaint = Paint()
          ..color = Colors.yellow.withValues(alpha: 0.4)
          ..strokeWidth = stroke.width + 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final path = _buildPath(stroke);
        canvas.drawPath(path, glowPaint);
      } else if (multiSelectStrokeIds.contains(stroke.id)) {
        final glowPaint = Paint()
          ..color = const Color(0xFF00C2B2).withValues(alpha: 0.55)
          ..strokeWidth = stroke.width + 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawPath(_buildPath(stroke), glowPaint);
      }
      _paintStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _paintStroke(canvas, currentStroke!);
    }
  }

  /// The points that define the stroke's spine. A [LineShape.straight] stroke
  /// ignores the wobble of the drawn path and spans first → last, so both the
  /// body and the terminator angle read off the same two points.
  List<Offset> _spine(DrawingStroke stroke) =>
      stroke.shape == LineShape.straight
          ? [stroke.points.first, stroke.points.last]
          : stroke.points;

  /// Smoothed curve through [points] using midpoint quadratics.
  Path _smoothPath(List<Offset> points) {
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      if (i == 1) {
        path.lineTo(points[i].dx, points[i].dy);
      } else {
        final mid = (points[i - 1] + points[i]) / 2;
        path.quadraticBezierTo(points[i - 1].dx, points[i - 1].dy, mid.dx, mid.dy);
      }
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  Path _buildPath(DrawingStroke stroke) {
    final base = _smoothPath(_spine(stroke));
    return stroke.shape == LineShape.wavy
        ? _wavify(base, stroke.width, dashed: stroke.style == StrokeStyle.dashed)
        : base;
  }

  /// Resample [base] into a sine wave oscillating about it. Amplitude tapers to
  /// zero at both ends so terminators and dash phase still sit on the spine.
  ///
  /// A [dashed] wave is stretched out: each dash then spans a gentler arc, so
  /// the line reads as a broken squiggle rather than a row of commas.
  Path _wavify(Path base, double strokeWidth, {required bool dashed}) {
    final amp = (strokeWidth * 1.2).clamp(3.0, 8.0);
    final preferred =
        (strokeWidth * 6.0).clamp(16.0, 36.0) * (dashed ? 1.6 : 1.0);
    const step = 1.5;
    final out = Path();
    for (final metric in base.computeMetrics()) {
      if (metric.length < step * 2) continue; // degenerate
      // Shrink the wavelength to fit at least two full waves in a short
      // stroke. A fixed wavelength would make anything shorter than one wave
      // render as a flat line, silently ignoring the style the user picked.
      final wavelength = min(preferred, metric.length / 2);
      // Taper amplitude to zero at both ends so terminators and dash phase sit
      // on the spine — but never spend more than a quarter of a short stroke
      // fading in, or the wave flattens out again.
      final fade = min(wavelength * 0.75, metric.length * 0.25);
      bool started = false;
      for (double d = 0; d <= metric.length; d += step) {
        final t = metric.getTangentForOffset(d);
        if (t == null) continue;
        final normal = Offset(-t.vector.dy, t.vector.dx);
        final taper =
            (d / fade).clamp(0.0, 1.0) * ((metric.length - d) / fade).clamp(0.0, 1.0);
        final p = t.position + normal * (amp * taper * sin(d / wavelength * 2 * pi));
        started ? out.lineTo(p.dx, p.dy) : out.moveTo(p.dx, p.dy);
        started = true;
      }
    }
    return out;
  }

  void _paintStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.length < 2) return;

    // Use a square (butt) cap when anything is attached to the end so the
    // rounded cap doesn't blob past the terminator on thick strokes — the
    // terminator covers the join. Round cap stays for plain strokes.
    final hasEndArrow =
        stroke.arrow == ArrowStyle.end || stroke.arrow == ArrowStyle.both;
    final hasStartArrow = stroke.arrow == ArrowStyle.both;
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap =
          stroke.arrow == ArrowStyle.none ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = _buildPath(stroke);

    // Trim the path so the arrow head replaces the last (and optionally
    // first) chunk of the line. Prevents thick-stroke blob where the
    // round cap pokes past the arrow tip and gives the arrow a clean
    // triangular silhouette instead of one stacked on a wider tail.
    // Cross and T-bar sit *on* the endpoint, so they trim nothing.
    Path drawPath = path;
    if (hasEndArrow || hasStartArrow) {
      final trim = _arrowSize(stroke.width) * 0.55;
      drawPath = _trimEnds(
        path,
        trimStart: hasStartArrow ? trim : 0,
        trimEnd: hasEndArrow ? trim : 0,
      );
    }

    if (stroke.style == StrokeStyle.dashed) {
      _drawDashedPath(canvas, paint, drawPath);
    } else {
      canvas.drawPath(drawPath, paint);
    }

    if (stroke.arrow != ArrowStyle.none) {
      _drawTerminator(canvas, paint, _spine(stroke), stroke.arrow);
    }
  }

  /// Trim [path] by removing [trimStart] units off the front and
  /// [trimEnd] off the tail. Returns an empty path if the trim would
  /// consume the entire stroke.
  Path _trimEnds(Path path, {double trimStart = 0, double trimEnd = 0}) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      final start = trimStart.clamp(0.0, metric.length);
      final end = (metric.length - trimEnd).clamp(start, metric.length);
      if (end <= start) continue;
      out.addPath(metric.extractPath(start, end), Offset.zero);
    }
    return out;
  }

  /// Arrowhead size as a function of stroke width — scales linearly
  /// (roughly 3× width) so thick strokes get visibly larger arrows. The
  /// small +4 keeps thin strokes from disappearing into a tiny tip and
  /// the upper clamp keeps absurdly wide strokes (which we don't allow
  /// today anyway) from producing comic-book arrows.
  double _arrowSize(double strokeWidth) =>
      (strokeWidth * 3 + 4).clamp(12.0, 50.0);

  void _drawDashedPath(Canvas canvas, Paint paint, Path path) {
    final metrics = path.computeMetrics();
    // Scale the pattern with the stroke so a thin line doesn't turn into
    // dots and a thick one doesn't read as a solid bar. At the default width
    // of 3 this reproduces the previous fixed 12/8 pattern.
    final dashLen = (paint.strokeWidth * 4.0).clamp(6.0, 40.0);
    final gapLen = (paint.strokeWidth * 2.6).clamp(4.0, 26.0);
    for (final metric in metrics) {
      double start = 0;
      bool draw = true;
      while (start < metric.length) {
        final seg = draw ? dashLen : gapLen;
        final end = (start + seg).clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        start = end;
        draw = !draw;
      }
    }
  }

  void _drawTerminator(
      Canvas canvas, Paint paint, List<Offset> points, ArrowStyle arrow) {
    final dir = _stableDirection(points, fromEnd: true);
    switch (arrow) {
      case ArrowStyle.none:
        return;
      case ArrowStyle.end:
      case ArrowStyle.both:
        final fill = Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill;
        _arrowAt(canvas, fill, points.last, dir, paint.strokeWidth);
        if (arrow == ArrowStyle.both) {
          _arrowAt(canvas, fill, points.first,
              _stableDirection(points, fromEnd: false), paint.strokeWidth);
        }
      case ArrowStyle.cross:
        _crossAt(canvas, paint, points.last, dir);
      case ArrowStyle.tbar:
        _barAt(canvas, paint, points.last, dir);
    }
  }

  /// An X centred on [tip], rotated 45° off the line direction. Coaches use it
  /// to mark a screen, a block, or the end of a run.
  void _crossAt(Canvas canvas, Paint paint, Offset tip, double angle) {
    final arm = _arrowSize(paint.strokeWidth) * 0.5;
    final bar = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final a in [angle + pi / 4, angle - pi / 4]) {
      final d = Offset(cos(a), sin(a)) * arm;
      canvas.drawLine(tip - d, tip + d, bar);
    }
  }

  /// A bar perpendicular to the line at [tip] — the classic "stop here" mark.
  void _barAt(Canvas canvas, Paint paint, Offset tip, double angle) {
    final half = _arrowSize(paint.strokeWidth) * 0.5;
    final n = Offset(-sin(angle), cos(angle)) * half;
    canvas.drawLine(
      tip - n,
      tip + n,
      Paint()
        ..color = paint.color
        ..strokeWidth = paint.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  /// Get a stable direction angle by looking at a segment farther back,
  /// not just the last two (often jittery) points.
  double _stableDirection(List<Offset> points, {required bool fromEnd}) {
    const minDist = 20.0; // look back at least 20px for stable angle
    if (fromEnd) {
      final tip = points.last;
      for (int i = points.length - 2; i >= 0; i--) {
        if ((points[i] - tip).distance >= minDist) {
          return atan2(tip.dy - points[i].dy, tip.dx - points[i].dx);
        }
      }
      final p = points[max(0, points.length - 2)];
      return atan2(tip.dy - p.dy, tip.dx - p.dx);
    } else {
      final tip = points.first;
      for (int i = 1; i < points.length; i++) {
        if ((points[i] - tip).distance >= minDist) {
          return atan2(tip.dy - points[i].dy, tip.dx - points[i].dx);
        }
      }
      final p = points[min(1, points.length - 1)];
      return atan2(tip.dy - p.dy, tip.dx - p.dx);
    }
  }

  void _arrowAt(Canvas canvas, Paint paint, Offset tip, double angle, double width) {
    final arrowSize = _arrowSize(width);
    // Slightly narrower spread (28°) so thick strokes don't end in a
    // squat triangle; pairs with the longer body trim for a sharper
    // pointer silhouette.
    const spread = pi * 28 / 180;
    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * cos(angle - spread),
      tip.dy - arrowSize * sin(angle - spread),
    );
    // Notch the base in slightly along the line direction so the arrow
    // blends with the trimmed stroke body instead of presenting a flat
    // wide base. Notch depth ≈ stroke width / 2.
    final notch = width * 0.5;
    path.lineTo(
      tip.dx - (arrowSize - notch) * cos(angle),
      tip.dy - (arrowSize - notch) * sin(angle),
    );
    path.lineTo(
      tip.dx - arrowSize * cos(angle + spread),
      tip.dy - arrowSize * sin(angle + spread),
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.currentStroke != currentStroke ||
      oldDelegate.selectedStrokeId != selectedStrokeId ||
      oldDelegate.multiSelectStrokeIds != multiSelectStrokeIds;
}
