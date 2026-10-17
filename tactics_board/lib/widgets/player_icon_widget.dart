import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../config_constants.dart';
import '../ui/tokens.dart';
import 'package:flutter/scheduler.dart';
import '../models/player_icon.dart';
import '../models/sport_type.dart';
import '../painters/ball_painter.dart';
import '../services/photo_library_service.dart';
import 'marker_shape_clipper.dart';
import 'tactics_canvas.dart' show chainEndAt, turnVector;

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
///
/// That is the size on a phone. A tablet board is two and a half times
/// the phone's, and at a fixed 36 its players came out a third of the size
/// they are on the phone relative to the pitch they stand on — dots on a
/// 13" screen. So the cell is [kPlayerIconBase] times [kFigureScale], and
/// everything sized off the figure (its hit box, the ball at its feet, the
/// fan-out, its badge, the arrowheads) follows the one factor.
double get kPlayerIconSize => kPlayerIconBase * kFigureScale;

/// The figure's cell on a phone board: 36pt. See [kPlayerIconSize].
const double kPlayerIconBase = 36.0;

/// How much bigger than on a phone the board draws everything that sits
/// ON it — figures, arrows, waypoints — set from the board's on-screen size
/// by [boardFigureScaleFor] (and divided by a view zoom, which magnifies
/// the board itself). 1.0 on every phone board.
double gBoardFigureScale = 1.0;

/// The board's own figure size: 1.0, or the generator's tight figure for a
/// scrum, a wall, a lineout (the board JSON's "figureScale", see
/// tools/drills/engine.py TIGHT_FIGURE_SCALE). Set by TacticsState.
double gTightFigureScale = 1.0;

/// The one factor every figure-derived size is multiplied by.
double get kFigureScale => gBoardFigureScale * gTightFigureScale;

/// The view's zoom onto a drill's half or close-up (TacticsState.frameZoom;
/// 1.0 unzoomed). The transform magnifies everything on the canvas, so the
/// few details a figure draws at a fixed size — its outline, its drop
/// shadow, the shadows on its number — are drawn this much smaller to stay
/// their size on the screen. At a lineout's 5x they were a white blob round
/// every man and every number printed twice.
double gViewZoom = 1.0;

/// The figure growth for a board drawn [board] big on screen.
///
/// Exactly 1 up to a 500pt short side — every phone, upright or sideways,
/// so a phone board is pixel for pixel what it was — then in proportion to
/// the board, capped at 1.6: a 13" iPad's 58pt figure is about the share of
/// the pitch the phone's was at 26pt, room the generator's spacing (made
/// for the phone) still clears with to spare.
///
/// Upright, on a court whose players stand behind its baselines, the figure
/// is also never bigger for its court than on the 402x730 board the drills
/// are written on (tools/drills/engine.py figure_clear): a far server
/// stands half a figure past the far baseline in fractions of the court, so
/// on a shorter court — the phone's own board, under its toolbars — his
/// feet were on the line and his head off the top of the board. Turned
/// sideways the figure stands across the court and has the room.
double boardFigureScaleFor(Size board,
    {SportType? sport, bool sideways = false}) {
  if (board.isEmpty) return 1.0;
  final grown = (board.shortestSide / 500).clamp(1.0, 1.6).toDouble();
  if (sport == null || sideways || !kBehindBaselineSports.contains(sport)) {
    return grown;
  }
  final court = sport.fieldRect(board).height /
      sport.fieldRect(const Size(402, 730)).height;
  return min(grown, court);
}

/// The sports whose drills stand servers and receivers behind a baseline
/// (tools/check_baselines.py), so whose figure keeps its court's share.
const kBehindBaselineSports = {
  SportType.tennis,
  SportType.pickleball,
  SportType.beachTennis,
  SportType.volleyball,
};

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

/// The same fraction, per sport, because the balls are not the same size.
///
/// 0.58 was measured against a football, and a football is 22cm across a
/// 45cm pair of shoulders — half a person wide, which is what it looks like
/// from above. A hockey ball is 7.3cm. Drawn at the football's fraction it
/// came out the size of a player's head, which is the one thing a board
/// showing a drag flick must not do: the eye reads the biggest round thing
/// as the ball, and here it was reading a head.
///
/// Not scaled to life — at true scale a hockey ball would be 0.19 of the
/// cell and vanish — but far enough down that it is plainly the smaller
/// object. The others keep the football's figure until each is looked at.
double ballDrawFactor(SportType sport) => switch (sport) {
      SportType.fieldHockey => 0.40,
      // A 40mm ball at a player's hip, drawn at the football's fraction,
      // was as big as the player's head (audit 2026-10-11 m15). Smaller
      // than the hockey ball, as it is in life, and still plainly a ball.
      SportType.tableTennis => 0.34,
      _ => kBallDrawFactor,
    };

/// The figure a brand-new player of this sport gets: holding, if the sport
/// has something to hold. A coach who wants an empty-handed feeder turns it
/// off on that one player.
///
/// The swimmer holds nothing; every other body — plain, or barefoot on
/// sand — is what an empty-handed player is drawn as, and the implement
/// figure what a holding one is.
PlayerFigure newPlayerFigure(SportType sport) =>
    sport.playerBody == PlayerFigure.water
        ? sport.playerBody
        : (sport.implementHeldByDefault
            ? (sport.playerImplement ?? sport.playerBody)
            : sport.playerBody);

/// Where the shirt number sits on a token.
///
/// The circle-and-oval had its number in the middle of the oval, which on a
/// figure is the shorts. The figurine's head is a quarter of its height, so
/// the shirt sits lower than it did on the realistic one that came before:
/// 0.52 of the figure down, measured off the art, which leaves the face
/// clear above it. Same on both figures — they were normalised together.
const Alignment kPlayerLabelAlign = Alignment(0, 0.05);

/// The turnaround figure is drawn at eye level, not from above, so its
/// chest is higher in the box than the top-down figure's: 0.42 of a
/// 430px figure centred in 512, through the 1.57 draw scale.
const Alignment kTurnLabelAlign = Alignment(0, -0.2);
Alignment playerLabelAlign(SportType sport, PlayerIcon p) =>
    PlayerArt.turns(sport, p.gender, TopDownPlayerPainter.figureFor(sport, p))
        ? kTurnLabelAlign
        : kPlayerLabelAlign;


// ─────────────────────────────────────────────────────────────────────────────
// The figure a player token is drawn from
// ─────────────────────────────────────────────────────────────────────────────

/// Greyscale top-down player art, tinted to the team colour as it is drawn.
///
/// A token was a circle on an oval, and at 36pt a board of them reads as
/// beads rather than people. These are the same moulded figures the referee
/// and the coach already are. They ship in neutral grey because there is no
/// palette to bake: a coach picks the two team colours, and a red shirt in
/// the pixels would fight whatever they pick.
///
/// A painter is synchronous and an asset is not, so the first frames of a
/// board are drawn with the old circle and oval and repaint themselves the
/// moment the decode lands — [ready] is what makes that repaint happen.
class PlayerArt {
  PlayerArt._();

  /// Bumped once per image decoded. Every player painter listens to it.
  static final ValueNotifier<int> ready = ValueNotifier<int>(0);

  static final Map<String, ui.Image> _plates = {};
  static final Set<String> _asked = {};
  static final Set<String> _missing = {};

  static String _key(PlayerGender g, PlayerFigure f, String layer) =>
      '${g == PlayerGender.female ? 'female' : 'male'}.${f.name}.$layer';

  /// A turnaround sheet: the figure at eight headings, 4x2 cells of 512,
  /// clockwise from up the board — N NE E SE S SW W NW. Same two layers as
  /// a single plate. Not every figure has one yet; the painter falls back
  /// to the single plate, which faces the viewer, when it does not.
  static const int kTurnCells = 8, kTurnCols = 4, kTurnCell = 512;

  static ui.Image? turnOf(SportType sport, PlayerGender g, PlayerFigure f) =>
      _plate(sport, g, f, 'turn_base');
  static ui.Image? turnKitOf(
          SportType sport, PlayerGender g, PlayerFigure f) =>
      _plate(sport, g, f, 'turn_kit');

  /// Whether this figure can face every way. Answered from what has
  /// loaded, so it is false for the first frames and flips once.
  static bool turns(SportType sport, PlayerGender g, PlayerFigure f) =>
      turnOf(sport, g, f) != null && turnKitOf(sport, g, f) != null;

