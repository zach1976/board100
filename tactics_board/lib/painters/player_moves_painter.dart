import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player_icon.dart';

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

  static const _strokeWidth = 1.8;
  static const _arrowSize = 10.0;

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

    const startInset = 20.0; // shorten start to clear player icon
    const endInset = 14.0; // shorten end to expose arrow
    for (int i = 0; i < points.length - 1; i++) {
      final from = points[i];
      final to = points[i + 1];
      final dir = to - from;
      final dist = dir.distance;
      if (dist < startInset + endInset + 5) {
        // Too short — just draw arrow
        _drawArrowHead(canvas, color, from, to);
        continue;
      }
      final unit = dir / dist;
      final shortenedFrom = from + unit * startInset;
      final shortenedTo = to - unit * endInset;
      _drawDashedLine(canvas, color, shortenedFrom, shortenedTo);
      _drawArrowHead(canvas, color, shortenedFrom, shortenedTo);
    }

    // Draw start marker at player's origin
    _drawStartMarker(canvas, color, player.position);
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
