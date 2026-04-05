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
  final bool isGhost;

  const TopDownPlayerPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    this.isSelected = false,
    this.gender = PlayerGender.unspecified,
    this.isGhost = false,
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

    if (isGhost) {
      _paintGhost(canvas, w, h, headCenter, headRadius, bodyRect);
      return;
    }

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

  /// Ghost mode — dashed outline, no fill, reduced opacity
  void _paintGhost(Canvas canvas, double w, double h, Offset headCenter, double headRadius, Rect bodyRect) {
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (gender == PlayerGender.female) {
      final skirtTop = headCenter.dy + headRadius * 0.6;
      final skirtBottom = h * 0.92;
      final skirtPath = Path()
        ..moveTo(w * 0.5 - w * 0.16, skirtTop)
        ..lineTo(w * 0.5 + w * 0.16, skirtTop)
        ..lineTo(w * 0.5 + w * 0.36, skirtBottom)
        ..lineTo(w * 0.5 - w * 0.36, skirtBottom)
        ..close();
      _drawDashedPath(canvas, skirtPath, dashPaint);
    } else {
      _drawDashedOval(canvas, bodyRect, dashPaint);
    }
    _drawDashedCircle(canvas, headCenter, headRadius, dashPaint);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashLen = 4.0;
    const gapLen = 3.0;
    final circumference = 2 * pi * radius;
    final steps = (circumference / (dashLen + gapLen)).floor();
    for (int i = 0; i < steps; i++) {
      final startAngle = (i * (dashLen + gapLen)) / radius;
      final sweepAngle = dashLen / radius;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
    }
  }

  void _drawDashedOval(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()..addOval(rect);
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLen = 4.0;
    const gapLen = 3.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLen).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(TopDownPlayerPainter old) =>
      old.color != color ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.isSelected != isSelected ||
      old.gender != gender ||
      old.isGhost != isGhost;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: player.isMarker
                ? _MarkerWidget(player: player, isSelected: isSelected)
                : player.isBall
                ? _BallWidget(player: player, isSelected: isSelected)
                : _PlayerShape(player: player, isSelected: isSelected),
          ),
          if (player.label.length > 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: player.color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2)],
              ),
              child: Text(
                player.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10 * player.scale,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
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
        if (player.label.isNotEmpty && player.label.length <= 2)
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
// Marker shapes — circle, square, triangle, diamond
// ─────────────────────────────────────────────────────────────────────────────
class _MarkerWidget extends StatelessWidget {
  final PlayerIcon player;
  final bool isSelected;
  const _MarkerWidget({required this.player, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: MarkerPainter(
            shape: player.markerShape,
            color: player.color,
            isSelected: isSelected,
          ),
          size: Size.infinite,
        ),
        if (player.label.isNotEmpty && player.label.length <= 2)
          Align(
            alignment: Alignment.center,
            child: Text(
              player.label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12 * player.scale,
                height: 1,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 2)],
              ),
            ),
          ),
      ],
    );
  }
}

class MarkerPainter extends CustomPainter {
  final MarkerShape shape;
  final Color color;
  final bool isSelected;