  /// The plain figure is everybody's and lives in the core; a racket, a bat
  /// and a swim cap belong to the sports that use them and ship in their
  /// packages, so a soccer app has no swim caps to carry.
  static String _path(
      SportType sport, PlayerGender g, PlayerFigure f, String layer) {
    final gn = g == PlayerGender.female ? 'female' : 'male';
    final file = 'assets/icon/player_top_$gn'
        '${f == PlayerFigure.plain ? '' : '_${f.name}'}_$layer.png';
    return f == PlayerFigure.plain
        ? packageAsset(file)
        : sportAsset(sport, file);
  }

  /// The body — skin, hair, socks, boots — in its own colours, and the whole
  /// silhouette in its alpha. Null until the asset has decoded; asking is
  /// what starts the decode, so nothing has to remember to warm it.
  static ui.Image? of(SportType sport, PlayerGender gender, PlayerFigure f) =>
      _plate(sport, gender, f, 'base');

  /// Kit alone, in grey, for the team colour to land on. A player is not one
  /// colour: tinting the whole figure turned a coach's squad into eleven blue
  /// blobs, when what stands on a real board is eleven people wearing blue.
  /// For the swimmer the kit is the cap and the suit, which is how a real
  /// water polo team is told apart anyway.
  static ui.Image? kitOf(
          SportType sport, PlayerGender gender, PlayerFigure f) =>
      _plate(sport, gender, f, 'kit');

  static ui.Image? _plate(
      SportType sport, PlayerGender g, PlayerFigure f, String layer) {
    final k = _key(g, f, layer);
    if (_asked.add(k)) _load(k, _path(sport, g, f, layer));
    return _plates[k];
  }

  /// Decodes every figure every sport can draw and waits for them. Only the
  /// headless board renderer needs it: it shoots a frame the moment it pumps
  /// and would otherwise catch every first board mid-decode.
  static Future<void> warm() async {
    final want = <String>{};
    for (final s in SportType.values) {
      for (final g in [PlayerGender.male, PlayerGender.female]) {
        for (final f in <PlayerFigure?>{
          PlayerFigure.plain,
          s.playerBody,
          s.playerImplement,
        }) {
          if (f == null) continue;
          for (final layer in ['base', 'kit', 'turn_base', 'turn_kit']) {
            want.add(_key(g, f, layer));
            _plate(s, g, f, layer);
          }
        }
      }
    }
    // A plate this app does not ship counts as settled, not as never: the
    // wait is for the decode to finish, not for the file to exist.
    while (!want.every((k) => _plates.containsKey(k) || _missing.contains(k))) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  static Future<void> _load(String key, String path) async {
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _plates[key] = frame.image;
      ready.value++;
    } catch (_) {
      // No art, no crash: the painter keeps drawing the circle and the oval.
      _missing.add(key);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-down person painter (shared between board and toolbar preview)
// ─────────────────────────────────────────────────────────────────────────────
class TopDownPlayerPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool isSelected;
  final PlayerGender gender;
  final PlayerFigure figure;
  /// Only used to find the figure's plates: an implement ships in the package
  /// of the sport that swings it.
  final SportType sport;
  /// Which way the player faces, radians clockwise from up the board.
  /// See [playerFacing]. The default faces the viewer, which is what a
  /// palette preview with no player behind it should do.
  final double heading;
  /// Quarter turns clockwise the board is shown at. The picture is chosen
  /// for the heading as it appears ON SCREEN, so a player facing up the
  /// board is drawn facing right when the board lies on its side.
  final int boardTurns;
  final bool isGhost;

  /// Not const: it repaints on [PlayerArt.ready], so the tokens already on
  /// screen pick the figures up as soon as they decode.
  TopDownPlayerPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    this.isSelected = false,
    this.gender = PlayerGender.unspecified,
    this.figure = PlayerFigure.plain,
    this.sport = SportType.soccer,
    this.heading = pi,
    this.boardTurns = 0,
    this.isGhost = false,
  }) : super(repaint: PlayerArt.ready);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final turn = PlayerArt.turnOf(sport, gender, figure);
    final turnKit = PlayerArt.turnKitOf(sport, gender, figure);
    if (turn != null && turnKit != null) {
      final onScreen = heading + boardTurns * pi / 2;
      final cell = ((onScreen / (pi / 4)).round() % PlayerArt.kTurnCells +
              PlayerArt.kTurnCells) %
          PlayerArt.kTurnCells;
      const c = PlayerArt.kTurnCell;
      final src = Rect.fromLTWH(
          (cell % PlayerArt.kTurnCols) * c.toDouble(),
          (cell ~/ PlayerArt.kTurnCols) * c.toDouble(),
          c.toDouble(),
          c.toDouble());
      _paintArt(canvas, turn, turnKit, Offset.zero & size, src);
      return;
    }

