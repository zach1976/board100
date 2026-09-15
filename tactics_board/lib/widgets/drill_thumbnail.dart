import 'package:flutter/material.dart';

import '../models/drill.dart';
import '../models/sport_type.dart';
import '../ui/tokens.dart';
import 'tactics_canvas.dart' show kBoardRefWidth, kBoardRefHeight;

/// A drill, small enough to scan a list of a hundred.
///
/// Deliberately NOT a shrunken [TacticsCanvas]: the canvas is the real board
/// — sprites, animation controllers, gesture recognisers, a repaint boundary
/// — and a hundred of them in a scrolling list is a hundred of all that. This
/// paints the two things that make a drill recognisable at a glance, straight
/// from the same `drill.board` JSON: the surface, and who is standing where
/// on it before anybody has moved.
///
/// It is cropped to the PITCH, not to the canvas. Boards are authored in a
/// 1000x1500 box and the pitch is fitted inside that box at the sport's own
/// proportions, so drawing the whole box rendered a football pitch — 68 by
/// 105 — as a square with dead margins down both sides, and squeezed every
/// player into the middle of it. Cropping to the pitch makes the thumbnail
/// the shape the sport actually is, and gives the players all of it.
class DrillThumbnail extends StatelessWidget {
  final Drill drill;
  final SportType sport;

  /// The long side. The short one follows from the sport's own proportions.
  final double height;

  const DrillThumbnail({
    super.key,
    required this.drill,
    required this.sport,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    // Where the app puts the pitch inside the board, as fractions of the
    // authored canvas. Read from the same fieldRect the board itself uses,
    // so the crop cannot drift from what a coach sees on opening the drill.
    final fr = sport.fieldRect(const Size(kBoardRefWidth, kBoardRefHeight));
    final pitch = Rect.fromLTWH(
      fr.left / kBoardRefWidth,
      fr.top / kBoardRefHeight,
      fr.width / kBoardRefWidth,
      fr.height / kBoardRefHeight,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(T.rSm),
      child: SizedBox(
        width: height * (fr.width / fr.height),
        height: height,
        child: CustomPaint(
          painter: _ThumbPainter(_dots(drill, pitch), drill.offSurface),
        ),
      ),
    );
  }

  /// What stands on the board, by what it IS, in the pitch's own frame.
  ///
  /// Everything used to come back as one blue dot — the cones, the ball and
  /// the coach along with the players — so a thumbnail of eight things was a
  /// blue smudge and every drill looked like every other drill. The point of
  /// a thumbnail is that the eye can tell two of them apart without reading.
  ///
  /// Start positions only. `position` is where a thing stands before the
  /// first beat and `moves` is where it goes afterwards; a still picture of a
  /// drill is its SETUP — what a coach walks out and arranges — not a frame
  /// from the middle of it.
  ///
  /// The canvas size is read from the payload rather than assumed: `board`
  /// carries canvasWidth/canvasHeight, and a hardcoded 1000x1500 would
  /// silently misplace every dot the day that changes.
  static List<_Dot> _dots(Drill drill, Rect pitch) {
    final board = drill.board;
    final w = (board['canvasWidth'] as num?)?.toDouble() ?? 1000.0;
    final h = (board['canvasHeight'] as num?)?.toDouble() ?? 1500.0;
    final out = <_Dot>[];
    final players = board['players'];
    if (players is! List || w <= 0 || h <= 0) return out;
    if (pitch.width <= 0 || pitch.height <= 0) return out;
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

      // Into the pitch's frame. A drill that uses the space outside the
      // touchline — a thrower at a lineout, a keeper behind his goal — lands
      // outside 0..1 and is pinned to the edge rather than dropped: he is
      // part of the shape even when he is off the grass.
      final px = (x / w - pitch.left) / pitch.width;
      final py = (y / h - pitch.top) / pitch.height;
      out.add(_Dot(px.clamp(0.03, 0.97), py.clamp(0.03, 0.97), kind));
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
    canvas.drawRect(Offset.zero & size,
        Paint()..color = offSurface ? T.surfaceHi : T.turf);

    if (!offSurface) {
      // A halfway line and a centre circle, edge to edge. The thumbnail IS
      // the pitch now, so it needs no outline drawn inside itself, and a
      // full set of markings at this size is noise the players would have
      // to compete with.
      final line = Paint()
        ..color = T.turfLine.withValues(alpha: 0.28)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, size.height / 2),
          Offset(size.width, size.height / 2), line);
      canvas.drawCircle(size.center(Offset.zero), size.width * 0.17, line);
    }

    // Back to front, so a player is never hidden under a cone: gear first,
    // then people, then the ball.
    final unit = size.shortestSide;
    for (final kind in _Kind.values) {
      for (final d in dots.where((d) => d.kind == kind)) {
        final at = Offset(d.x * size.width, d.y * size.height);
        switch (kind) {
          case _Kind.gear:
            // A cone is a small triangle: at this size a round cone and a
            // round player are the same mark.
            final s = unit * 0.06;
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
            canvas.drawCircle(at, unit * 0.075,
                Paint()..color = kind == _Kind.home ? T.home : T.away);
          case _Kind.ball:
            canvas.drawCircle(at, unit * 0.05, Paint()..color = Colors.white);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.dots.length != dots.length || old.offSurface != offSurface;
}