  const MarkerPainter({required this.shape, required this.color, this.isSelected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w * 0.38;

    if (isSelected) {
      final glow = Paint()
        ..color = Colors.yellow.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(cx, cy), r + 5, glow);
    }

    // Shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx + 2, cy + 2), r, shadow);

    final fill = Paint()..color = color;
    final border = Paint()
      ..color = isSelected ? Colors.yellow : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 2;

    switch (shape) {
      case MarkerShape.circle:
        canvas.drawCircle(Offset(cx, cy), r, fill);
        canvas.drawCircle(Offset(cx, cy), r, border);
      case MarkerShape.square:
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.7, height: r * 1.7);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), border);
      case MarkerShape.triangle:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.95, cy + r * 0.7)
          ..lineTo(cx - r * 0.95, cy + r * 0.7)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, border);
      case MarkerShape.diamond:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.85, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.85, cy)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, border);
      case MarkerShape.cone:
        // Traffic cone shape
        final path = Path()
          ..moveTo(cx, cy - r * 0.9)
          ..lineTo(cx + r * 0.7, cy + r * 0.7)
          ..lineTo(cx - r * 0.7, cy + r * 0.7)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, border);
        // Stripe
        final stripe = Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 2..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(cx - r * 0.35, cy + r * 0.1), Offset(cx + r * 0.35, cy + r * 0.1), stripe);
      case MarkerShape.text:
        // "T" text marker
        canvas.drawCircle(Offset(cx, cy), r, fill);
        canvas.drawCircle(Offset(cx, cy), r, border);
        final tp = TextPainter(
          text: TextSpan(text: 'T', style: TextStyle(color: Colors.white, fontSize: r * 1.2, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      case MarkerShape.zone:
        // Dashed rectangle zone
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.6);
        final zoneFill = Paint()..color = color.withValues(alpha: 0.3);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), zoneFill);
        final zoneBorder = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2;
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), zoneBorder);
      case MarkerShape.referee:
        // Referee whistle icon — circle with "R"
        canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.black87);
        canvas.drawCircle(Offset(cx, cy), r, border);
        final tp = TextPainter(
          text: TextSpan(text: 'R', style: TextStyle(color: Colors.yellow, fontSize: r * 1.1, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      case MarkerShape.coach:
        // Coach — circle with "C"
        canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFF37474F));
        canvas.drawCircle(Offset(cx, cy), r, border);
        final tp = TextPainter(
          text: TextSpan(text: 'C', style: TextStyle(color: Colors.white, fontSize: r * 1.1, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      case MarkerShape.ladder:
        // Agility ladder — horizontal bars
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.2, height: r * 2);
        canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.2));
        canvas.drawRect(rect, border);
        for (int i = 1; i < 4; i++) {
          final y = rect.top + rect.height * i / 4;
          canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), border);
        }
      case MarkerShape.hurdle:
        // Hurdle — T shape
        final base = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - r * 0.7, cy + r * 0.5), Offset(cx + r * 0.7, cy + r * 0.5), base); // bar
        canvas.drawLine(Offset(cx - r * 0.5, cy + r * 0.5), Offset(cx - r * 0.5, cy - r * 0.4), base); // left leg
        canvas.drawLine(Offset(cx + r * 0.5, cy + r * 0.5), Offset(cx + r * 0.5, cy - r * 0.4), base); // right leg
        canvas.drawLine(Offset(cx - r * 0.7, cy - r * 0.4), Offset(cx + r * 0.7, cy - r * 0.4), Paint()..color = color..strokeWidth = 4..strokeCap = StrokeCap.round); // top bar
      case MarkerShape.arrowMark:
        // Arrow direction marker
        canvas.drawCircle(Offset(cx, cy), r, fill);
        canvas.drawCircle(Offset(cx, cy), r, border);
        final arrowPaint = Paint()..color = Colors.white..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - r * 0.4, cy), Offset(cx + r * 0.4, cy), arrowPaint);
        canvas.drawLine(Offset(cx + r * 0.1, cy - r * 0.35), Offset(cx + r * 0.4, cy), arrowPaint);
        canvas.drawLine(Offset(cx + r * 0.1, cy + r * 0.35), Offset(cx + r * 0.4, cy), arrowPaint);
      case MarkerShape.none:
        break;
    }
  }

  @override
  bool shouldRepaint(MarkerPainter old) =>
      old.shape != shape || old.color != color || old.isSelected != isSelected;
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

    return Stack(
      children: [
        Container(
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
        ),
        if (widget.player.label.isNotEmpty)
          Align(
            alignment: Alignment.center,
            child: Text(
              widget.player.label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11 * widget.player.scale,
                height: 1,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
              ),
            ),
          ),
      ],
    );
  }
}
