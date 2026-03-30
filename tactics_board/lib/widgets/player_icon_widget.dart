import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/player_icon.dart';
import '../models/sport_type.dart';
import '../painters/ball_painter.dart';

const double kPlayerIconSize = 44.0;

// ─────────────────────────────────────────────────────────────────────────────
// Top-down person painter (shared between board and toolbar preview)
// ─────────────────────────────────────────────────────────────────────────────
class TopDownPlayerPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool isSelected;
  final PlayerGender gender;

  const TopDownPlayerPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    this.isSelected = false,
    this.gender = PlayerGender.unspecified,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final headCenter = Offset(w * 0.5, h * 0.28);
    final headRadius = w * 0.2;
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.65),
      width: w * 0.55,
      height: h * 0.45,
    );

    // Selection glow
    if (isSelected) {
      final glowPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawOval(bodyRect.inflate(5), glowPaint);
      canvas.drawCircle(headCenter, headRadius + 5, glowPaint);
    }

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    const shadowOffset = Offset(2, 2);
    canvas.drawOval(bodyRect.shift(shadowOffset), shadowPaint);
    canvas.drawCircle(headCenter + shadowOffset, headRadius, shadowPaint);

    final fillPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (gender == PlayerGender.female) {
      // Skirt body — trapezoid wider at bottom (top-down view)
      final skirtTop = headCenter.dy + headRadius * 0.6;
      final skirtBottom = h * 0.92;
      final skirtPath = Path()
        ..moveTo(w * 0.5 - w * 0.16, skirtTop)
        ..lineTo(w * 0.5 + w * 0.16, skirtTop)
        ..lineTo(w * 0.5 + w * 0.36, skirtBottom)
        ..lineTo(w * 0.5 - w * 0.36, skirtBottom)
        ..close();
      canvas.drawPath(skirtPath, fillPaint);
      canvas.drawPath(skirtPath, borderPaint);
    } else {
      // Male body — oval
      canvas.drawOval(bodyRect, fillPaint);
      canvas.drawOval(bodyRect, borderPaint);
    }

    // Head
    canvas.drawCircle(headCenter, headRadius, fillPaint);
    canvas.drawCircle(headCenter, headRadius, borderPaint);
  }

  @override
  bool shouldRepaint(TopDownPlayerPainter old) =>
      old.color != color ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.isSelected != isSelected ||
      old.gender != gender;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main player icon widget
// ─────────────────────────────────────────────────────────────────────────────
class PlayerIconWidget extends StatelessWidget {
  final PlayerIcon player;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(ScaleStartDetails)? onScaleStart;
  final Function(ScaleUpdateDetails)? onScaleUpdate;
  final Function(ScaleEndDetails)? onScaleEnd;

  const PlayerIconWidget({
    super.key,
    required this.player,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  });

  @override
  Widget build(BuildContext context) {
    final size = kPlayerIconSize * player.scale;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      child: SizedBox(
        width: size,
        height: size,
        child: player.isBall
            ? _BallWidget(player: player, isSelected: isSelected)
            : _PlayerShape(player: player, isSelected: isSelected),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-down person shape with number label
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerShape extends StatelessWidget {
  final PlayerIcon player;
  final bool isSelected;
  const _PlayerShape({required this.player, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: TopDownPlayerPainter(
            color: player.color,
            borderColor: isSelected ? Colors.yellow : Colors.white,
            borderWidth: isSelected ? 3 : 2,
            isSelected: isSelected,
            gender: player.gender,
          ),
          size: Size.infinite,
        ),
        if (player.label.isNotEmpty)
          Align(
            alignment: const Alignment(0, 0.35),
            child: Text(
              player.label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13 * player.scale,
                height: 1,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ball widget — shuttlecock supports physics-based manual spin
// ─────────────────────────────────────────────────────────────────────────────
class _BallWidget extends StatefulWidget {
  final PlayerIcon player;
  final bool isSelected;
  const _BallWidget({required this.player, required this.isSelected});

  @override
  State<_BallWidget> createState() => _BallWidgetState();
}

class _BallWidgetState extends State<_BallWidget>
    with SingleTickerProviderStateMixin {
  double _angle = 0;
  double _velocity = 0;
  static const double _friction = 0.88;
  static const double _minVelocity = 0.01;

  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  bool get _isShuttlecock =>
      widget.player.sportType == SportType.badminton;

  @override
  void initState() {
    super.initState();
    if (_isShuttlecock) {
      _ticker = createTicker(_onTick)..start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
    _lastElapsed = elapsed;
    if (_velocity.abs() < _minVelocity) {
      _velocity = 0;
      return;
    }
    setState(() {
      _angle += _velocity * dt;
      _velocity *= pow(_friction, dt * 60).toDouble();
    });
  }

  void flick(double dxPixels) {
    _velocity += dxPixels * 0.25;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ball = ClipOval(
      child: CustomPaint(
        painter: BallPainter.forSport(widget.player.sportType!),
      ),
    );

    final inner = _isShuttlecock
        ? Transform.rotate(angle: _angle, child: ball)
        : ball;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
          if (widget.isSelected)
            BoxShadow(
              color: Colors.yellow.withValues(alpha: 0.7),
              blurRadius: 12,
              spreadRadius: 3,
            ),
        ],
      ),
      child: _isShuttlecock
          ? GestureDetector(
              onHorizontalDragUpdate: (d) => flick(d.delta.dx),
              onHorizontalDragEnd: (d) {
                _velocity += d.velocity.pixelsPerSecond.dx * 0.003;
              },
              child: inner,
            )
          : inner,
    );
  }
}
