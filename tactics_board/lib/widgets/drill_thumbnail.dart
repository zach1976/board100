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
    this.height = 96,
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

    final aspect = fr.width / fr.height;
    final dots = _dots(drill, pitch);
    final ball = _ballPath(drill, pitch);

    return ClipRRect(
      borderRadius: BorderRadius.circular(T.rSm),
      child: SizedBox(
        width: height * aspect,
        height: height,
        child: CustomPaint(
          painter: _ThumbPainter(
              dots, ball, _window(dots, ball), drill.offSurface),
        ),
      ),
    );
  }

  /// The part of the pitch this drill actually uses.
  ///
  /// Nearly every drill happens in a corner of the pitch or a box in the
  /// middle, so a thumbnail of the whole pitch spent most of itself on empty
  /// grass and left eleven players as eleven specks. This finds what the
  /// drill occupies and frames that instead.
  ///
  /// The window is SQUARE in this space, which is what keeps the picture
  /// undistorted: both axes here run 0..1 across a box that is already the
  /// pitch's proportions, so equal fractions of each are equal fractions of
  /// the frame. And it never zooms past 45% of the pitch — a two-player
  /// drill blown up to fill the thumbnail would say those two were standing
  /// forty metres apart.
  static Rect _window(List<_Dot> dots, List<Offset> ball) {
    final xs = <double>[...dots.map((d) => d.x), ...ball.map((p) => p.dx)];
    final ys = <double>[...dots.map((d) => d.y), ...ball.map((p) => p.dy)];
    if (xs.isEmpty) return const Rect.fromLTWH(0, 0, 1, 1);

    var left = xs.reduce((a, b) => a < b ? a : b);
    var right = xs.reduce((a, b) => a > b ? a : b);
    var top = ys.reduce((a, b) => a < b ? a : b);
    var bottom = ys.reduce((a, b) => a > b ? a : b);

    // Room for the tokens themselves, which are drawn centred on their point
    // and would otherwise be cut in half by the edge.
    const pad = 0.09;
    left -= pad;
    right += pad;
    top -= pad;
    bottom += pad;

    // Square, and never tighter than 45% of the pitch.
    final span = [right - left, bottom - top, 0.45]
        .reduce((a, b) => a > b ? a : b)
        .clamp(0.0, 1.0);
    final w = span;
    final h = span;
    final cx = (left + right) / 2;
    final cy = (top + bottom) / 2;
    var rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);

    // Slide back inside the pitch rather than shrinking: a drill in the
    // corner should be framed on the corner, not zoomed out to re-centre.
    if (rect.width >= 1) {
      rect = Rect.fromLTWH(0, rect.top, 1, rect.height);
    } else if (rect.left < 0) {
      rect = rect.translate(-rect.left, 0);
    } else if (rect.right > 1) {
      rect = rect.translate(1 - rect.right, 0);
    }
    if (rect.height >= 1) {
      rect = Rect.fromLTWH(rect.left, 0, rect.width, 1);
    } else if (rect.top < 0) {
      rect = rect.translate(0, -rect.top);
    } else if (rect.bottom > 1) {
      rect = rect.translate(0, 1 - rect.bottom);
    }
    return rect;
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

/// Where the ball goes, in the pitch's frame.
///
/// Start positions alone say how many people are on the grass and roughly
/// where; they do not say what the drill is FOR. The ball's path does: a
/// rondo is a closed ring, a slalom is a line straight up the pitch, a cross
/// goes out to the touchline and back in. One thin line is the difference
/// between a list of green rectangles and a list you can read.
List<Offset> _ballPath(Drill drill, Rect pitch) {
  final board = drill.board;
  final w = (board['canvasWidth'] as num?)?.toDouble() ?? 1000.0;
  final h = (board['canvasHeight'] as num?)?.toDouble() ?? 1500.0;
  final players = board['players'];
  if (players is! List || w <= 0 || h <= 0) return const [];
  if (pitch.width <= 0 || pitch.height <= 0) return const [];
  for (final raw in players) {
    if (raw is! Map) continue;
    if (raw['team'] != 2 || raw['markerShape'] != 0) continue;
    final out = <Offset>[];
    void add(List<dynamic> pt) {
      final x = (pt[0] as num?)?.toDouble();
      final y = (pt[1] as num?)?.toDouble();
      if (x == null || y == null) return;
      out.add(Offset(
        (((x / w - pitch.left) / pitch.width)).clamp(0.03, 0.97),
        (((y / h - pitch.top) / pitch.height)).clamp(0.03, 0.97),
      ));
    }
    final pos = raw['position'];
    if (pos is List && pos.length >= 2) add(pos);
    for (final mv in (raw['moves'] as List? ?? const [])) {
      if (mv is List && mv.length >= 2) add(mv);
    }
    return out.length >= 2 ? out : const [];
  }
  return const [];
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
  final List<Offset> ball;

  /// The part of the pitch being shown, in pitch fractions.
  final Rect window;

  /// A drill run off the pitch — a gym circuit, a classroom walk-through —
  /// gets the neutral ground rather than turf it never touches.
  final bool offSurface;

  const _ThumbPainter(this.dots, this.ball, this.window, this.offSurface);

  /// A point on the pitch, in the cropped frame.
  Offset _at(double x, double y, Size size) => Offset(
        (x - window.left) / window.width * size.width,
        (y - window.top) / window.height * size.height,
      );

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
      // Drawn in pitch coordinates and then cropped, so a drill framed on
      // one corner still shows the touchline it is played against — the
      // markings are how a coach tells "in the box" from "on halfway" once
      // the frame no longer shows the whole pitch.
      canvas.drawRect(
          Rect.fromPoints(_at(0, 0, size), _at(1, 1, size)), line);
      canvas.drawLine(_at(0, 0.5, size), _at(1, 0.5, size), line);
      canvas.drawCircle(_at(0.5, 0.5, size),
          0.135 / window.width * size.width, line);
    }

    // The ball's route, under everything: it is the shape of the drill, not
    // a thing standing on the grass, and at full contrast it would out-shout
    // the players it is being passed between.
    if (ball.length >= 2) {
      final path = Path()
        ..moveTo(_at(ball.first.dx, ball.first.dy, size).dx,
            _at(ball.first.dx, ball.first.dy, size).dy);
      for (final p in ball.skip(1)) {
        final q = _at(p.dx, p.dy, size);
        path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = size.shortestSide * 0.028
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    // Back to front, so a player is never hidden under a cone: gear first,
    // then people, then the ball.
    final unit = size.shortestSide;
    for (final kind in _Kind.values) {
      for (final d in dots.where((d) => d.kind == kind)) {
        final at = _at(d.x, d.y, size);
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
      old.dots.length != dots.length ||
      old.ball.length != ball.length ||
      old.window != window ||
      old.offSurface != offSurface;
}
