import 'package:flutter/material.dart';

import '../models/drill.dart';
import '../ui/tokens.dart';

/// A drill, small enough to scan a list of a hundred.
///
/// Deliberately NOT a shrunken [TacticsCanvas]: the canvas is the real board
/// — sprites, animation controllers, gesture recognisers, a repaint boundary
/// — and a hundred of them in a scrolling list is a hundred of all that. This
/// paints the two things that make a drill recognisable at 64pt, straight
/// from the same `drill.board` JSON: the surface, and where the players are.
///
/// One shape for the whole library (§20). A list where each row invented its
/// own pitch colour and marker size would defeat the point of a thumbnail,
/// which is that the eye can skip down it without reading.
class DrillThumbnail extends StatelessWidget {
  final Drill drill;
  final double size;

  const DrillThumbnail({super.key, required this.drill, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(T.rSm),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ThumbPainter(_positions(drill), drill.offSurface),
        ),
      ),
    );
  }

  /// What stands on the board, by what it IS.
  ///
  /// Everything used to come back as one blue dot — the cones, the ball and
  /// the coach along with the players — so a thumbnail of eight things was a
  /// blue smudge and every drill looked like every other drill. The point of
  /// a thumbnail is that the eye can tell two of them apart without reading.
  ///
  /// The canvas size is read from the payload rather than assumed: `board`
  /// carries canvasWidth/canvasHeight, and a hardcoded 1000x1500 would
  /// silently misplace every dot the day that changes.
  static List<_Dot> _positions(Drill drill) {
    final board = drill.board;
    final w = (board['canvasWidth'] as num?)?.toDouble() ?? 1000.0;
    final h = (board['canvasHeight'] as num?)?.toDouble() ?? 1500.0;
    final out = <_Dot>[];
    final players = board['players'];
    if (players is! List || w <= 0 || h <= 0) return out;
    for (final raw in players) {
      if (raw is! Map) continue;
      final pos = raw['position'];
      if (pos is! List || pos.length < 2) continue;
      final x = (pos[0] as num?)?.toDouble();
      final y = (pos[1] as num?)?.toDouble();
      if (x == null || y == null) continue;
      // PlayerTeam is serialised as its index: 0 home, 1 away, 2 the
      // equipment that is not a person at all. markerShape 0 among those is
      // the ball; anything else is a cone, a ladder, a hurdle.
      final team = raw['team'];
      final shape = raw['markerShape'];
      final _Kind kind;
      if (team == 0) {
        kind = _Kind.home;
      } else if (team == 1) {
        kind = _Kind.away;
      } else if (shape == 0) {
        kind = _Kind.ball;
      } else {
        kind = _Kind.gear;
      }
      out.add(_Dot(x / w, y / h, kind));
    }
    return out;
  }
}

enum _Kind { home, away, ball, gear }

class _Dot {
  final double x;
  final double y;
  final _Kind kind;
  const _Dot(this.x, this.y, this.kind);
}

class _ThumbPainter extends CustomPainter {
  final List<_Dot> dots;

  /// A drill run off the pitch — a gym circuit, a classroom walk-through —
  /// gets the neutral ground rather than turf it never touches.
  final bool offSurface;

  const _ThumbPainter(this.dots, this.offSurface);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..color = offSurface ? T.surfaceHi : T.turf);

    if (!offSurface) {
      // An outline, a halfway line and a centre spot. Enough for the eye to
      // read "pitch" at 64pt; a full set of markings at this size is noise
      // that the players then have to compete with.
      final line = Paint()
        ..color = T.turfLine.withValues(alpha: 0.30)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawRect(r.deflate(size.shortestSide * 0.10), line);
      canvas.drawLine(Offset(size.width * 0.10, size.height / 2),
          Offset(size.width * 0.90, size.height / 2), line);
      canvas.drawCircle(size.center(Offset.zero), size.shortestSide * 0.11, line);
    }

    // Smaller than they were, and drawn back to front so a player is never
    // hidden under a cone: gear first, then people, then the ball.
    final unit = size.shortestSide;
    for (final kind in _Kind.values) {
      for (final d in dots.where((d) => d.kind == kind)) {
        final at = Offset(d.x * size.width, d.y * size.height);
        switch (kind) {
          case _Kind.gear:
            // A cone is a small triangle: at this size a round cone and a
            // round player are the same mark.
            final s = unit * 0.045;
            canvas.drawPath(
              Path()
                ..moveTo(at.dx, at.dy - s)
                ..lineTo(at.dx + s, at.dy + s)
                ..lineTo(at.dx - s, at.dy + s)
                ..close(),
              Paint()..color = const Color(0xFFE0703A),
            );
          case _Kind.home:
          case _Kind.away:
            canvas.drawCircle(at, unit * 0.055,
                Paint()..color = kind == _Kind.home ? T.home : T.away);
          case _Kind.ball:
            canvas.drawCircle(at, unit * 0.038, Paint()..color = Colors.white);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.dots.length != dots.length || old.offSurface != offSurface;
}
