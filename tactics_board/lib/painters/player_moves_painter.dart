import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/player_icon.dart';
import '../widgets/player_icon_widget.dart';

/// Whether every leg of this ball's route rides along with somebody.
///
/// A pass-and-follow drill gives the ball and the runner the same route one
/// beat apart at most, and drawing both meant every edge of the diamond
/// carried two parallel dashed arrows plus the ball's own waypoint badges.
/// When each of the ball's segments starts and ends within an arm's reach of
/// some player's segment in the same phase, the players' arrows already tell
/// the whole story and the ball's are only noise — its line and its waypoint
/// dots are both suppressed. A ball that ever travels alone (a switch, a
/// shot, a cross to space) keeps them, because there they ARE the story.
bool ballTravelsWithPlayers(PlayerIcon ball, List<PlayerIcon> players) {
  // At the receiver's feet the ball sits ~38pt from the receiver's point;
  // one and a half icons covers that with room, while the next cone is
  // hundreds of points away.
  const near = kPlayerIconSize * 1.5;
  if (ball.moves.isEmpty) return false;
  ball.syncPhases();
  for (int i = 0; i < ball.moves.length; i++) {
    final from = i == 0 ? ball.position : ball.moves[i - 1];
    final to = ball.moves[i];
    final ph = i < ball.movePhases.length ? ball.movePhases[i] : i;
    var escorted = false;
    for (final p in players) {
      if (p.isBall || p.isMarker || p.moves.isEmpty) continue;
      p.syncPhases();
      for (int j = 0; j < p.moves.length; j++) {
        final pph = j < p.movePhases.length ? p.movePhases[j] : j;
        if (pph != ph) continue;
        final pFrom = j == 0 ? p.position : p.moves[j - 1];
        final pTo = p.moves[j];
        if ((pFrom - from).distance < near && (pTo - to).distance < near) {
          escorted = true;
          break;
        }
      }
      if (escorted) break;
    }
    if (!escorted) return false;
  }
  return true;
}

class PlayerMovesPainter extends CustomPainter {
  final List<PlayerIcon> players;
  final int targetStep; // 0 = all; used when not animating
  final int? completedSteps; // non-null during animation: show only this many segments

  const PlayerMovesPainter({
    required this.players,
    this.targetStep = 0,
    this.completedSteps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final player in players) {
      if (player.moves.isEmpty) continue;
      if (player.isBall && ballTravelsWithPlayers(player, players)) continue;
      _paintMoves(canvas, player);
    }
  }

  static const _strokeWidth = 2.8;
  static const _arrowSize = 13.0;
  static const _waypointRadius = 17.0; // half of 28.0 dot + shadow margin

  void _paintMoves(Canvas canvas, PlayerIcon player) {
    final color = player.moveColor;
    player.syncPhases();

    // phaseLimit is the number of beats elapsed (atStep). Show only the
    // segments whose phase value is strictly less than phaseLimit so that
    // empty beats in the middle of the timeline don't reveal later arrows
    // ahead of their actual phase.
    final int phaseLimit = completedSteps ?? targetStep;
    final List<Offset> allMoves;
    if (phaseLimit > 0) {
      int visibleCount = 0;
      for (int i = 0; i < player.moves.length; i++) {
        final ph = i < player.movePhases.length ? player.movePhases[i] : i;
        if (ph < phaseLimit) {
          visibleCount = i + 1;
        }
      }
      allMoves = player.moves.take(visibleCount).toList();
    } else {
      allMoves = player.moves;
    }
    if (allMoves.isEmpty) return;
    final points = [player.position, ...allMoves];
    // bbox half + shadow/border margin — keep arrow clear of the icon's drop shadow
    final iconRadius = kPlayerIconSize / 2 * player.scale + 3;

    for (int i = 0; i < points.length - 1; i++) {
      final from = points[i];
      final to = points[i + 1];
      // Offset both ends: start from source edge, end at destination edge
      final startRadius = i == 0 ? iconRadius : _waypointRadius;
      final isLastSegment = i == points.length - 2;
      final endRadius = isLastSegment ? iconRadius : _waypointRadius;
      final adjustedFrom = _offsetToward(from, to, startRadius);
      final adjustedTo = _offsetToward(to, from, endRadius);
      _drawDashedLine(canvas, color, adjustedFrom, adjustedTo);
      _drawArrowHead(canvas, color, adjustedFrom, adjustedTo);
    }

  }

  void _drawStartMarker(Canvas canvas, Color color, Offset center) {
    const r = 7.0;
    // Dark outline
    canvas.drawCircle(
      center,
      r + 2,
      Paint()..color = const Color(0x47000000),
    );
    // Filled circle
    canvas.drawCircle(center, r, Paint()..color = color);
    // White border
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  static Offset _offsetToward(Offset from, Offset to, double radius) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist <= radius) return from;
    return Offset(from.dx + dx / dist * radius, from.dy + dy / dist * radius);
  }

  void _drawDashedLine(Canvas canvas, Color color, Offset from, Offset to) {
    // A darker edge, not a shadow. Every path used to carry a black halo
    // at 50%, which on a deeper pitch reads as a second thicker line beside
    // the first; 28% is enough to hold the arrow against grass and white
    // pitch markings both.
    final outlinePaint = Paint()
      ..color = const Color(0x47000000)
      ..strokeWidth = _strokeWidth + 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Gradient tail: faded at the source, full color near the destination —
    // gives a sense of direction/recency without changing the dashed style.
    final linePaint = Paint()
      ..shader = ui.Gradient.linear(
        from,
        to,
        [color.withValues(alpha: 0.30), color],
      )
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);

    for (final paint in [outlinePaint, linePaint]) {
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        double start = 0;
        bool draw = true;
        const dashLen = 12.0;
        const gapLen = 7.0;
        while (start < metric.length) {
          final seg = draw ? dashLen : gapLen;
          final end = (start + seg).clamp(0.0, metric.length);
          if (draw) canvas.drawPath(metric.extractPath(start, end), paint);
          start = end;
          draw = !draw;
        }
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Color color, Offset from, Offset to) {
    final angle = atan2(to.dy - from.dy, to.dx - from.dx);

    final outlinePath = _arrowPath(to, angle, _arrowSize + 3);
    canvas.drawPath(
      outlinePath,
      Paint()
        ..color = const Color(0x47000000)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      _arrowPath(to, angle, _arrowSize),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  Path _arrowPath(Offset tip, double angle, double size) {
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - size * cos(angle - pi / 4.5),
        tip.dy - size * sin(angle - pi / 4.5),
      )
      ..lineTo(
        tip.dx - size * cos(angle + pi / 4.5),
        tip.dy - size * sin(angle + pi / 4.5),
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant PlayerMovesPainter oldDelegate) =>
      oldDelegate.completedSteps != completedSteps ||
      oldDelegate.targetStep != targetStep ||
      oldDelegate.players != players;
}
