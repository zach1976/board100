import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../config_constants.dart';
import '../ui/tokens.dart';
import 'package:flutter/scheduler.dart';
import '../models/player_icon.dart';
import '../models/sport_type.dart';
import '../painters/ball_painter.dart';
import '../services/photo_library_service.dart';
import 'marker_shape_clipper.dart';

/// How big a player token is drawn, in points, on any board.
///
/// It was 44, which on the 402pt board the phone draws is 12% of a football
/// pitch's width — a token 8.3 m across, seventeen times life size. That is
/// what made half the library's boards look crowded and what the spacing
/// audit spent its time pushing apart. 36 is 10% of the pitch, still leaves
/// the shirt number at 12pt, and gives every diagram a quarter more clear
/// space between players.
///
/// tools/drills/engine.py's SPACING_APART is this number: the generator
/// spaces boards by the size they are drawn at, so the two must move
/// together.
const double kPlayerIconSize = 36.0;

/// How much of its 44pt cell a ball actually fills.
///
/// A player token draws a circle of radius 0.38w — about three quarters of the
/// cell — while a ball filled the whole of it, so the ball came out a third
/// wider than the players around it and read as the biggest thing on the
/// pitch. Top-down, a ball is smaller than the person next to it. The cell
/// itself is unchanged, so the tap target stays 44pt and nothing about
/// positioning moves; only the drawing shrinks. Scale it up per-ball from the
/// edit bar if a drill wants the ball emphasised.
const double kBallDrawFactor = 0.58;

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
        ..color = T.accent.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawOval(bodyRect.inflate(5), glowPaint);
      canvas.drawCircle(headCenter, headRadius + 5, glowPaint);
    }

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
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

  /// Ghost mode — where the player ends up, not where they are.
  ///
  /// This used to be the solid icon plus a dashed ring in the move's colour,
  /// and on a board with six runs it was the loudest thing on the pitch: six
  /// extra tokens, each ringed in a different colour, each casting the same
  /// drop shadow as a real player. A ghost is a destination, so it now reads
  /// as one — the same shape at half strength, one thin white outline, and no
  /// shadow, because nothing is standing there yet. The arrow says which
  /// player it belongs to; the ring no longer has to.
  void _paintGhost(Canvas canvas, double w, double h, Offset headCenter, double headRadius, Rect bodyRect) {
    // Two coats, not one. A single translucent coat lets the turf through,
    // and green under red comes out brown — the away team's ghosts lost their
    // colour entirely. The white base makes the ghost's ground the same
    // whatever pitch it stands on, so red stays red and blue stays blue, just
    // washed out.
    final basePaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final fillPaint = Paint()..color = color.withValues(alpha: 0.6);
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    if (gender == PlayerGender.female) {
      final skirtTop = headCenter.dy + headRadius * 0.6;
      final skirtBottom = h * 0.92;
      final skirtPath = Path()
        ..moveTo(w * 0.5 - w * 0.16, skirtTop)
        ..lineTo(w * 0.5 + w * 0.16, skirtTop)
        ..lineTo(w * 0.5 + w * 0.36, skirtBottom)
        ..lineTo(w * 0.5 - w * 0.36, skirtBottom)
        ..close();
      canvas.drawPath(skirtPath, basePaint);
      canvas.drawPath(skirtPath, fillPaint);
      canvas.drawPath(skirtPath, outlinePaint);
    } else {
      canvas.drawOval(bodyRect, basePaint);
      canvas.drawOval(bodyRect, fillPaint);
      canvas.drawOval(bodyRect, outlinePaint);
    }
    canvas.drawCircle(headCenter, headRadius, basePaint);
    canvas.drawCircle(headCenter, headRadius, fillPaint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);
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
    // A text element is its text. Everything else on the board is a token in
    // a 44pt box with a label inside it; this one is the label, so it sizes
    // to what was typed instead of cropping it to fit a circle. The "T in a
    // circle" MarkerPainter still draws is right where it belongs — as the
    // tool's own icon in the palette.
    if (isTextElement(player)) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        onScaleEnd: onScaleEnd,
        child: TextElementChip(player: player, isSelected: isSelected),
      );
    }
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
          AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            scale: isSelected ? 1.1 : 1.0,
            // Only the shape turns. The name badge below and the number
            // inside the token are drawn in their own layers and stay
            // upright, because an upside-down 7 is not a 7.
            child: Transform.rotate(
              angle: player.rotation,
              child: SizedBox(
                width: size,
                height: size,
                child: (player.isMarker && player.photoId != null)
                    ? ShapedPhotoMarker(player: player, isSelected: isSelected)
                    : player.isMarker
                    ? _MarkerWidget(player: player, isSelected: isSelected)
                    : player.isBall
                    ? Center(
                        child: FractionallySizedBox(
                          widthFactor: kBallDrawFactor,
                          heightFactor: kBallDrawFactor,
                          child: _BallWidget(
                              player: player, isSelected: isSelected),
                        ),
                      )
                    : (player.photoId != null
                        ? PhotoPlayerShape(player: player, isSelected: isSelected)
                        : _PlayerShape(player: player, isSelected: isSelected)),
              ),
            ),
          ),
          if (player.label.isNotEmpty && !player.labelInside) ...[
            // Small gap so the name badge doesn't crowd the avatar's edge.
            SizedBox(height: 3 * player.scale),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: player.color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2)],
              ),
              child: Text(
                player.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12 * player.scale,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
            borderColor: isSelected ? T.accent : Colors.white,
            borderWidth: isSelected ? 3 : 2,
            isSelected: isSelected,
            gender: player.gender,
          ),
          size: Size.infinite,
        ),
        // Turned back by however much the shape was turned: an upside-down
        // 7 is not a 7, and a sideways one is a stroke.
        if (player.labelInside)
          Align(
            alignment: const Alignment(0, 0.35),
            child: Transform.rotate(
              angle: -player.rotation,
              child: Text(
              player.label,
              // Heavier weight + a dark outline (layered shadows) keeps the
              // jersey number crisp from the bench and when projected.
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15 * player.scale,
                height: 1,
                shadows: const [
                  Shadow(color: Colors.black, offset: Offset(0.8, 0.8), blurRadius: 1.5),
                  Shadow(color: Colors.black, offset: Offset(-0.8, -0.8), blurRadius: 1.5),
                  Shadow(color: Colors.black87, blurRadius: 3),
                ],
              ),
            ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo avatar — renders the user-uploaded face photo as a circular avatar,
// keeping the same team-coloured halo / selection ring / number badge
// language as the layered solid marker.
// ─────────────────────────────────────────────────────────────────────────────
class PhotoPlayerShape extends StatefulWidget {
  final PlayerIcon player;
  final bool isSelected;
  /// Render as a "ghost" — same photo, but at lower opacity and with a
  /// dashed white outline instead of the solid selection/halo chrome. Used
  /// to mark a player's *starting* position when motion arrows are shown,
  /// so users still recognise which player it represents.
  final bool isGhost;
  const PhotoPlayerShape({
    super.key,
    required this.player,
    required this.isSelected,
    this.isGhost = false,
  });

  @override
  State<PhotoPlayerShape> createState() => PhotoPlayerShapeState();
}

class PhotoPlayerShapeState extends State<PhotoPlayerShape> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _resolve();
    // Re-resolve whenever the photo library changes — picks up renames
    // after a crop adjustment (overwriteBytes rotates the filename).
    PhotoLibraryService.instance.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    PhotoLibraryService.instance.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) _resolve();
  }

  @override
  void didUpdateWidget(PhotoPlayerShape old) {
    super.didUpdateWidget(old);
    if (old.player.photoId != widget.player.photoId) _resolve();
  }

  Future<void> _resolve() async {
    final id = widget.player.photoId;
    if (id == null) return;
    final all = await PhotoLibraryService.instance.list();
    final photo = all.cast<dynamic>().firstWhere(
      (p) => p?.id == id,
      orElse: () => null,
    );
    if (photo == null) return;
    final p = await PhotoLibraryService.instance.resolvePath(photo);
    if (mounted) setState(() => _path = p);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final isSelected = widget.isSelected;
    final ghost = widget.isGhost;
    // Solid team-coloured ring around the photo: with a face filling the disc
    // the old soft halo alone was not enough to tell home from away apart at a
    // glance, so the team colour is painted as an actual ring (with a thin
    // white outline for contrast against any pitch colour).
    final ringWidth = (3.0 * p.scale).clamp(2.5, 5.0).toDouble();
    final body = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.color,
            border: ghost
                ? null
                : Border.all(
                    color: isSelected ? T.accent : Colors.white,
                    width: isSelected ? 2.4 : 1.5,
                  ),
            boxShadow: ghost
                ? null
                : [
                    if (isSelected)
                      const BoxShadow(
                        color: T.selectRing,
                        blurRadius: 0,
                        spreadRadius: 2,
                      ),
                    // One shadow, not two. Every token used to emit a halo in
                    // its own shirt colour on top of the ground shadow, so a
                    // full team put eleven coloured glows on the turf and the
                    // board read as lit from inside.
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 4,
                      offset: const Offset(1, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.all(ringWidth),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _path == null ? p.color : Colors.black12,
                image: _path != null
                    ? DecorationImage(
                        image: FileImage(File(_path!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          ),
        ),
        // Same one thin outline the drawn tokens use for a ghost — the photo
        // tokens carried their own dashed painter, which made the two kinds of
        // ghost look like two different states.
        if (ghost)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        if (p.labelInside)
          Align(
            alignment: const Alignment(0, 0.85),
            child: Transform.rotate(
              angle: -p.rotation,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: p.color.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white70, width: 0.8),
              ),
              child: Text(
                p.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10 * p.scale,
                  height: 1,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 2),
                  ],
                ),
              ),
            ),
            ),
          ),
      ],
    );
    return ghost ? Opacity(opacity: 0.55, child: body) : body;
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Custom-element marker — user-uploaded photo clipped to a chosen shape
// (square / triangle / diamond). Same visual chrome as PhotoPlayerShape
// (drop shadow + selection glow) but the avatar is a non-circular ClipPath
// so a single photo can stand in for any of the marker outlines.
// ─────────────────────────────────────────────────────────────────────────────
class ShapedPhotoMarker extends StatefulWidget {
  final PlayerIcon player;
  final bool isSelected;
  const ShapedPhotoMarker({
    super.key,
    required this.player,
    required this.isSelected,
  });

