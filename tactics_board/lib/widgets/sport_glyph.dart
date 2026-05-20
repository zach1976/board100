import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sport_type.dart';

/// A coherent, flat sport-icon family drawn in code — replaces the
/// inconsistent emoji set (🥒 / 👣 / 🧶 …) that read as a cheap template.
/// Each glyph is the sport's real ball or implement in a uniform flat style.
class SportGlyph extends StatelessWidget {
  final SportType sport;
  final double size;
  const SportGlyph({super.key, required this.sport, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SportGlyphPainter(sport)),
    );
  }
}

class _SportGlyphPainter extends CustomPainter {
  final SportType sport;
  const _SportGlyphPainter(this.sport);

  @override
  void paint(Canvas canvas, Size size) {
    final n = size.width;
    final c = Offset(n / 2, n / 2);
    final r = n * 0.38;
    switch (sport) {
      case SportType.soccer:      _soccer(canvas, c, r); break;
      case SportType.basketball:  _basketball(canvas, c, r); break;
      case SportType.volleyball:  _volleyball(canvas, c, r); break;
      case SportType.tennis:      _tennis(canvas, c, r); break;
      case SportType.baseball:    _baseball(canvas, c, r); break;
      case SportType.rugby:       _rugby(canvas, c, r); break;
      case SportType.handball:    _seamBall(canvas, c, r, const Color(0xFF2E7BD6)); break;
      case SportType.waterPolo:   _waterPolo(canvas, c, r); break;
      case SportType.footvolley:  _seamBall(canvas, c, r, const Color(0xFFF6B73C)); break;
      case SportType.sepakTakraw: _takraw(canvas, c, r); break;
      case SportType.pickleball:  _pickleball(canvas, c, r); break;
      case SportType.tableTennis: _paddle(canvas, c, r, const Color(0xFFD0432F), holes: false); break;
      case SportType.beachTennis: _paddle(canvas, c, r, const Color(0xFF1F9E94), holes: true); break;
      case SportType.badminton:   _shuttle(canvas, c, r); break;
      case SportType.fieldHockey: _fieldHockey(canvas, c, r); break;
    }
  }

  // ── shared helpers ─────────────────────────────────────────────────────────
  Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _disc(Canvas canvas, Offset c, double r, Color fill, Color border) {
    canvas.drawCircle(c, r, _fill(fill));
    canvas.drawCircle(c, r, _stroke(border, r * 0.10));
  }

  /// Generic round ball with two gentle curved seams — used for the
  /// ball sports that don't need a bespoke pattern.
  void _seamBall(Canvas canvas, Offset c, double r, Color color) {
    _disc(canvas, c, r, color, Colors.black.withValues(alpha: 0.30));
    final seam = _stroke(Colors.white.withValues(alpha: 0.85), r * 0.13);
    canvas.drawArc(Rect.fromCircle(center: c.translate(-r * 1.1, 0), radius: r * 1.4),
        -0.7, 1.4, false, seam);
    canvas.drawArc(Rect.fromCircle(center: c.translate(r * 1.1, 0), radius: r * 1.4),
        math.pi - 0.7, 1.4, false, seam);
  }