    final art = PlayerArt.of(sport, gender, figure);
    final kit = PlayerArt.kitOf(sport, gender, figure);
    if (art != null && kit != null) {
      _paintArt(canvas, art, kit, Offset.zero & size,
          Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()));
      return;
    }

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

  /// How much brighter than a straight multiply the tint is pushed.
  ///
  /// The kit plate is built at about 85% grey — bright enough that a plain
  /// multiply lands on the team colour itself, with the shirt's own shading
  /// moving either side of it. Nothing left to correct for, so 1.
  ///
  /// It was 2, for the old art where the whole figure was one mid grey and a
  /// straight multiply came out navy. Left at 2 here it multiplied a plate
  /// that was already bright and the home side came out sky blue: measured
  /// off the render at team colour x 1.74, which is 221/255 x 2 to within a
  /// step.
  static const double _tintGain = 1.0;

  /// The body plate as it was drawn — skin is skin, boots are boots.
  Paint _plainPaint(double opacity) => Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = opacity == 1.0
        ? null
        : ColorFilter.matrix(<double>[
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, opacity, 0,
          ]);

  /// Grey in, team colour out. A per-channel multiply: nothing in the kit
  /// plate has a hue of its own to fight it.
  ///
  /// [FilterQuality.medium] and not the default, which is none: this draws a
  /// 512px figure into a 36pt box, and point-sampling a downscale that steep
  /// is what made the hair speckle, the shoulders stair-step and the whole
  /// token read as mush next to a cone.
  Paint _tintPaint(double opacity) => Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = ColorFilter.matrix(<double>[
      _tintGain * color.r, 0, 0, 0, 0,
      0, _tintGain * color.g, 0, 0, 0,
      0, 0, _tintGain * color.b, 0, 0,
      0, 0, 0, opacity, 0,
    ]);

  /// The figure as one flat colour — the outline, the shadow it stands in,
  /// and the white base a ghost sits on.
  Paint _silhouettePaint(Color c, double opacity) => Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = ColorFilter.matrix(<double>[
      0, 0, 0, 0, c.r * 255,
      0, 0, 0, 0, c.g * 255,
      0, 0, 0, 0, c.b * 255,
      0, 0, 0, opacity, 0,
    ]);

  /// How much bigger than its box the figure is drawn.
  ///
  /// The box is the token — what a finger grabs, what the spacing audit
  /// measures — and it does not move. But a person seen from above is a
  /// narrow thing, so a figure fitted inside the box came out 20pt across
  /// where the circle and oval it replaced was 29, and on the pitch it read
  /// as the smaller of the two markers. The equipment sprites solve the same
  /// problem the same way.
  /// 1.57, not the 1.25 it was: the plates now leave headroom for a bat
  /// carried above the head, so the person inside a 512 square is smaller
  /// and the box it is drawn into has to grow to keep them the same size on
  /// the pitch. Measured, not guessed — the plain figure is 395px tall where
  /// it used to be 496.
  static const double _figureScale = 1.57;

  /// Which figure to draw for [player] on a board of [sport].
  ///
  /// The sport owns the body and the implement; the player owns only whether
  /// they are holding it. A sport with nothing to hold ignores the flag, so
  /// a board carried over from another sport never comes up empty-handed by
  /// accident — it comes up plain, which is what it always looked like.
  static PlayerFigure figureFor(SportType sport, PlayerIcon player) {
    // A referee or a coach holds nothing and wears no kit the sport
    // dictates: the plain figure, whatever the sport's players are drawn as.
    if (player.isMarker) return PlayerFigure.plain;
    final body = sport.playerBody;
    if (body == PlayerFigure.water) return body;
    final held = sport.playerImplement;
    if (held == null) return body;
    final holds = player.holdsImplement ?? sport.implementHeldByDefault;
    return holds ? held : body;
  }

  /// The figure's silhouette in [c], stamped eight ways round itself at
  /// [r] to make an outline an image does not have.
  void _stamp(Canvas canvas, ui.Image art, Rect src, Rect dst, Color c,
      double r) {
    final paint = _silhouettePaint(c, 1.0);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawImageRect(
          art, src, dst.shift(Offset(cos(a) * r, sin(a) * r)), paint);
    }
  }

  void _paintArt(
      Canvas canvas, ui.Image art, ui.Image kit, Rect box, Rect src) {
    final dst = box.inflate(box.width * (_figureScale - 1) / 2);

    if (isGhost) {
      // Two coats, same reason as the drawn ghost: green turf under a
      // half-transparent red shirt comes out brown, so the figure stands on
      // a white base and keeps its colour whatever pitch it is on.
      canvas.drawImageRect(art, src, dst, _silhouettePaint(Colors.white, 0.55));
      canvas.drawImageRect(art, src, dst, _plainPaint(0.45));
      canvas.drawImageRect(kit, src, dst, _tintPaint(0.6));
      return;
    }

    if (isSelected) {
      // A ring on the grass at the player's feet — not a glow around them.
      // The glow was a blurred copy of the figure, arms, legs and the
      // daylight between the boots included, which read as a smear behind
      // a person rather than as "this one is selected". The rim the stamps
      // below draw in the accent colour is the edge; this is the marker.
      final feet = Offset(dst.center.dx, dst.center.dy + dst.height * 0.42);
      final ring = Rect.fromCenter(
          center: feet, width: box.width * 0.92, height: box.width * 0.36);
      canvas.drawOval(
          ring,
          Paint()
            ..color = T.accent.withValues(alpha: 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawOval(ring, Paint()..color = T.accent.withValues(alpha: 0.22));
      canvas.drawOval(
          ring,
          Paint()
            ..color = T.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8);
    }

    // The figure is cut out of its own render, shadow and all: the art it
    // came with was a soft grey smear under the boots, and stamping the
    // outline from a silhouette that included it painted that smear white.
    // The shadow belongs to the painter, the same one the drawn token cast.
    final unzoom = 1 / gViewZoom;
    canvas.drawImageRect(
      art,
      src,
      dst.shift(Offset(1.5 * unzoom, 2 * unzoom)),
      _silhouettePaint(Colors.black, 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * unzoom),
    );

    // The stroke the drawn shape used to carry. A token is ringed in the
    // player's own arrow colour, which is how a coach matches a body on the
    // pitch to a line drawn across it — an image has no outline, so the
    // silhouette is stamped around itself to make one.
    //
    // Capped, because a stroke straddles the edge it is drawn on and half of
    // it lands inside the shape. A stamp is all outside, and on a figure
    // with arms, legs and daylight between the boots, all outside is most of
    // what you see: 2.5pt of it read as a glow round the player rather than
    // an edge on them.
    if (borderWidth > 0) {
      final r = min(borderWidth, 2.2) * 0.52 * unzoom;
      _stamp(canvas, art, src, dst, borderColor, r);
      // And white inside it, always. A player's arrow colour is often their
      // kit colour as well — the away side was ringed coral on coral, which
      // left the red figures with no edge at all and sitting flat on the
      // grass while the blue ones stood off it.
      _stamp(canvas, art, src, dst, Colors.white, r * 0.5);
    }

    canvas.drawImageRect(art, src, dst, _plainPaint(1.0));
    canvas.drawImageRect(kit, src, dst, _tintPaint(1.0));
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
      old.figure != figure ||
      old.sport != sport ||
      old.heading != heading ||
      old.boardTurns != boardTurns ||
      old.isGhost != isGhost;
}

// ─────────────────────────────────────────────────────────────────────────────
// Which way the board is turned on screen
// ─────────────────────────────────────────────────────────────────────────────

/// How many quarter turns clockwise the board is displayed at. Landscape
/// turns the whole canvas 90°, and a figure turned with it lies on its side:
/// the art is shot from above and slightly in front, so it only reads as a
/// person while its own up is the screen's up. Bodies counter-turn by this;
/// everything in board space — routes, markers, the facing chevron — does
/// not.
class BoardOrientation extends InheritedWidget {
  final int quarterTurns;
  const BoardOrientation(
      {super.key, required this.quarterTurns, required super.child});

  static int of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BoardOrientation>()
          ?.quarterTurns ??
      0;

  /// The turns that undo the board's, for a body that must stay upright.
  static int counterTurns(BuildContext context) => (4 - of(context)) % 4;

  @override
  bool updateShouldNotify(BoardOrientation old) =>
      old.quarterTurns != quarterTurns;
}

// ─────────────────────────────────────────────────────────────────────────────
// Facing
// ─────────────────────────────────────────────────────────────────────────────

/// Where a player is facing, in radians clockwise from up the board.
///
/// The picture is never rotated: a figure drawn from in front turns into a
/// body lying on the grass the moment it is, and a chevron beside an
/// unturned face was overruled by the face. So the figure is drawn eight
/// times, once per heading, and the heading picks the picture — the way a
/// top-down game draws a character. The home side plays bottom to top and
/// faces up by default; everyone else faces the viewer. The coach's own
/// turn, [PlayerIcon.rotation], is added on top and snaps to the eight.
double playerFacing(PlayerIcon p) =>
    (p.team == PlayerTeam.home ? 0.0 : pi) + p.rotation;

/// Where a player faces at beat [step] of a board: at their next action,
/// the same rule the drill generator uses for the opening stance, asked
/// again every beat. A man about to pass faces the target; a man about to
/// receive faces the ball; a man about to run faces down the run; anyone
/// else with a ball on the pitch watches the ball. Null when the board
/// gives no cue, and the caller falls back to [playerFacing].
///
/// This replaced "face the way you came": a runner who had reached the
/// touchline stood staring at it for the rest of the drill, and the man
/// who had just laid the ball off turned his back on the whole pattern.

/// Fold a heading so it obeys the net, for a token drawn at [at].
///
/// The rule behind [boardHeading] is "face your next action", and on a
/// court that is wrong in a way a player would notice at once: the next
/// action after reaching the net is the recovery to base, so the man was
/// drawn having spun round to face his own back line. You lunge to the net
/// facing it and you push back off that lunge still facing it. The net
/// stays in front of you.
///
/// Badminton has one exception, and it is one corner of the court: the
/// BACKHAND rear. That is the corner you cannot reach facing forwards —
/// you turn, travel back with your back to the net, hit, and turn again.
/// The forehand rear is a scissor jump taken chest-on, and the two front
/// corners are lunges you push straight back out of, so all three of them
/// keep the net in front of you. For a right-hander the backhand rear is
/// the left corner of his own half, and the other way round for the man
/// across the net. The sideways half of the heading is kept either way;
/// only the towards/away half is folded.
/// Racket sports whose players stay square to the net whatever they do:
/// they shuffle sideways, step in and step back, and never turn away.
bool squareToNet(SportType sport) =>
    sport == SportType.tableTennis ||
    sport == SportType.tennis ||
    sport == SportType.pickleball ||
    sport == SportType.beachTennis;

double faceAcrossNet(double h, PlayerIcon p, SportType sport, Offset at,
    Size court, {Offset? ball, Offset? ballFrom}) {
  if (!sport.hasNet) return h;
  // A racket sport's rule, not every net sport's. In volleyball, sepak
  // takraw and footvolley the ball is played BETWEEN team-mates on the same
  // side before it ever crosses: a pepper pair face each other, a setter
  // turns his back on the net to back-set, a passer turns to the man he is
  // passing to. Folding them to the net drew both halves of a two-man
  // warm-up facing the same way, the one thing a coach would notice first.
  //
  // What they do instead is never turn their backs on the BALL. A volleyball
  // player has no stroke that is played behind him: he moves to the ball and
  // squares up to it, and "face the way you ran" — the fallback when the
  // next action resolves to himself — had a passer stepping back for a deep
  // serve drawn with his back to the server. So the heading is kept unless
  // it points away from the ball, and then it is the ball.
  if (sport == SportType.volleyball ||
      sport == SportType.sepakTakraw ||
      sport == SportType.footvolley) {
    // No ball on the board at all — a court-sprint, a jump series, any of
    // the conditioning boards. A volleyball player runs those square to the
    // net: he shuffles and he sprints, he does not turn to face the cone he
    // is running at. Without a ball to watch he keeps his stance.
    if (ball == null) return playerFacing(p);
    var toBall = ball - at;
    // A ball he is playing is on him and points nowhere — half a token is
    // close enough to be his — so he faces where it came FROM: the server,
    // the hitter, the partner who passed it. That is the stance a passer
    // takes, and it is what stops a man who stepped back for a deep serve
    // being drawn with his back to the man who served it.
    if (toBall.distance < kPlayerIconSize * 0.5) {
      if (ballFrom == null) return h;
      toBall = ballFrom - at;
      if (toBall.distance < kPlayerIconSize * 0.5) return h;
      return atan2(toBall.dx, -toBall.dy);
    }
    final facing = Offset(sin(h), -cos(h));
    final away = facing.dx * toBall.dx + facing.dy * toBall.dy;
    return away >= 0 ? h : atan2(toBall.dx, -toBall.dy);
  }
  final wantUp = p.team == PlayerTeam.home;
  // Table tennis is played square to the table. A player shuffles sideways,
  // steps in and steps back, and never turns his shoulder or his back to
  // it — the ghost of a multiball player was drawn in profile because his
  // stored stance was 90 degrees, and the fold below only flips the
  // forward half of a heading, never the sideways half.
  //
  // Tennis, pickleball and beach tennis the same way: after the stroke the
  // player recovers with a side-shuffle, square to the net — drawn along
  // his travel he stood in profile, or angled off towards the sideline.
  if (squareToNet(sport)) return wantUp ? 0.0 : pi;
  var faceNet = true;
  if (sport == SportType.badminton && court.height > 0 && court.width > 0) {
    // 0.82, not 0.80: the rear corners of the footwork boards sit at 0.89
    // of the canvas and a round-the-head clear is taken from 0.80 — the
    // one shot whose entire point is NOT turning your back — and the old
    // line ran a thousandth under it.
    final deep = wantUp
        ? at.dy / court.height > 0.82
        : at.dy / court.height < 0.18;
    final backhand =
        wantUp ? at.dx / court.width < 0.5 : at.dx / court.width > 0.5;
    // And only on the way IN. Turning your back on the net is what you do
    // retreating into the backhand corner; coming out of it you are
    // already facing forwards again, and standing in it waiting to start
    // you never turned at all. Measured against where the token began the
    // board: a feeder whose ready position is that corner was drawn
    // turned away before anything had happened, and a clear rally — both
    // players living in a rear corner and stepping out of it between
    // shots — had one of them spin round on every recovery.
    final wentBack = wantUp
        ? at.dy > p.position.dy + 0.5
        : at.dy < p.position.dy - 0.5;
    faceNet = !(deep && backhand && wentBack);
    // Square to it, not angled towards it. A badminton player stands
    // facing the net because he has to cover both sides of himself, and
    // the lunge to a front corner does not turn him — he reaches, and he
    // pushes back out of it the way he came. Keeping the sideways half of
    // the travel direction had him swivel 45 degrees to go to the corner
    // and swivel back, which is a step nobody takes.
    return faceNet == wantUp ? 0.0 : pi;
  }
  final u = sin(h);
  var v = cos(h); // positive is up the board, towards the far side
  final up = faceNet == wantUp;
  if (up ? v < 0 : v > 0) v = -v;
  return atan2(u, v);
}

double? boardHeading(List<PlayerIcon> all, PlayerIcon p, int step) {
  // How close a ball sits to the feet of the player holding it: the
  // generator places it 24pt away, and a pass into space beside a man is
  // not a pass to him.
  const holdRadius = 24.0 * 1.4;
  double? dir(Offset from, Offset to) {
    final d = to - from;
    return d.distance < 1e-3 ? null : atan2(d.dx, -d.dy);
  }

  p.syncPhases();
  int? runPhase;
  Offset? runFrom, runTo;
  for (var i = 0; i < p.moves.length; i++) {
    final ph = i < p.movePhases.length ? p.movePhases[i] : i;
    if (ph >= step) {
      runPhase = ph;
      runTo = p.moves[i];
      runFrom = i == 0 ? p.position : p.moves[i - 1];
      break;
    }
  }
  final run = runFrom == null ? null : dir(runFrom, runTo!);

  PlayerIcon? ball;
  for (final x in all) {
    if (x.isBall) {
      ball = x;
      break;
    }
  }
  if (ball == null) return run;

  final me = standingAt(p, step);
  final ballNow = ballPositionAt(all, ball, step);
  ball.syncPhases();
  int? legPhase;
  Offset? legTo;
  for (var i = 0; i < ball.moves.length; i++) {
    final ph = i < ball.movePhases.length ? ball.movePhases[i] : i;
    if (ph >= step) {
      legPhase = ph;
      legTo = ball.moves[i];
      break;
    }
  }
  // Whoever is standing closest to it has it. Being merely within reach is
  // not enough: a keeper with a forward bearing down on him is a stride from
  // the ball, was read as the man about to play it, and so was drawn facing
  // where the SHOT was going — turning his back on the attacker to watch his
  // own goal.
  var nearestToBall = double.infinity;
  for (final x in all) {
    if (x.isBall || x.isMarker) continue;
    final d = (standingAt(x, step) - ballNow).distance;
    if (d < nearestToBall) nearestToBall = d;
  }
  if (legPhase != null && (runPhase == null || legPhase <= runPhase)) {
    if ((me - ballNow).distance < holdRadius &&
        (me - ballNow).distance <= nearestToBall + 0.5) {
      return dir(me, legTo!) ?? run; // about to pass
    }
    if ((chainEndAt(p, legPhase + 1) - legTo!).distance < holdRadius) {
      return dir(me, ballNow) ?? run; // about to receive: face the passer
    }
  }
  // A run that starts on this beat is what I am doing; a run two beats away
  // is not, and standing with my back to the ball until it comes round is
  // not what a player does. C, waiting on the wing to check away at beat
  // two, faced up the pitch from the first frame while the ball was still
  // at the other end.
  if (runPhase == step) return run ?? dir(me, ballNow);
  // A ball lying exactly on a player — a spike that lands on the defender,
  // a ball hit straight at him — points nowhere, and the token used to
  // snap back to its team's default facing for the rest of the board. He
  // keeps the way the last beat had him facing instead.
  return dir(me, ballNow) ??
      run ??
      (step > 0 ? boardHeading(all, p, step - 1) : null);
}

/// Where the ball is at beat [step]: down its own legs, or at the feet of
/// whoever it is attached to.
Offset ballPositionAt(List<PlayerIcon> all, PlayerIcon ball, int step) {
  if (ball.moves.isEmpty && ball.attachedTo != null) {
    for (final x in all) {
      if (x.id == ball.attachedTo) return standingAt(x, step);
    }
  }
  return standingAt(ball, step);
}

/// Where a token stands at the start of beat [step]. [chainEndAt] reads a
/// zero as "no limit" — the whole run, the canvas's convention for a board
/// at rest — which is nowhere anyone stands before the first beat: asked
/// about beat 0, a dribbler was placed at his last cone, found the ball
/// there too, and "passed" it back to his first cone, facing the viewer.
Offset standingAt(PlayerIcon p, int step) =>
    step <= 0 ? p.position : chainEndAt(p, step);

/// Where a player faces while a beat carries them: along the leg of the
/// run they are on. [at] is where the token is drawn mid-leg.
double playerHeadingAt(PlayerIcon p, Offset? at) {
  if (at == null || p.moves.isEmpty) return playerFacing(p);
  final chain = [p.position, ...p.moves];
  if ((at - chain.first).distance < 0.5) return playerFacing(p);
  var best = double.infinity;
  double? heading;
  for (var i = 0; i + 1 < chain.length; i++) {
    final a = chain[i], b = chain[i + 1];
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 < 1e-6) continue;
    final t = (((at - a).dx * ab.dx + (at - a).dy * ab.dy) / len2)
        .clamp(0.0, 1.0);
    final d = (at - (a + ab * t)).distance;
    if (d + 1e-6 < best) {
      best = d;
      heading = atan2(ab.dx, -ab.dy);
    }
  }
  return heading ?? playerFacing(p);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main player icon widget
// ─────────────────────────────────────────────────────────────────────────────
class PlayerIconWidget extends StatelessWidget {
  final PlayerIcon player;
  final bool isSelected;
  /// The board this token is on. It decides the body, the implement and
  /// which package the artwork comes out of.
  final SportType sport;
  /// Where the player faces right now; null means the drill's stance.
  /// The board passes the heading of the run the token is on.
  final double? heading;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(ScaleStartDetails)? onScaleStart;
  final Function(ScaleUpdateDetails)? onScaleUpdate;
  final Function(ScaleEndDetails)? onScaleEnd;
  /// Hang the name badge over the head instead of under the feet.
  ///
  /// The badge hangs 30pt below the middle, which is the head of anyone
  /// standing a stride nearer the viewer — a marker behind an attacker put
  /// his "X1" on the attacker's hair, and with the nearer figure painted
  /// last the badge came out cut in half. The board sets this when the spot
  /// below is taken; the badge then sits on its owner's head, still touching
  /// him, so whose it is stays plain.
  final bool labelAbove;

  /// A right-click (trackpad, mouse) — and on a tablet a long press — asks
  /// for the element's menu, at this point on the screen.
  final void Function(Offset globalPosition)? onContextMenu;

  const PlayerIconWidget({
    super.key,
    required this.player,
    this.isSelected = false,
    this.sport = SportType.soccer,
    this.heading,
    this.labelAbove = false,
    this.onTap,
    this.onLongPress,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onContextMenu,
  });

  /// The long press opens the menu only on a tablet and only where nothing
  /// else has claimed it; a phone's board is unchanged.
  GestureLongPressStartCallback? _menuOnHold(BuildContext context) {
    final menu = onContextMenu;
    if (menu == null || onLongPress != null) return null;
    if (MediaQuery.sizeOf(context).shortestSide < 600) return null;
    return (d) => menu(d.globalPosition);
  }

  /// A pointer that can hover gets told this is something to pick up.
  Widget _hoverable(Widget child) => onTap == null && onScaleStart == null
      ? child
      : MouseRegion(cursor: SystemMouseCursors.grab, child: child);

  @override
  Widget build(BuildContext context) {
    // A text element is its text. Everything else on the board is a token in
    // a 44pt box with a label inside it; this one is the label, so it sizes
    // to what was typed instead of cropping it to fit a circle. The "T in a
    // circle" MarkerPainter still draws is right where it belongs — as the
    // tool's own icon in the palette.
    if (isTextElement(player)) {
      // The gestures sit INSIDE the turn. Every box above a Transform keeps
      // the untransformed rectangle for its hit test, so a detector wrapped
      // around a turned chip answered only where the two rectangles
      // overlapped. Inside it, the detector's own frame is the chip's, and
      // the whole of it answers at any angle.
      return turnedForText(
        player,
        extraQuarters: BoardOrientation.counterTurns(context),
        _hoverable(GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          onLongPressStart: _menuOnHold(context),
          onSecondaryTapUp: onContextMenu == null
              ? null
              : (d) => onContextMenu!(d.globalPosition),
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          onScaleEnd: onScaleEnd,
          child: TextElementChip(
              player: player, isSelected: isSelected, turned: false),
        )),
      );
    }
    final size = kPlayerIconSize * player.scale;
    return _hoverable(GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressStart: _menuOnHold(context),
      onSecondaryTapUp: onContextMenu == null
          ? null
          : (d) => onContextMenu!(d.globalPosition),
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      // The name badge hangs under the figure ON SCREEN. It used to be the
      // second child of a Column, and a column runs down the BOARD: turn the
      // phone and the name swung round to the player's side, where it read
      // as a label with no token under it — a goalkeeper's GK floating in
      // his six-yard box with the goalkeeper an inch away. The badge is
      // placed out of the token's box instead, in whichever direction is
      // down on the screen, and the box itself stays the 36pt square
      // everything else positions and grabs the player by.
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _ContactShadow(player: player, size: size),
          AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            scale: isSelected ? 1.1 : 1.0,
            // Markers and balls turn with `rotation` — an arrow that does
            // not turn is no arrow. A person is never rotated as a picture:
            // the token stays upright on screen whichever way the board is
            // turned, and the heading picks which of eight pictures is
            // drawn. See playerFacing.
            child: ((player.isMarker && !player.isPersonMarker) || player.isBall)
                ? RotatedBox(
                    // A cone does not fall over when the board is turned;
                    // a goal keeps its bearing. See kUprightMarkers.
                    quarterTurns: staysUpright(player)
                        ? BoardOrientation.counterTurns(context)
                        : 0,
                    child: Transform.rotate(
                    angle: player.rotation,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: (player.isMarker && player.photoId != null)
                          ? ShapedPhotoMarker(
                              player: player, isSelected: isSelected)
                          : player.isMarker
                              ? _MarkerWidget(
                                  player: player,
                                  isSelected: isSelected,
                                  sport: sport)
                              : Center(
                                  child: FractionallySizedBox(
                                    widthFactor: ballDrawFactor(sport),
                                    heightFactor: ballDrawFactor(sport),
                                    child: _BallWidget(
                                        player: player,
                                        isSelected: isSelected),
                                  ),
                                ),
                    ),
                  ))
                : SizedBox(
                    width: size,
                    height: size,
                    child: RotatedBox(
                      quarterTurns: BoardOrientation.counterTurns(context),
                      child: player.photoId != null
                          ? PhotoPlayerShape(
                              player: player, isSelected: isSelected)
                          : _PlayerShape(
                              player: player,
                              isSelected: isSelected,
                              sport: sport,
                              heading: heading),
                    ),
                  ),
          ),
          if (player.label.isNotEmpty && !player.labelInside)
            Transform.translate(
              // Clear of the figure, down the screen. In points rather than
              // a fraction of the box: the box is 36pt but the figure is
              // drawn 1.57 boxes tall, so a badge placed by the box lands on
              // the player's shins.
              offset: turnVector(
                  Offset(
                      0,
                      labelAbove
                          // Above the hair: the figure's ink reaches 24pt
                          // over the middle, the badge is 13 tall.
                          ? -(kPlayerIconSize * 0.5 + 14 * kFigureScale) *
                              player.scale
                          : kPlayerIconSize * 0.5 * player.scale +
                              11.7 * player.scale * kFigureScale),
                  BoardOrientation.counterTurns(context)),
              child: RotatedBox(
              // Upright on screen like the body above it.
              quarterTurns: BoardOrientation.counterTurns(context),
              child: Container(
              // A pill, not a tag: rounded to its own height, a little
              // wider (volleyball's editor mock, 2026-10-17).
              padding: EdgeInsets.symmetric(
                  horizontal: 7 * kFigureScale, vertical: 2 * kFigureScale),
              decoration: BoxDecoration(
                color: player.color.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12 * kFigureScale),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2)],
              ),
              child: Text(
                player.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12 * player.scale * kFigureScale,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ),
            ),
        ],
      ),
    ));
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Top-down person shape with number label
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerShape extends StatelessWidget {
  final PlayerIcon player;
  final bool isSelected;
  final SportType sport;
  final double? heading;
  const _PlayerShape(
      {required this.player,
      required this.isSelected,
      this.sport = SportType.soccer,
      this.heading});

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
            figure: TopDownPlayerPainter.figureFor(sport, player),
            sport: sport,
            heading: heading ?? playerFacing(player),
            boardTurns: BoardOrientation.of(context),
          ),
          size: Size.infinite,
        ),
        if (player.labelInside)
          Align(
            alignment: playerLabelAlign(sport, player),
            child: Text(
              player.label,
              // Heavier weight + a dark outline (layered shadows) keeps the
              // jersey number crisp from the bench and when projected.
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15 * player.scale * kFigureScale,
                height: 1,
                shadows: [
                  Shadow(
                      color: Colors.black,
                      offset: Offset(0.8 / gViewZoom, 0.8 / gViewZoom),
                      blurRadius: 1.5 / gViewZoom),
                  Shadow(
                      color: Colors.black,
                      offset: Offset(-0.8 / gViewZoom, -0.8 / gViewZoom),
                      blurRadius: 1.5 / gViewZoom),
                  Shadow(color: Colors.black87, blurRadius: 3 / gViewZoom),
                ],
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
  void didUpdateWidget(PhotoPlayerShape oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.photoId != widget.player.photoId) _resolve();
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
    final ringWidth = (3.0 * p.scale * kFigureScale).clamp(2.5, 5.0 * kFigureScale).toDouble();
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
                  fontSize: 10 * p.scale * kFigureScale,
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
/// The equipment only some sports can show. Everything else in the Add sheet
/// is on offer in every sport, so it stays in the core; these seventeen ship
/// in the package of whichever sports list them, which is why a soccer app no
/// longer carries a basketball hoop and a set of rugby posts.
const Set<MarkerShape> kSportScopedMarkers = {
  MarkerShape.hoop,
  MarkerShape.net,
  MarkerShape.antenna,
  MarkerShape.racket,
  MarkerShape.paddle,
  MarkerShape.shuttleTube,
  MarkerShape.hopper,
  MarkerShape.base,
  MarkerShape.homePlate,
  MarkerShape.battingTee,
  MarkerShape.lScreen,
  MarkerShape.rugbyPosts,
  MarkerShape.tackleBag,
  MarkerShape.hockeyStick,
  MarkerShape.floatingGoal,
  MarkerShape.laneRope,
  MarkerShape.chair,
};

String? markerImageAsset(MarkerShape shape, SportType sport) => switch (shape) {
      MarkerShape.cone => _markerAsset(shape, sport, 'assets/icon/marker_cone.png'),
      MarkerShape.ladder => _markerAsset(shape, sport, 'assets/icon/marker_ladder.png'),
      MarkerShape.hurdle => _markerAsset(shape, sport, 'assets/icon/marker_hurdle.png'),
      MarkerShape.referee => _markerAsset(shape, sport, 'assets/icon/marker_referee.png'),
      MarkerShape.coach => _markerAsset(shape, sport, 'assets/icon/marker_coach.png'),
      MarkerShape.goal => _markerAsset(shape, sport, 'assets/icon/marker_goal.png'),
      MarkerShape.miniGoal => _markerAsset(shape, sport, 'assets/icon/marker_minigoal.png'),
      MarkerShape.mannequin => _markerAsset(shape, sport, 'assets/icon/marker_mannequin.png'),
      MarkerShape.pole => _markerAsset(shape, sport, 'assets/icon/marker_pole.png'),
      MarkerShape.disc => _markerAsset(shape, sport, 'assets/icon/marker_disc.png'),
      MarkerShape.ring => _markerAsset(shape, sport, 'assets/icon/marker_ring.png'),
      MarkerShape.rebounder => _markerAsset(shape, sport, 'assets/icon/marker_rebounder.png'),
      MarkerShape.bench => _markerAsset(shape, sport, 'assets/icon/marker_bench.png'),
      MarkerShape.ballBag => _markerAsset(shape, sport, 'assets/icon/marker_ballbag.png'),
      MarkerShape.cornerFlag => _markerAsset(shape, sport, 'assets/icon/marker_flag.png'),
      MarkerShape.hoop => _markerAsset(shape, sport, 'assets/icon/marker_hoop.png'),
      MarkerShape.net => _markerAsset(shape, sport, 'assets/icon/marker_net.png'),
      MarkerShape.antenna => _markerAsset(shape, sport, 'assets/icon/marker_antenna.png'),
      MarkerShape.racket => _markerAsset(shape, sport, 'assets/icon/marker_racket.png'),
      MarkerShape.paddle => _markerAsset(shape, sport, 'assets/icon/marker_paddle.png'),
      MarkerShape.shuttleTube =>
        _markerAsset(shape, sport, 'assets/icon/marker_shuttletube.png'),
      MarkerShape.hopper => _markerAsset(shape, sport, 'assets/icon/marker_hopper.png'),
      MarkerShape.base => _markerAsset(shape, sport, 'assets/icon/marker_base.png'),
      MarkerShape.homePlate =>
        _markerAsset(shape, sport, 'assets/icon/marker_homeplate.png'),
      MarkerShape.battingTee => _markerAsset(shape, sport, 'assets/icon/marker_tee.png'),
      MarkerShape.lScreen => _markerAsset(shape, sport, 'assets/icon/marker_lscreen.png'),
      MarkerShape.rugbyPosts => _markerAsset(shape, sport, 'assets/icon/marker_posts.png'),
      MarkerShape.tackleBag =>
        _markerAsset(shape, sport, 'assets/icon/marker_tacklebag.png'),
      MarkerShape.hockeyStick => _markerAsset(shape, sport, 'assets/icon/marker_stick.png'),
      MarkerShape.floatingGoal =>
        _markerAsset(shape, sport, 'assets/icon/marker_floatinggoal.png'),
      MarkerShape.laneRope => _markerAsset(shape, sport, 'assets/icon/marker_lanerope.png'),
      MarkerShape.chair => _markerAsset(shape, sport, 'assets/icon/marker_chair.png'),
      _ => null,
    };

/// Equipment whose picture stands up and has no bearing on the pitch.
///
/// A cone is a cone whichever way the board is turned. Its art is an object
/// standing on the grass, photographed from the side, and turning the board
/// is the camera moving round the pitch — not the cone falling over. These
/// counter-turn with the figures (see BoardOrientation); everything with a
/// direction turns with the pitch instead, because that direction is the
/// whole point of it: a goal faces somewhere, a hurdle is cleared one way,
/// a ladder runs along a line, an arrow points, and home plate points at
/// the catcher.
///
/// A ball is in here for the same reason a cone is: it is a sphere with its
/// highlight painted on, and rolling that highlight round the board was the
/// only thing turning it ever did.
const kUprightMarkers = <MarkerShape>{
  MarkerShape.cone,
  MarkerShape.pole,
  MarkerShape.disc,
  MarkerShape.ring,
  MarkerShape.ballBag,
  MarkerShape.cornerFlag,
  MarkerShape.shuttleTube,
  MarkerShape.hopper,
  MarkerShape.battingTee,
  MarkerShape.tackleBag,
  MarkerShape.antenna,
  MarkerShape.mannequin,
  MarkerShape.referee,
  MarkerShape.coach,
  MarkerShape.chair,
};

/// The equipment that stands up off the grass.
///
/// [kUprightMarkers] less the two that lie flat on it: a marker disc and a
/// throw-down ring are printed on the ground, and a player standing over one
/// hides it exactly as a player standing over one does in life. The rest have
/// a height, and a figure that stands 47pt tall buries anything shorter than
/// that directly behind it — see markerClearOffsets.
/// The patch of ground a token is standing on.
///
/// Everything on the board was drawn flat, each piece a sticker with a white
/// outline and nothing under it — a cut-out lying on the turf rather than a
/// figure standing on it. This is one soft ellipse at the token's own
/// contact point: the shoes for a person, the resting point for a ball or a
/// cone. Flat equipment (a base, a marker disc, a throw-down ring) is
/// already ON the ground and gets none.
///
/// It turns with the board, like the name badge above it: the figures stay
/// upright on screen whichever way the pitch is pointed, so "under" is under
/// on the screen and not in board coordinates.
class _ContactShadow extends StatelessWidget {
  final PlayerIcon player;
  final double size;
  const _ContactShadow({required this.player, required this.size});

  @override
  Widget build(BuildContext context) {
    if (isTextElement(player)) return const SizedBox.shrink();
    // A ball is not a marker, so "not a marker" alone counted it as a
    // person and dropped its shadow to where a figure's shoes are — 25pt
    // down, 15pt clear of the ball, which then hung in the air above it.
    final person =
        !player.isBall && (!player.isMarker || player.isPersonMarker);
    if (player.isMarker && !person &&
        !kStandingMarkers.contains(player.markerShape)) {
      return const SizedBox.shrink();
    }
    // A figure is drawn 1.4 boxes tall and its shoes sit 0.70 of a box below
    // the middle — measured off the art, not guessed; see tool/ink_probe.dart.
    //
    // Everything else is fitted to its own box by [markerArtScale], so where
    // its foot lands is half that. A flat 0.33 for all of them put a cone's
    // shadow BEHIND the cone: the art reaches 0.31 of a box below the middle
    // and the shadow's whole half-height is 0.03, so the only thing that
    // showed was a sliver, and the cone stood in mid-air. The shadow now
    // starts where the object's own base ends.
    // Centred ON the contact edge, not under it: the object hides the top
    // half and the bottom half shows as the rim of ground it stands on. Put
    // wholly below the edge, even by a few points, the same ellipse reads as
    // the shadow of something held above it. The 0.03 is the transparent
    // padding the ball and cone bitmaps carry under their ink (measured:
    // both end 9.2–9.5pt below the middle, not the 10.4–11.2 their draw
    // factors say).
    final draw = (player.isBall
            ? ballDrawFactor(player.sportType ?? SportType.soccer)
            : markerArtScale(player.markerShape))
        .clamp(0.4, 1.2);
    final drop = person ? size * 0.70 : size * (draw / 2 - 0.03);
    final w = person ? size * 0.66 : size * draw * 1.1;
    return Transform.translate(
      // A hair to the right as well as down: the figures are lit from the
      // upper left, and a shadow directly underneath reads as a sticker
      // with a smudge rather than a body with a light on it.
      offset: turnVector(Offset(w * (person ? 0.10 : 0.16), drop),
          BoardOrientation.counterTurns(context)),
      child: RotatedBox(
        quarterTurns: BoardOrientation.counterTurns(context),
        // A round gradient squashed, not a gradient in a flat box: a
        // RadialGradient takes its radius from the box's SHORTER side, so
        // painted straight into an ellipse 22pt by 6 it came out as a 6pt
        // dot beside the boots.
        child: Transform.scale(
          scaleY: 0.30,
          child: Container(
            width: w,
            height: w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Colors.black.withValues(alpha: 0.42),
                Colors.black.withValues(alpha: 0.0),
              ], stops: const [0.45, 1.0]),
            ),
          ),
        ),
      ),
    );
  }
}

