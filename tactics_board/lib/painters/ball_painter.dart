import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sport_type.dart';

abstract class BallPainter extends CustomPainter {
  const BallPainter();

  static BallPainter forSport(SportType sport) {
    switch (sport) {
      case SportType.badminton:    return const ShuttlecockPainter();
      case SportType.tableTennis:  return const PingPongBallPainter();
      case SportType.tennis:       return const TennisBallPainter();
      case SportType.basketball:   return const BasketballPainter();
      case SportType.volleyball:   return const VolleyballPainter();
      case SportType.pickleball:   return const PickleballPainter();
      case SportType.soccer:       return const SoccerBallPainter();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Badminton Shuttlecock  (side-view silhouette)
// ─────────────────────────────────────────────────────────────────────────────
class ShuttlecockPainter extends BallPainter {
  const ShuttlecockPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r  = size.width / 2;

    // Layout: cork at bottom, feather cone going up
    final corkCY  = r * 1.55;   // cork center (below canvas mid)
    final corkR   = r * 0.30;
    final rimCY   = r * 0.22;   // rim oval center (near top)
    final rimW    = r * 0.88;   // half-width of rim oval
    final rimH    = r * 0.18;   // half-height of rim oval (flat ellipse)
    final neckY   = corkCY - corkR; // top of cork

    // ── Feather body fill (trapezoid) ──────────────────────────────────────
    final bodyPath = Path()
      ..moveTo(cx - corkR * 0.7, neckY)
      ..lineTo(cx - rimW, rimCY)
      ..lineTo(cx + rimW, rimCY)
      ..lineTo(cx + corkR * 0.7, neckY)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    // ── Individual feather lines (inside cone) ─────────────────────────────
    const featherCount = 7;
    final featherPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < featherCount; i++) {
      final t = i / (featherCount - 1);           // 0..1 left→right
      final tipX  = cx - rimW + 2 * rimW * t;
      final tipY  = rimCY + rimH * (1 - 4 * (t - 0.5) * (t - 0.5)); // ellipse arc
      final baseX = cx - corkR * 0.6 + 2 * corkR * 0.6 * t;
      canvas.drawLine(Offset(baseX, neckY), Offset(tipX, tipY), featherPaint);
    }

    // ── Rim oval ───────────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, rimCY), width: rimW * 2, height: rimH * 2),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );

    // ── Cork – gradient sphere ─────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, corkCY),
      corkR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [const Color(0xFFE8A87C), const Color(0xFF8B4513)],
        ).createShader(Rect.fromCircle(center: Offset(cx, corkCY), radius: corkR)),
    );
    // cork shine
    canvas.drawCircle(
      Offset(cx - corkR * 0.28, corkCY - corkR * 0.28),
      corkR * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    // cork outline
    canvas.drawCircle(
      Offset(cx, corkCY),
      corkR,
      Paint()
        ..color = const Color(0xFF5D2E0C)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Tennis Ball
// ─────────────────────────────────────────────────────────────────────────────
class PingPongBallPainter extends BallPainter {
  const PingPongBallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    // Base ball - white/orange
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [Colors.white, const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, basePaint);

    // Seam line
    final seamPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85),
      -pi * 0.2, pi * 1.4, false, seamPaint,
    );

    // Shine
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.3), r * 0.2, shinePaint);

    // Border
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = const Color(0xFFBDBDBD)..style = PaintingStyle.stroke..strokeWidth = 0.8);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tennis Ball
// ─────────────────────────────────────────────────────────────────────────────
class TennisBallPainter extends BallPainter {
  const TennisBallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    // Yellow-green base
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 1.0,
        colors: [const Color(0xFFCCDD00), const Color(0xFFB8CC00)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, basePaint);

    // White seam curves (characteristic tennis S-curve)
    final seamPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top seam
    final path1 = Path();
    path1.moveTo(cx - r * 0.6, cy - r * 0.1);
    path1.cubicTo(
      cx - r * 0.2, cy - r * 0.9,
      cx + r * 0.2, cy - r * 0.9,
      cx + r * 0.6, cy - r * 0.1,
    );
    canvas.drawPath(path1, seamPaint);

    // Bottom seam
    final path2 = Path();
    path2.moveTo(cx - r * 0.6, cy + r * 0.1);
    path2.cubicTo(
      cx - r * 0.2, cy + r * 0.9,
      cx + r * 0.2, cy + r * 0.9,
      cx + r * 0.6, cy + r * 0.1,
    );
    canvas.drawPath(path2, seamPaint);