  void _soccer(Canvas canvas, Offset c, double r) {
    _disc(canvas, c, r, Colors.white, const Color(0xFF333333));
    final dark = _fill(const Color(0xFF1E1E1E));
    final pent = Path();
    final pr = r * 0.40;
    for (int i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * pr;
      i == 0 ? pent.moveTo(p.dx, p.dy) : pent.lineTo(p.dx, p.dy);
    }
    pent.close();
    canvas.drawPath(pent, dark);
    final spoke = _stroke(const Color(0xFF1E1E1E), r * 0.11);
    for (int i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * pr, c + dir * (r * 0.92), spoke);
    }
  }

  void _basketball(Canvas canvas, Offset c, double r) {
    _disc(canvas, c, r, const Color(0xFFE2832B), const Color(0xFF8A4A12));
    final ln = _stroke(const Color(0xFF24160A), r * 0.11);
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), ln);
    canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), ln);
    canvas.drawArc(Rect.fromCircle(center: c.translate(-r * 1.55, 0), radius: r * 1.5),
        -0.62, 1.24, false, ln);
    canvas.drawArc(Rect.fromCircle(center: c.translate(r * 1.55, 0), radius: r * 1.5),
        math.pi - 0.62, 1.24, false, ln);
  }

  void _volleyball(Canvas canvas, Offset c, double r) {
    _disc(canvas, c, r, Colors.white, const Color(0xFF7E8794));
    final ln = _stroke(const Color(0xFF1E6FB8), r * 0.13);
    canvas.drawArc(Rect.fromCircle(center: c.translate(-r * 1.0, -r * 0.6), radius: r * 1.5),
        0.2, 1.1, false, ln);
    canvas.drawArc(Rect.fromCircle(center: c.translate(r * 1.0, -r * 0.6), radius: r * 1.5),
        math.pi - 1.3, 1.1, false, ln);
    canvas.drawArc(Rect.fromCircle(center: c.translate(0, r * 1.25), radius: r * 1.5),
        -math.pi / 2 - 0.55, 1.1, false, ln);
  }

  void _tennis(Canvas canvas, Offset c, double r) {
    _disc(canvas, c, r, const Color(0xFFC9DA3B), const Color(0xFF8A9A1E));
    final seam = _stroke(Colors.white, r * 0.13);
    final p = Path()
      ..moveTo(c.dx - r * 0.95, c.dy - r * 0.35)
      ..quadraticBezierTo(c.dx, c.dy - r * 0.1, c.dx, c.dy + r * 0.4)
      ..moveTo(c.dx + r * 0.95, c.dy + r * 0.35)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.1, c.dx, c.dy - r * 0.4);
    canvas.drawPath(p, seam);
  }

  void _baseball(Canvas canvas, Offset c, double r) {
    _disc(canvas, c, r, Colors.white, const Color(0xFF9AA0A6));
    final st = _stroke(const Color(0xFFD0432F), r * 0.10);
    for (final side in [-1.0, 1.0]) {
      final arc = Rect.fromCircle(center: c.translate(side * r * 1.35, 0), radius: r * 1.45);
      canvas.drawArc(arc, side > 0 ? math.pi - 0.5 : -0.5, 1.0, false, st);
    }
  }

  void _rugby(Canvas canvas, Offset c, double r) {
    final rect = Rect.fromCenter(center: c, width: r * 2.3, height: r * 1.45);
    canvas.drawOval(rect, _fill(const Color(0xFF7C4A2D)));
    canvas.drawOval(rect, _stroke(const Color(0xFF4A2A16), r * 0.10));
    final lace = _stroke(Colors.white, r * 0.12);
    canvas.drawLine(c.translate(-r * 0.5, 0), c.translate(r * 0.5, 0), lace);
    for (final dx in [-0.32, -0.1, 0.12, 0.34]) {
      canvas.drawLine(c.translate(r * dx, -r * 0.22), c.translate(r * dx, r * 0.22), lace);
    }
  }

  void _waterPolo(Canvas canvas, Offset c, double r) {
    _disc(canvas, c, r, const Color(0xFFF4C430), const Color(0xFFB9881A));
    final ln = _stroke(const Color(0xFF8A6410), r * 0.10);
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), ln);
    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(Rect.fromCircle(center: c.translate(side * r * 1.5, 0), radius: r * 1.5),
          side > 0 ? math.pi - 0.6 : -0.6, 1.2, false, ln);
    }
  }

  void _takraw(Canvas canvas, Offset c, double r) {
    _disc(canvas, c, r, const Color(0xFFD9A441), const Color(0xFF9A6E22));
    final w = _stroke(const Color(0xFF6E4A14), r * 0.09);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    for (int i = -3; i <= 3; i++) {
      final o = i * r * 0.42;
      canvas.drawLine(c.translate(o - r * 1.4, -r * 1.4), c.translate(o + r * 1.4, r * 1.4), w);
      canvas.drawLine(c.translate(o - r * 1.4, r * 1.4), c.translate(o + r * 1.4, -r * 1.4), w);
    }
    canvas.restore();
  }

  void _pickleball(Canvas canvas, Offset c, double r) {
    _disc(canvas, c, r, const Color(0xFFF2C200), const Color(0xFFB08F00));
    final hole = _fill(const Color(0xFF7A6200));
    for (int i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 0.52, r * 0.12, hole);
    }
    canvas.drawCircle(c, r * 0.12, hole);
  }

  void _paddle(Canvas canvas, Offset c, double r, Color blade, {required bool holes}) {
    // Handle.
    final hRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c.translate(r * 0.55, r * 0.95), width: r * 0.42, height: r * 1.2),
      Radius.circular(r * 0.2),
    );
    canvas.drawRRect(hRect, _fill(const Color(0xFF7A5230)));
    // Blade.
    final bc = c.translate(-r * 0.18, -r * 0.32);
    final br = r * 0.85;
    canvas.drawCircle(bc, br, _fill(blade));
    canvas.drawCircle(bc, br, _stroke(Colors.black.withValues(alpha: 0.28), r * 0.09));
    if (holes) {
      final h = _fill(Colors.white.withValues(alpha: 0.55));
      for (int i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5;
        canvas.drawCircle(bc + Offset(math.cos(a), math.sin(a)) * br * 0.5, br * 0.12, h);
      }
    }
  }

  void _shuttle(Canvas canvas, Offset c, double r) {
    // Feathers — trapezoid fanning up.
    final feather = Path()
      ..moveTo(c.dx - r * 0.30, c.dy + r * 0.25)
      ..lineTo(c.dx - r * 0.95, c.dy - r * 0.95)
      ..lineTo(c.dx + r * 0.95, c.dy - r * 0.95)
      ..lineTo(c.dx + r * 0.30, c.dy + r * 0.25)
      ..close();
    canvas.drawPath(feather, _fill(Colors.white));
    canvas.drawPath(feather, _stroke(const Color(0xFF8A93A0), r * 0.09));
    final rib = _stroke(const Color(0xFF8A93A0), r * 0.07);
    for (final dx in [-0.5, 0.0, 0.5]) {
      canvas.drawLine(
          c.translate(r * dx * 0.55, r * 0.2), c.translate(r * dx, -r * 0.92), rib);
    }
    // Cork.
    canvas.drawCircle(c.translate(0, r * 0.5), r * 0.4, _fill(const Color(0xFFE24B3B)));
    canvas.drawCircle(c.translate(0, r * 0.5), r * 0.4,
        _stroke(const Color(0xFF9A2C20), r * 0.08));
  }

  void _fieldHockey(Canvas canvas, Offset c, double r) {
    // Stick — shaft + hooked head.
    final stick = Path()
      ..moveTo(c.dx + r * 0.55, c.dy - r * 0.95)
      ..lineTo(c.dx - r * 0.15, c.dy + r * 0.55)
      ..quadraticBezierTo(
          c.dx - r * 0.35, c.dy + r * 0.95, c.dx - r * 0.85, c.dy + r * 0.85);
    canvas.drawPath(stick, _stroke(const Color(0xFFB87333), r * 0.26));
    canvas.drawPath(stick, _stroke(const Color(0xFF7A4A1E), r * 0.10));
    // Ball.
    canvas.drawCircle(c.translate(r * 0.6, r * 0.7), r * 0.32, _fill(Colors.white));
    canvas.drawCircle(c.translate(r * 0.6, r * 0.7), r * 0.32,
        _stroke(const Color(0xFF9AA0A6), r * 0.08));
  }

  @override
  bool shouldRepaint(_SportGlyphPainter old) => old.sport != sport;
}