const kStandingMarkers = <MarkerShape>{
  MarkerShape.cone,
  MarkerShape.pole,
  MarkerShape.ballBag,
  MarkerShape.cornerFlag,
  MarkerShape.shuttleTube,
  MarkerShape.hopper,
  MarkerShape.battingTee,
  MarkerShape.tackleBag,
  MarkerShape.antenna,
  MarkerShape.mannequin,
  MarkerShape.referee,
  MarkerShape.coach,
  MarkerShape.chair,
};

/// Whether [p]'s picture stays upright on screen when the board is turned.
bool staysUpright(PlayerIcon p) =>
    p.isBall || (p.isMarker && kUprightMarkers.contains(p.markerShape));

/// Core for the shared markers, the sport's own package for the seventeen
/// that only some sports offer.
String _markerAsset(MarkerShape shape, SportType sport, String path) =>
    kSportScopedMarkers.contains(shape)
        ? sportAsset(sport, path)
        : packageAsset(path);

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
      MarkerShape.hurdle => 0.8,
      MarkerShape.ladder => 2.3,
      // A goal is the width of a penalty area's mouth and a disc is something
      // you step over: the same rule as the cone and the ladder, applied to
      // ten more objects. The grab box does not change.
      //
      // Ten of them were redrawn from directly above on 2026-09-26, because
      // a side view cannot be turned: every one of these both stands up and
      // points somewhere, so the board tipped them over the moment a coach
      // turned one or laid the phone on its side. Their numbers were worked
      // out to keep each piece the width it was already drawn at, so no
      // saved board changes size — except the hoop and the posts, whose old
      // art was tall and narrow and whose footprint from above is the
      // backboard and the gap between the uprights.
      MarkerShape.goal => 2.5,
      MarkerShape.miniGoal => 1.45,
      MarkerShape.rebounder => 1.5,
      MarkerShape.bench => 1.85,
      // The three human ones are measured against a player, not guessed at:
      // a figure is drawn into 1.57 boxes and fills 430 of its plate's 512,
      // so it stands 47.5pt on a 36pt token, while a marker is fitted to its
      // box whole — the referee filled 0.889 of his plate and came out 32pt,
      // two thirds of the players he was sent to officiate.
      MarkerShape.referee => 1.48,
      MarkerShape.coach => 1.43,
      MarkerShape.mannequin => 1.47,
      MarkerShape.pole => 1.05,
      MarkerShape.cornerFlag => 1.0,
      MarkerShape.ballBag => 0.8,
      MarkerShape.ring => 0.85,
      MarkerShape.disc => 0.6,
      MarkerShape.net => 2.6,
      MarkerShape.rugbyPosts => 1.5,
      MarkerShape.laneRope => 2.4,
      MarkerShape.floatingGoal => 2.15,
      MarkerShape.hoop => 1.25,
      MarkerShape.lScreen => 1.45,
      MarkerShape.hockeyStick => 1.3,
      MarkerShape.racket => 1.1,
      MarkerShape.antenna => 1.0,
      MarkerShape.hopper => 1.0,
      MarkerShape.tackleBag => 1.0,
      MarkerShape.chair => 0.9,
      MarkerShape.battingTee => 0.9,
      MarkerShape.paddle => 0.8,
      MarkerShape.base => 0.7,
      MarkerShape.homePlate => 0.7,
      MarkerShape.shuttleTube => 0.7,
      _ => 1.0,
    };