    // Shine
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.35), r * 0.15,
        Paint()..color = Colors.white.withValues(alpha: 0.5));

    // Border
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = const Color(0xFF9E9E00)..style = PaintingStyle.stroke..strokeWidth = 0.8);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Basketball
// ─────────────────────────────────────────────────────────────────────────────
class BasketballPainter extends BallPainter {
  const BasketballPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    // Orange base
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 1.0,
        colors: [const Color(0xFFFF8C00), const Color(0xFFE65100)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, basePaint);

    // Black seam lines
    final seamPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Vertical center line
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.95),
      -pi / 2, pi, false, seamPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.95),
      pi / 2, pi, false, seamPaint,
    );

    // Horizontal line
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), seamPaint);

    // Top arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy - r * 0.5), radius: r * 0.8),
      0, pi, false, seamPaint,
    );

    // Bottom arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy + r * 0.5), radius: r * 0.8),
      pi, pi, false, seamPaint,
    );

    // Shine
    canvas.drawCircle(Offset(cx - r * 0.28, cy - r * 0.32), r * 0.14,
        Paint()..color = Colors.white.withValues(alpha: 0.35));

    // Clip to circle
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Volleyball
// ─────────────────────────────────────────────────────────────────────────────
class VolleyballPainter extends BallPainter {
  const VolleyballPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    final clipPath = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.clipPath(clipPath);

    // Panel colors
    final colors = [
      const Color(0xFF1565C0), // blue
      const Color(0xFFFFD600), // yellow
      Colors.white,
    ];

    // Draw 3 panels as arcs
    for (int i = 0; i < 3; i++) {
      final paint = Paint()..color = colors[i]..style = PaintingStyle.fill;
      final startAngle = (2 * pi / 3) * i - pi / 6;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle, 2 * pi / 3, true, paint,
      );
    }

    // Panel seam lines
    final seamPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final angle = (2 * pi / 3) * i - pi / 6;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + cos(angle) * r, cy + sin(angle) * r),
        seamPaint,
      );
    }

    // Shine
    canvas.drawCircle(Offset(cx - r * 0.25, cy - r * 0.3), r * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.5));

    // Border
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pickleball
// ─────────────────────────────────────────────────────────────────────────────
class PickleballPainter extends BallPainter {
  const PickleballPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    // Yellow base
    final basePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 1.0,
        colors: [const Color(0xFFFFEE58), const Color(0xFFFDD835)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, basePaint);

    // Holes pattern
    final holePaint = Paint()
      ..color = const Color(0xFFE65100).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final holePositions = [
      Offset(cx, cy),
      Offset(cx - r * 0.45, cy - r * 0.45),
      Offset(cx + r * 0.45, cy - r * 0.45),
      Offset(cx - r * 0.45, cy + r * 0.45),
      Offset(cx + r * 0.45, cy + r * 0.45),
      Offset(cx - r * 0.55, cy),
      Offset(cx + r * 0.55, cy),
      Offset(cx, cy - r * 0.55),
      Offset(cx, cy + r * 0.55),
    ];
    for (final pos in holePositions) {
      canvas.drawCircle(pos, r * 0.11, holePaint);
    }

    // Shine
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.32), r * 0.14,
        Paint()..color = Colors.white.withValues(alpha: 0.6));

    // Border
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = const Color(0xFFF9A825)..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Soccer Ball  (classic black-and-white Telstar pattern)
// ─────────────────────────────────────────────────────────────────────────────
class SoccerBallPainter extends BallPainter {
  const SoccerBallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    // Clip to circle
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // White base
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white..style = PaintingStyle.fill);

    final blackPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    // Draw central pentagon and 5 surrounding ones (Telstar pattern)
    _drawPentagon(canvas, blackPaint, cx, cy, r * 0.26, -pi / 2);

    // 5 surrounding pentagons — centers at ~55% radius, each rotated 180° (pointing inward)
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (2 * pi / 5) * i;
      final px = cx + cos(angle) * r * 0.58;
      final py = cy + sin(angle) * r * 0.58;
      _drawPentagon(canvas, blackPaint, px, py, r * 0.24, angle + pi);
    }

    // Shine
    canvas.drawCircle(Offset(cx - r * 0.28, cy - r * 0.30), r * 0.14,
        Paint()..color = Colors.white.withValues(alpha: 0.55));

    // Border
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()
          ..color = const Color(0xFF333333)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  void _drawPentagon(Canvas canvas, Paint paint, double cx, double cy,
      double r, double startAngle) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a = startAngle + (2 * pi / 5) * i;
      final x = cx + cos(a) * r;
      final y = cy + sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
