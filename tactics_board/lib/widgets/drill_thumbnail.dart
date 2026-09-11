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

  /// Player positions as fractions of the board's own canvas, with their
  /// team. The canvas size is read from the payload rather than assumed:
  /// `board` carries canvasWidth/canvasHeight, and a hardcoded 1000×1500
  /// would silently misplace every dot the day that changes.
  ///
  /// Anything the JSON does not carry is skipped rather than guessed — a
  /// thumbnail with one dot missing is fine; one with a dot in the wrong
  /// place is a lie about the drill.
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
      // PlayerTeam is serialised as its index: 0 home, 1 away. Anything else
      // (a coach, a cone) is drawn as home rather than dropped — it is still
      // something standing on the pitch.
      out.add(_Dot(x / w, y / h, raw['team'] == 1));
    }
    return out;
  }
}

class _Dot {
  final double x;
  final double y;
  final bool away;
  const _Dot(this.x, this.y, this.away);
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
    canvas.drawRect(
        r, Paint()..color = offSurface ? T.surfaceHi : T.turf);

    if (!offSurface) {
      // Two lines only — a halfway line and a centre spot. At 64pt a full set
      // of markings is noise, but without any the square is just green.
      final line = Paint()
        ..color = T.turfLine.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(0, size.height / 2),
          Offset(size.width, size.height / 2), line);
      canvas.drawCircle(
          size.center(Offset.zero), size.shortestSide * 0.13, line..style = PaintingStyle.stroke);
    }

    final radius = size.shortestSide * 0.075;
    for (final d in dots) {
      canvas.drawCircle(
        Offset(d.x * size.width, d.y * size.height),
        radius,
        Paint()..color = d.away ? T.away : T.home,
      );
    }
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.dots.length != dots.length || old.offSurface != offSurface;
}