class _MarkerWidget extends StatelessWidget {
  final PlayerIcon player;
  final bool isSelected;
  final SportType sport;
  const _MarkerWidget(
      {required this.player, required this.isSelected, this.sport = SportType.soccer});

  @override
  Widget build(BuildContext context) {
    final art = markerImageAsset(player.markerShape, sport);
    final body = Stack(
      children: [
        if (art != null)
          // The sprite carries its own contact shadow, so the painter's is
          // not wanted here; the selection ring is drawn over the top instead
          // of around a shape the image no longer matches.
          Positioned.fill(
            child: Image.asset(art,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                // A board carried in from another sport can name equipment
                // this app does not ship. It falls back to the drawing rather
                // than to a broken-image box.
                errorBuilder: (_, _, _) => CustomPaint(
                      painter: MarkerPainter(
                        shape: player.markerShape,
                        color: player.color,
                        isSelected: isSelected,
                      ),
                      size: Size.infinite,
                    )),
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
                fontSize: 12 * player.scale * kFigureScale,
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

/// How wide a text element is allowed to get before it wraps, and how many
/// lines it is allowed to wrap into.
///
/// 150 and three lines for a short coaching phrase — wide enough to read,
/// narrow enough that three of them on a pitch do not overlap each other by
/// default. A drill's own step runs longer than that (median 31 characters
/// across the library, the ninetieth percentile 71, the longest 259), and at
/// 150 it came out as a column nine lines deep.
///
/// So a long one is given the width instead of the height: most of the
/// board's short side, and two lines. It is the caption under a picture, and
/// a caption that climbs three or four lines up into the court is covering
/// the thing it describes. What will not fit is an ellipsis away — tapping
/// the element opens the whole of it to read and to edit.
///
/// Length is measured as it reads, not in characters: a Chinese or Japanese
/// character is as wide as two Latin ones, so a 30-character Chinese step
/// was given the short label's 150 points and cut to "5 名 …" (audit
/// 2026-10-11 M2). And a drill's own step note always gets the caption's
/// width and three lines: it is a sentence, not a label, and the third line
/// is what kept the 90th-percentile step whole.
double textElementMaxWidth(BuildContext context, String label,
    {bool note = false}) {
  if (!note && textReadLength(label) <= 40) return 150.0;
  return (MediaQuery.sizeOf(context).shortestSide * 0.8).clamp(280.0, 520.0);
}

int textElementMaxLines(String label, {bool note = false}) =>
    note || textReadLength(label) <= 40 ? 3 : 2;

/// The id the drill's step note is placed under (TacticsState.kDrillNoteId).
const String kDrillNoteElementId = 'drill_note';

/// How long [s] reads, in Latin-character widths: CJK ideographs, kana,
/// Hangul and full-width forms count two.
int textReadLength(String s) {
  var n = 0;
  for (final r in s.runes) {
    final wide = (r >= 0x1100 && r <= 0x115F) ||
        (r >= 0x2E80 && r <= 0xA4CF) ||
        (r >= 0xAC00 && r <= 0xD7A3) ||
        (r >= 0xF900 && r <= 0xFAFF) ||
        (r >= 0xFE30 && r <= 0xFE4F) ||
        (r >= 0xFF00 && r <= 0xFF60) ||
        (r >= 0xFFE0 && r <= 0xFFE6);
    n += wide ? 2 : 1;
  }
  return n;
}

/// What the longest step in the drill library needs, with room to edit it.
/// The other elements cap at 12 because they are a name under a token; this
/// one IS the sentence.
const int kTextElementMaxChars = 260;

/// The words, on a chip sized to them.
/// The platform face for a text element's [PlayerIcon.font], primary and
/// fallbacks. Names differ by platform and Flutter takes the first it can
/// find, so both are listed; an unknown name falls through to the default.
List<String> textFontFamily(String? font) {
  final apple = Platform.isIOS || Platform.isMacOS;
  return switch (font) {
    'serif' => apple
        ? const ['Georgia', 'Times New Roman', 'serif']
        : const ['serif', 'Noto Serif', 'Georgia'],
    'mono' => apple
        ? const ['Menlo', 'Courier New', 'monospace']
        : const ['monospace', 'Droid Sans Mono', 'Courier New'],
    'hand' => apple
        ? const ['Marker Felt', 'Chalkboard SE', 'Bradley Hand', 'casual']
        : const ['casual', 'cursive', 'Marker Felt'],
    _ => const [],
  };
}

/// What a face is called on a picker. A type specimen, not a word to
/// translate: these are Latin faces and the name is set in the face itself,
/// which is what tells them apart — four "Aa" at 14pt did not.
String textFontName(String? font) => switch (font) {
      'serif' => 'Serif',
      'mono' => 'Mono',
      'hand' => 'Hand',
      _ => 'Sans',
    };

/// One face on a picker: a big "Aa" over its name, both set in the face.
/// The tune panel and the add-text dialog show the same four.
class TextFontChip extends StatelessWidget {
  /// One of [kTextFonts]; the empty string is the app's own face.
  final String font;
  final bool selected;
  final VoidCallback onTap;

  const TextFontChip(
      {super.key,
      required this.font,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final faces = textFontFamily(font);
    final family = faces.isEmpty ? null : faces.first;
    final fallback = faces.length > 1 ? faces.sublist(1) : null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? T.accent : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.1,
                fontWeight: FontWeight.w600,
                fontFamily: family,
                fontFamilyFallback: fallback,
              ),
            ),
            Text(
              textFontName(font),
              style: TextStyle(
                color: selected ? T.accent : Colors.white54,
                fontSize: 9,
                height: 1.1,
                fontFamily: family,
                fontFamilyFallback: fallback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A text element turned the way its rotation says, as a whole, text and
/// all: it IS the text, and a label along a touchline reads along the
/// touchline. Every other token turns its picture and keeps its label
/// upright.
///
/// A quarter turn is turned by ROTATING THE BOX, not by transforming the
/// paint inside it. Transform.rotate leaves the layout size alone: a chip
/// lying on its side still measured 280 across and 45 down while it painted
/// 45 across and 280 down, so the half-size it is pulled back by to sit on
/// its point was the half-size of the wrong rectangle. RotatedBox turns the
/// box with it. A free angle (a marker turned 15 degrees at a time) still
/// transforms — there is no box for it — and sits a little off its point;
/// its hit area is right regardless, because the gestures live inside the
/// turn (see PlayerIconWidget).
///
/// [extraQuarters] is the board's counter-turn ([BoardOrientation.counterTurns]).
/// Words are for the reader, so a text element keeps its own rotation
/// relative to the SCREEN: when landscape turns the whole board a quarter,
/// the chip turns back the way the figures do, and "Press high" or the
/// step note no longer reads down the side of an iPad.
Widget turnedForText(PlayerIcon player, Widget child,
    {int extraQuarters = 0}) {
  final angle = player.rotation + extraQuarters * (pi / 2);
  final quarters = angle / (pi / 2);
  final nearest = quarters.roundToDouble();
  final squared = (quarters - nearest).abs() < 0.01;
  return squared
      ? RotatedBox(quarterTurns: (nearest.toInt() % 4 + 4) % 4, child: child)
      : Transform.rotate(angle: angle, child: child);
}

/// A drag delta reported inside a turned text element, put back into the
/// board's frame.
///
/// The gesture detector lives inside the turn (see [turnedForText]), which
/// is what makes the whole chip answer a tap at any angle — and it means a
/// drag's delta arrives in the CHIP's frame, not the board's. A note lying
/// on its side was moving at a right angle to the finger; the board turned
/// too, sideways, made that read as backwards.
Offset untwistForText(PlayerIcon player, Offset local,
    {int extraQuarters = 0}) {
  final a = player.rotation + extraQuarters * (pi / 2);
  if (a == 0) return local;
  return Offset(local.dx * cos(a) - local.dy * sin(a),
      local.dx * sin(a) + local.dy * cos(a));
}

class TextElementChip extends StatelessWidget {
  final PlayerIcon player;
  final bool isSelected;

  /// False when the caller turns the chip itself, so that it can put its
  /// gesture detector inside the turn. See [turnedForText].
  final bool turned;
  const TextElementChip(
      {super.key,
      required this.player,
      this.isSelected = false,
      this.turned = true});

  @override
  Widget build(BuildContext context) {
    // With the board's figures (gBoardFigureScale): on an iPad the people
    // and their labels are half as big again, and a sentence under the
    // court set in a phone's 13pt read as the one thing nobody had
    // enlarged. The width it may wrap in stays the screen's (see
    // textElementMaxWidth) — placeDrillNote measures it at that width.
    // Never smaller: an upright volleyball board shrinks its figures to
    // keep the far server on it, and words have no server to keep.
    final scale = player.scale * max(1.0, gBoardFigureScale);
    // An empty one would be an invisible thing you cannot tap again, so it
    // keeps the tool's own glyph until something is typed into it.
    final empty = player.label.trim().isEmpty;
    final faces = textFontFamily(player.font);
    final body = ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: textElementMaxWidth(context, player.label,
                  note: player.id == kDrillNoteElementId) *
              player.scale),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 8 * scale, vertical: 4.5 * scale),
        decoration: BoxDecoration(
          color: player.color.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(6 * scale),
          // Fixed-point details, un-magnified by a view zoom (gViewZoom).
          border: isSelected
              ? Border.all(color: T.accent, width: 2 / gViewZoom)
              : Border.all(color: Colors.white24, width: 1 / gViewZoom),
          boxShadow: [
            BoxShadow(
                color: Colors.black45,
                blurRadius: 4 / gViewZoom,
                offset: Offset(1 / gViewZoom, 1 / gViewZoom)),
          ],
        ),
        child: Text(
          empty ? 'T' : player.label,
          maxLines: textElementMaxLines(player.label,
              note: player.id == kDrillNoteElementId),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13 * scale,
            height: 1.25,
            fontWeight: FontWeight.w600,
            fontFamily: faces.isEmpty ? null : faces.first,
            fontFamilyFallback: faces.length > 1 ? faces.sublist(1) : null,
            shadows: [Shadow(color: Colors.black54, blurRadius: 2 / gViewZoom)],
          ),
        ),
      ),
    );
    return turned
        ? turnedForText(player, body,
            extraQuarters: BoardOrientation.counterTurns(context))
        : body;
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

    // Shadow. Not for a zone: that one is paint on the floor, not a thing
    // standing on it, and a drop shadow under it was half of why it read
    // as a little tile somebody had put down.
    if (shape != MarkerShape.zone) {
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(cx + 1, cy + 2), r, shadow);
    }

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
        // An area of the floor the shot has to land in. The old one was a
        // solid amber box with a hard 2pt outline and a drop shadow: an
        // object on the court, which is what it looked like. Shading is a
        // wash with a soft edge — a pale bloom under a tint of the marker
        // colour, and a dashed line round it so the boundary is still
        // readable without drawing a frame.
        final rect = Rect.fromCenter(
            center: Offset(cx, cy), width: r * 2.4, height: r * 2.0);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        canvas.drawRRect(
            rr, Paint()..color = Colors.white.withValues(alpha: 0.14));
        canvas.drawRRect(
            rr, Paint()..color = color.withValues(alpha: 0.20));
        final edge = Paint()
          ..color = color.withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        for (final m in (Path()..addRRect(rr)).computeMetrics()) {
          var at = 0.0;
          var on = true;
          while (at < m.length) {
            final end = (at + (on ? 5.0 : 4.0)).clamp(0.0, m.length);
            if (on) canvas.drawPath(m.extractPath(at, end), edge);
            at = end;
            on = !on;
          }
        }
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
      // Equipment that exists only as artwork: the widget draws its sprite
      // and never reaches this painter. Named rather than left to a default
      // so that adding a marker with no picture is a compile error here, not
      // a blank space on someone's board. The cone, ladder, hurdle, referee
      // and coach are NOT in this list — they have sprites too, but they
      // kept their code drawing above, from before the artwork existed.
      case MarkerShape.goal:
      case MarkerShape.miniGoal:
      case MarkerShape.mannequin:
      case MarkerShape.pole:
      case MarkerShape.disc:
      case MarkerShape.ring:
      case MarkerShape.rebounder:
      case MarkerShape.bench:
      case MarkerShape.ballBag:
      case MarkerShape.cornerFlag:
      case MarkerShape.hoop:
      case MarkerShape.net:
      case MarkerShape.antenna:
      case MarkerShape.racket:
      case MarkerShape.paddle:
      case MarkerShape.shuttleTube:
      case MarkerShape.hopper:
      case MarkerShape.base:
      case MarkerShape.homePlate:
      case MarkerShape.battingTee:
      case MarkerShape.lScreen:
      case MarkerShape.rugbyPosts:
      case MarkerShape.tackleBag:
      case MarkerShape.hockeyStick:
      case MarkerShape.floatingGoal:
      case MarkerShape.laneRope:
      case MarkerShape.chair:
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
                fontSize: 11 * widget.player.scale * kFigureScale,
                height: 1,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
              ),
            ),
          ),
      ],
    );
  }
}
