import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player_icon.dart';

class PlayerMovesPainter extends CustomPainter {
  final List<PlayerIcon> players;
  final int targetStep; // 0 = all

  const PlayerMovesPainter({required this.players, this.targetStep = 0});

  @override
  void paint(Canvas canvas, Size size) {
    for (final player in players) {
      if (player.moves.isEmpty) continue;
      _paintMoves(canvas, player);
    }
  }

  static const _strokeWidth = 3.5;
  static const _arrowSize = 14.0;

  void _paintMoves(Canvas canvas, PlayerIcon player) {
    final color = player.moveColor;
    final allMoves = targetStep > 0
        ? player.moves.take(targetStep).toList()
        : player.moves;
    final points = [player.position, ...allMoves];

    for (int i = 0; i < points.length - 1; i++) {
      final from = points[i];
      final to = points[i + 1];
      _drawDashedLine(canvas, color, from, to);
      _drawArrowHead(canvas, color, from, to);
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
        tip.dx - size * cos(angle - pi / 6),
        tip.dy - size * sin(angle - pi / 6),
      )
      ..lineTo(
        tip.dx - size * cos(angle + pi / 6),
        tip.dy - size * sin(angle + pi / 6),
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant PlayerMovesPainter oldDelegate) => true;
}
