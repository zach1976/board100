import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player_icon.dart';
import '../widgets/player_icon_widget.dart';

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
      _paintMoves(canvas, player);
    }
  }

  static const _strokeWidth = 2.8;
  static const _arrowSize = 13.0;
  static const _waypointRadius = 17.0; // half of 28.0 dot + shadow margin

  List<int> _getSortedPhases() {
    final phases = <int>{};
    for (final p in players) {
      p.syncPhases();
      phases.addAll(p.movePhases);
    }
    return phases.toList()..sort();
  }

  void _paintMoves(Canvas canvas, PlayerIcon player) {
    final color = player.moveColor;
    player.syncPhases();

    // Determine how many of this player's moves to show based on completed phases
    final int phaseLimit = completedSteps ?? targetStep;
    final List<Offset> allMoves;
    if (phaseLimit > 0) {
      // Only show moves whose phase index is < phaseLimit
      // Get sorted distinct phases across ALL moves in the painting context
      final sortedPhases = _getSortedPhases();
      int visibleCount = 0;
      for (int i = 0; i < player.moves.length; i++) {
        final ph = i < player.movePhases.length ? player.movePhases[i] : i;
        final phaseOrderIdx = sortedPhases.indexOf(ph);
        if (phaseOrderIdx >= 0 && phaseOrderIdx < phaseLimit) {
          visibleCount = i + 1; // include this move
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
      Paint()..color = Colors.black.withValues(alpha: 0.5),
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
    // Dark outline for contrast
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..strokeWidth = _strokeWidth + 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = color
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
        ..color = Colors.black.withValues(alpha: 0.5)
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