  @override
  State<ShapedPhotoMarker> createState() => _ShapedPhotoMarkerState();
}

class _ShapedPhotoMarkerState extends State<ShapedPhotoMarker> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _resolve();
    PhotoLibraryService.instance.addListener(_onLibraryChanged);
  }

  @override
  void dispose() {
    PhotoLibraryService.instance.removeListener(_onLibraryChanged);
    super.dispose();
  }

  void _onLibraryChanged() {
    if (mounted) _resolve();
  }

  @override
  void didUpdateWidget(ShapedPhotoMarker old) {
    super.didUpdateWidget(old);
    if (old.player.photoId != widget.player.photoId) _resolve();
  }

  Future<void> _resolve() async {
    final id = widget.player.photoId;
    if (id == null) return;
    final all = await PhotoLibraryService.instance.list();
    final element = await PhotoLibraryService.instance.listElements();
    final photo = [...all, ...element]
        .cast<dynamic>()
        .firstWhere((p) => p?.id == id, orElse: () => null);
    if (photo == null) return;
    final p = await PhotoLibraryService.instance.resolvePath(photo);
    if (mounted) setState(() => _path = p);
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.player.markerShape;
    final isSel = widget.isSelected;
    // StackFit.expand makes every non-Positioned child fill the parent's
    // SizedBox; without it, ClipPath + Image.file collapses to zero size
    // and the avatar disappears on the board.
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isSel)
          IgnorePointer(
            child: ClipPath(
              clipper: MarkerShapeClipper(shape),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: T.selectRing,
                      blurRadius: 0,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ClipPath(
          clipper: MarkerShapeClipper(shape),
          child: _path != null
              ? Image.file(File(_path!), fit: BoxFit.cover)
              : ColoredBox(
                  color: widget.player.color.withValues(alpha: 0.4),
                ),
        ),
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ShapedMarkerOutlinePainter(
              shape: shape,
              isSelected: isSel,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShapedMarkerOutlinePainter extends CustomPainter {
  final MarkerShape shape;
  final bool isSelected;
  const _ShapedMarkerOutlinePainter({
    required this.shape,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = MarkerShapeClipper(shape);
    final path = clipper.getClip(size);
    final ring = Paint()
      ..color = isSelected ? T.accent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.6 : 1.6;
    canvas.drawPath(path, ring);
  }

  @override
  bool shouldRepaint(_ShapedMarkerOutlinePainter old) =>
      old.shape != shape || old.isSelected != isSelected;
}

// ─────────────────────────────────────────────────────────────────────────────
// Marker shapes — circle, square, triangle, diamond
// ─────────────────────────────────────────────────────────────────────────────
/// The shipped artwork for a marker, when there is any.
///
/// Five of the markers are real objects a coach puts on the grass, and the
/// code drawings of them were geometry standing in for a photograph: the cone
/// was a side-on triangle among top-down tokens, the ladder a bordered
/// rectangle, the hurdle four thin lines that vanished against turf. Those
/// five ship as sprites. Everything else stays drawn, and deliberately: the
/// flat spot markers take their colour from the coach — marking four zones in
/// four colours is the whole point of them — and an image cannot be recoloured.
/// packageAsset, not a hardcoded packages/ prefix: the same path has to
/// resolve both in the hub, where these assets are local, and in the fifteen
/// sport shells, where tactics_board is a dependency.
String? markerImageAsset(MarkerShape shape) => switch (shape) {
      MarkerShape.cone => packageAsset('assets/icon/marker_cone.png'),
      MarkerShape.ladder => packageAsset('assets/icon/marker_ladder.png'),
      MarkerShape.hurdle => packageAsset('assets/icon/marker_hurdle.png'),
      MarkerShape.referee => packageAsset('assets/icon/marker_referee.png'),
      MarkerShape.coach => packageAsset('assets/icon/marker_coach.png'),
      _ => null,
    };

/// How big a marker's sprite is drawn against a player token.
///
/// Every marker was painted into the same 36pt box as a player, so a cone
/// stood as tall as the man running round it and an agility ladder — four
/// and a half metres of webbing — came out shorter than his shoulders. The
/// board is symbolic and none of it is to scale, but the objects have to
/// stay in proportion to each other and to a body: a cone is something you
/// step round, a hurdle something you clear, a ladder something you run the
/// length of. The referee and the coach are people and stay a person's size.
///
/// The box itself does not change — it is what the icon is positioned and
/// grabbed by, and a ladder is still grabbed by its middle.
double markerArtScale(MarkerShape shape) => switch (shape) {
      MarkerShape.cone => 0.62,
      MarkerShape.hurdle => 0.82,
      MarkerShape.ladder => 2.3,
      _ => 1.0,
    };

class _MarkerWidget extends StatelessWidget {
  final PlayerIcon player;
  final bool isSelected;
  const _MarkerWidget({required this.player, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final art = markerImageAsset(player.markerShape);
    final body = Stack(
      children: [
        if (art != null)
          // The sprite carries its own contact shadow, so the painter's is
          // not wanted here; the selection ring is drawn over the top instead
          // of around a shape the image no longer matches.
          Positioned.fill(
            child: Image.asset(art,
                fit: BoxFit.contain, filterQuality: FilterQuality.medium),
          )
        else
          CustomPaint(
            painter: MarkerPainter(
              shape: player.markerShape,
              color: player.color,
              isSelected: isSelected,
            ),
            size: Size.infinite,
          ),
        if (art != null && isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: T.accent, width: 2.5),
                ),
              ),
            ),
          ),
        if (player.labelInside)
          Align(
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: -player.rotation,
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
          ),
      ],
    );
    // Drawn bigger or smaller than its box, about the same centre: the box
    // stays a token, so the marker sits on its point and is grabbed where
    // it always was.
    final scale = markerArtScale(player.markerShape);
    return scale == 1.0 ? body : Transform.scale(scale: scale, child: body);
  }
}

/// A text element: a marker whose whole job is the words on it.
bool isTextElement(PlayerIcon p) =>
    p.markerShape == MarkerShape.text && p.photoId == null;

/// How wide a text element is allowed to get before it wraps. Wide enough
/// for a short coaching phrase, narrow enough that three of them on a pitch
/// do not overlap each other by default.
const double kTextElementMaxWidth = 150.0;

/// As much as three wrapped lines of the chip hold. The other elements cap
/// at 12 because they are a name under a token; this one IS the sentence.
const int kTextElementMaxChars = 40;

/// The words, on a chip sized to them.
class TextElementChip extends StatelessWidget {
  final PlayerIcon player;
  final bool isSelected;
  const TextElementChip(
      {super.key, required this.player, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final scale = player.scale;
    // An empty one would be an invisible thing you cannot tap again, so it
    // keeps the tool's own glyph until something is typed into it.
    final empty = player.label.trim().isEmpty;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: kTextElementMaxWidth * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 8 * scale, vertical: 4.5 * scale),
        decoration: BoxDecoration(
          color: player.color.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(6 * scale),
          border: isSelected
              ? Border.all(color: T.accent, width: 2)
              : Border.all(color: Colors.white24, width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
        child: Text(
          empty ? 'T' : player.label,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13 * scale,
            height: 1.25,
            fontWeight: FontWeight.w600,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
      ),
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
        ..color = T.accent.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(cx, cy), r + 5, glow);
    }

    // Shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx + 1, cy + 2), r, shadow);

    final fill = Paint()..color = color;
    final border = Paint()
      ..color = isSelected ? T.accent : Colors.white
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
          text: TextSpan(text: 'R', style: TextStyle(color: T.accent, fontSize: r * 1.1, fontWeight: FontWeight.bold)),
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
      // Created idle: a ticker that runs while the shuttle is standing still
      // burns a frame per vsync for nothing — and keeps pumpAndSettle (and
      // the drive walk built on it) from ever settling on a badminton board.
      _ticker = createTicker(_onTick);
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
    _lastElapsed = elapsed;
    if (_velocity.abs() < _minVelocity) {
      _velocity = 0;
      _ticker?.stop();
      return;
    }
    setState(() {
      _angle += _velocity * dt;
      _velocity *= pow(_friction, dt * 60).toDouble();
    });
  }

  void flick(double dxPixels) {
    _velocity += dxPixels * 0.25;
    if (!(_ticker?.isActive ?? true)) {
      // start() counts elapsed from zero again, so the dt baseline must too.
      _lastElapsed = Duration.zero;
      _ticker?.start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ball = ClipOval(
      child: ballWidget(widget.player.sportType!),
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
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
              // A ring, not a glow (§09): a halo on a green pitch bleeds
              // into the grass and reads as a smudge at arm's length.
              if (widget.isSelected)
                const BoxShadow(
                  color: T.selectRing,
                  blurRadius: 0,
                  spreadRadius: 2,
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
