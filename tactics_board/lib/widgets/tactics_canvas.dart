import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior, kDoubleTapTimeout, PointerDeviceKind;
import 'package:flutter/material.dart';
import '../ui/tokens.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/sport_type.dart';
import '../models/player_icon.dart';
import '../models/drawing_stroke.dart';
import '../painters/drawing_painter.dart';
import '../painters/ball_painter.dart';
import '../painters/player_moves_painter.dart';
import '../painters/badminton_court_painter.dart';
import '../painters/basketball_court_painter.dart';
import '../painters/tennis_court_painter.dart';
import '../painters/table_tennis_court_painter.dart';
import '../painters/volleyball_court_painter.dart';
import '../painters/pickleball_court_painter.dart';
import '../painters/soccer_court_painter.dart';
import '../painters/field_hockey_court_painter.dart';
import '../painters/rugby_court_painter.dart';
import '../painters/baseball_court_painter.dart';
import '../painters/handball_court_painter.dart';
import '../painters/water_polo_court_painter.dart';
import '../painters/sepak_takraw_court_painter.dart';
import '../painters/beach_tennis_court_painter.dart';
import '../painters/footvolley_court_painter.dart';
import '../state/tactics_state.dart';
import 'player_icon_widget.dart';
import 'volleyball_rotation_widgets.dart';

/// Paint order for everything standing on the board.
///
/// The list is in the order things were added, so a cone dropped after a
/// player was drawn on top of them — four hurdles hid the numbers of the four
/// players they belonged to. Equipment is context, a player is the subject and
/// a ball is what the eye follows, so they layer in that order. Stack order is
/// also hit-test order, so this additionally means a tap where a player and a
/// cone overlap selects the player.
///
/// Among the people and the balls the order is DEPTH, by [depth]: how far
/// down the screen each one touches the ground. The figures stand up, so
/// lower on the screen is nearer the viewer, and the nearer thing is painted
/// last. "The ball on top of everyone" was only ever right when the ball
/// was between the viewer and everyone — a pass laid at C's feet was drawn
/// over the head of X2, who was standing a stride nearer than C, as though
/// the ball were the size of a man and hanging in front of him.
///
/// Without a [depth] the balls go over the people, which is what a caller
/// with no board to measure — a preview, a test — gets. Equipment stays
/// under everyone whatever its depth: that rule was set by four hurdles
/// hiding the numbers of the players they belonged to, and a cone under a
/// player's foot is the picture a coach meant.
@visibleForTesting
List<PlayerIcon> inPaintOrderForTest(
  List<PlayerIcon> players, {
  double Function(PlayerIcon)? depth,
}) => _inPaintOrder(players, depth);

List<PlayerIcon> _inPaintOrder(
  List<PlayerIcon> players, [
  double Function(PlayerIcon)? depth,
]) {
  final markers = <PlayerIcon>[];
  final rest = <(double, int, PlayerIcon)>[];
  for (var i = 0; i < players.length; i++) {
    final p = players[i];
    if (p.isMarker) {
      markers.add(p);
    } else {
      rest.add((depth?.call(p) ?? (p.isBall ? 1.0 : 0.0), i, p));
    }
  }
  // The added order breaks ties, because List.sort is not stable in Dart
  // and two players on one point must not swap on an unrelated rebuild.
  rest.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    return c != 0 ? c : a.$2.compareTo(b.$2);
  });
  return [...markers, ...rest.map((e) => e.$3)];
}

/// Whether a figure at this heading has its back to the viewer.
///
/// The art is a turnaround of eight pictures and the heading picks the cell
/// — see TopDownPlayerPainter. Cell 0 faces straight up the screen, which is
/// away from whoever is looking at it; the two beside it are three-quarters
/// turned away and read the same. The other five show some chest.
bool facesAwayOnScreen(double heading, int boardTurns) {
  final onScreen = heading + boardTurns * math.pi / 2;
  final cell = ((onScreen / (math.pi / 4)).round() % 8 + 8) % 8;
  return cell == 0 || cell == 1 || cell == 7;
}

/// The board as the phone draws it: a 402x874 screen less the toolbar and the
/// safe areas. A preview lays the canvas out at exactly this and scales the
/// result, because a token is a fixed 44pt whatever box the canvas is given —
/// laid out small, a preview came out with full-size players standing on a
/// shrunken pitch. It is the same size tool/render_boards.dart shoots at, so
/// a preview, a shot and the board itself are one picture at three sizes.
const double kBoardRefWidth = 402;
const double kBoardRefHeight = 730;

/// Where a chain has reached once every phase below [phaseLimit] has run.
///
/// phaseLimit 0 is the overview: step 0 shows the whole planned chain, so the
/// end of it is the last leg, not the start.
Offset chainEndAt(PlayerIcon player, int phaseLimit) {
  if (player.moves.isEmpty) return player.position;
  if (phaseLimit <= 0) return player.moves.last;
  player.syncPhases();
  var end = player.position;
  for (var i = 0; i < player.moves.length; i++) {
    final ph = i < player.movePhases.length ? player.movePhases[i] : i;
    if (ph < phaseLimit) end = player.moves[i];
  }
  return end;
}

/// How close two players have to be before the board fans them apart.
double get _kFanThreshold => kPlayerIconSize * 0.9;

/// How far each one moves when they are exactly on top of each other.
double get _kFanRadius => kPlayerIconSize * 0.4;

/// How close a ball has to be to a player before it is drawn at their feet.
///
/// The same reach the facing rules use for "this is his ball": the generator
/// places a carried ball 24pt from its holder.
double get _kHoldReach => kPlayerIconSize * 0.95;

/// Where a ball at the feet sits, in the holder's own frame.
///
/// Three numbers, all in cells of the token. [anchor] is where the shoes
/// are on the screen — 0.70 of a cell below the middle, measured off the
/// art, and the same whichever way he faces, because the figures stand
/// upright on the screen. [ahead] is how far past the shoes the ball goes
/// in the direction he FACES: for a man facing the viewer that is down the
/// screen, for a man running up the pitch it is up the screen, and that is
/// the whole point — the ball used to be dropped down the screen for
/// everyone, which put a dribbler's ball behind his heels. [side] is a
/// screen-horizontal step out of his silhouette, so the ball is visible
/// beside the leg rather than lost behind it when he has his back turned,
/// and beside the toe rather than under both boots when he has not.
///
/// 0.25 ahead with 0.40 to the side: facing the viewer the ball's top just
/// meets the toe of the near boot and the rest is in front of him; facing
/// away it stands beside his shin, a third of it behind the leg (it is
/// painted under him then — see the depth rule), which is what a ball a
/// stride ahead of a man walking away looks like.
double get _kFeetAnchor => kPlayerIconSize * 0.70;
double get _kFeetAhead => kPlayerIconSize * 0.25;
double get _kFeetSide => kPlayerIconSize * 0.40;

/// A ball carried in the hands: held in front of the player, to one side.
///
/// It used to be 0.18 of a cell below the middle and free to sit dead
/// centre, which put a basketball flat on the player's chest with his shirt
/// number behind it — one blob where there should be a man and the ball he
/// is holding.
///
/// Out to the hip fixed that and left a second problem: at hip height and
/// clear of the body the ball reads as standing BESIDE the player, or
/// behind him. There is no perspective on a board, so the only thing that
/// says "in front" is one shape covering another. The figure is 23.5pt
/// across and the ball is drawn 21pt wide, so the ball comes in far enough
/// to cover the edge of the shorts — it is painted after the players, so
/// it is the one on top — and down far enough that it sits over the legs
/// with its bottom level with the shoes.
/// Same frame as the feet: the hands hang at 0.30 of a cell below the
/// middle, the ball is held 0.20 of a cell ahead of them and 0.40 to the
/// side, clear of the shirt and its number.
double get _kHandAnchor => kPlayerIconSize * 0.30;
double get _kHandAhead => kPlayerIconSize * 0.20;
double get _kHandSide => kPlayerIconSize * 0.40;

/// A volleyball is played off the platform or above the head, never carried.
///
/// At the hands' 0.30 below the middle the ball sat at the player's thigh,
/// which is the one height a volleyball is never at. Level with the middle
/// is his chest: a pass taken on the forearms, a set in front of the
/// forehead, a dig in front of the knees — all of them nearer the top half
/// of him than the floor. Still 0.40 out to the side, so it clears the
/// shirt and its number.
double get _kChestAnchor => kPlayerIconSize * -0.05;

/// One ball on its way to a holder: where it would sit between his feet, how
/// far across his facing the next one goes, and how much of the pull applies.
typedef _Held = ({String id, Offset middle, Offset across, double weight});

/// Where a ball its holder owns is drawn, relative to the middle of his
/// token: how far to the side, and how far down the screen.
///
/// Not every sport puts the ball on the floor. Measured off the drawn
/// figure: the shoes are 0.58 of a cell below the middle, so a basketball
/// dropped to the shoes sat on the court beside a player who is supposed to
/// be holding it — as did a handball, a water polo ball, a rugby ball and a
/// served shuttle. The sports played with the feet keep the shoes, and so
/// does hockey, where the ball is at the head of a stick that is on the
/// ground; everything else is carried.
///
///
/// See [_kFeetAnchor] for what the three numbers mean.
({double anchor, double ahead, double side}) ballHoldAt(SportType sport) =>
    switch (sport) {
      SportType.soccer ||
      SportType.fieldHockey => (
        anchor: _kFeetAnchor,
        ahead: _kFeetAhead,
        side: _kFeetSide,
      ),
      // Footvolley and sepak takraw are volleyball without hands: the ball
      // is met in the air — chest, shoulder, head, a raised foot — never
      // dribbled along the sand. Drawn at the shoes, a chest control read as
      // a ball lying at the player's feet.
      SportType.volleyball ||
      SportType.footvolley ||
      SportType.sepakTakraw => (
        anchor: _kChestAnchor,
        ahead: _kHandAhead,
        side: _kHandSide,
      ),
      _ => (anchor: _kHandAnchor, ahead: _kHandAhead, side: _kHandSide),
    };

/// Draw-time placement for a ball that belongs to somebody.
///
/// A carried ball is stored 24pt from its holder in the direction of play,
/// which was right when a player was a circle: any side of a disc is the
/// same side. A figure who stands up has a head at the top of that circle
/// and a number across the middle of it, so the same ball landed on the
/// hair of a man facing up the board and on the number of one facing down.
///
/// Like [fanOutOffsets] this moves the drawing only — the stored position is
/// what the pass rules, the facing rules and the hit test all read, and it is
/// untouched. The ball drops to the shoes and keeps the side it was already
/// on, so which way the play is going is still legible. The pull fades out
/// over the reach beyond [_kHoldReach], so a ball leaving on a pass slides
/// free of its holder instead of snapping.
///
/// "Below" is below on the SCREEN. The figures stand upright whichever way
/// the board is turned — see BoardOrientation — so on a landscape board a
/// drop of +y in board coordinates is a step to the player's side. The
/// vector is worked out in screen space and turned back into the board's.
Map<String, Offset> ballAtFeetOffsets(
  List<PlayerIcon> players,
  Offset Function(PlayerIcon) positionOf, {
  int boardTurns = 0,
  String? Function(PlayerIcon ball)? holderOf,
  SportType sport = SportType.soccer,

  /// Filled, when given, with the man each ball was decided to belong to.
  /// Who that is takes the board's word, a reach test and a keeper rule;
  /// the layering needs the same answer and must not work it out twice.
  Map<String, PlayerIcon>? intoHolders,

  /// Whether the ball has come to rest where it was going.
  ///
  /// The pull fades with distance so a ball LEAVING on a pass slides free
  /// of the man it is going to instead of snapping onto his boot the
  /// moment the beat starts. Once the beat is over there is nothing to
  /// fade: wherever the leg ended, the ball belongs at his feet. It was
  /// fading there too, so a ball that arrived 50pt from the man who had
  /// just stepped forward to collect it was only pulled 23% of the way in
  /// and came to rest a stride behind him — "the ball was right before the
  /// move and wrong once it came over".
  bool settled = false,

  /// Which way each holder faces, radians clockwise from up the BOARD (the
  /// same angle TopDownPlayerPainter is given). The ball goes ahead of him
  /// along it. Without it everyone is taken to face the viewer, which is
  /// what a caller with no beat to read it from gets.
  double Function(PlayerIcon holder)? headingOf,

  /// The playing surface, in board coordinates. A man standing in the corner
  /// had the ball put at his outside hand, which is over the line: on a board
  /// where the court is the whole subject, a ball off the court reads as a
  /// mistake. Given it, the ball takes whichever side keeps it in play.
  Rect? court,
}) {
  final hold = ballHoldAt(sport);
  final holders = players
      .where((p) => !p.isMarker && !p.isBall)
      .toList(growable: false);
  if (holders.isEmpty) return const {};
  final result = <String, Offset>{};
  // Every ball each holder was given, so the ones who ended up with more
  // than one can be spread apart below.
  final mine = <String, List<_Held>>{};
  for (final ball in players) {
    if (!ball.isBall) continue;
    final at = positionOf(ball);
    PlayerIcon? holder;
    var best = double.infinity;
    // A board that says who has it is believed, as long as he is within
    // reach of where the ball is. Nearest was the rule, and after a short
    // pass the passer is often nearer the ball than the man it was played
    // to: the pass was drawn arriving at his own other foot, two balls a
    // stride apart with a stub of an arrow between them.
    final named = holderOf?.call(ball);
    // A board that names holders and names nobody for this beat means the
    // ball is in the air: a shot, a loose ball, a pass between two men. It
    // must stay where the route puts it. Falling through to "nearest body"
    // magnetised a shot back onto the shooter's boot — the board drew him
    // taking it rather than letting it go, and once the start-of-leg trace
    // was drawn too he stood there with a ball either side of him.
    // A list of nothing but nulls is not an answer, it is a board that was
    // never asked: a drill whose ball legs are written as coordinates fills
    // the list to length with nulls and names nobody at all. Read as "the
    // ball is loose on every leg", a throw that lands on a fielder was left
    // dead centre on his token and disappeared behind him — the board said
    // "F throws to CF" with no ball anywhere on it.
    final boardNamesHolders =
        ball.moves.isNotEmpty &&
        ball.moveHolders.length == ball.moves.length &&
        ball.moveHolders.any((h) => h != null);
    // Only when the caller actually asked: with no holderOf, a null means
    // nobody enquired, and the nearest-body rule is the whole answer.
    if (holderOf != null && named == null && boardNamesHolders) continue;
    if (named != null) {
      for (final p in holders) {
        if (p.id == named) {
          best = (positionOf(p) - at).distance;
          holder = p;
        }
      }
    }
    if (holder == null) {
      for (final p in holders) {
        final d = (positionOf(p) - at).distance;
        if (d < best) {
          best = d;
          holder = p;
        }
      }
    }
    if (holder == null) continue;
    // A keeper does not collect a ball that is already past him. A shot is
    // aimed at the goal and the keeper stands in it, so the nearest body to
    // a ball on the line is always him: the arrowhead was pulled back onto
    // his shins and every drill named for its finish drew the ball being
    // gathered rather than going in. Past him means further from where
    // everyone else is standing than he is.
    if ((holder.role ?? '').toUpperCase() == 'GK') {
      var mid = Offset.zero;
      for (final p in holders) {
        mid += positionOf(p);
      }
      mid = mid / holders.length.toDouble();
      if ((at - mid).distance > (positionOf(holder) - mid).distance) continue;
    }
    final reach = _kHoldReach * holder.scale;
    if (best >= reach * 1.6) continue;
    final weight = settled || best <= reach
        ? 1.0
        : (1 - (best - reach) / (reach * 0.6)).clamp(0.0, 1.0);
    final from = positionOf(holder);
    // On screen. The ball sits a step AHEAD of the holder's shoes (or
    // hands) along the way he faces, and a step to the side out of his
    // silhouette — see _kFeetAnchor. "Ahead" is read off the heading as it
    // appears on the screen, where the figures stand upright whichever way
    // the board is turned.
    final d = turnVector(at - from, boardTurns);
    final h = (headingOf?.call(holder) ?? math.pi) + boardTurns * math.pi / 2;
    final forward = Offset(math.sin(h), -math.cos(h));
    // Which side: ahead of him when he faces across the screen, else the
    // side the ball already lies on, so a pass being received on the left
    // is not drawn arriving on the right.
    final sign = forward.dx.abs() > 0.3
        ? (forward.dx < 0 ? -1.0 : 1.0)
        : (d.dx < 0 ? -1.0 : 1.0);
    final side = sign * hold.side * holder.scale;
    // Bound once: the closures below cannot see the null check above.
    final him = holder;
    Offset spot(double sd) =>
        Offset(sd, hold.anchor * him.scale) +
        forward * (hold.ahead * him.scale);
    // The side is the holder's to choose — unless somebody is standing
    // there. A defender closing on the man in possession stands a stride
    // from him, on the side the ball is played to, and the ball drawn at
    // that side went under the defender's boots: with depth deciding who is
    // painted over whom, that is a man standing on a ball. If the chosen
    // side has another player within a token's reach and the other side is
    // clearer, the ball goes to the other side of the same feet.
    Offset landing(double sd) =>
        at + turnVector(spot(sd) - d, (4 - boardTurns) % 4) * weight;
    double clearance(Offset point) {
      var nearest = double.infinity;
      for (final p in holders) {
        if (identical(p, him)) continue;
        final gap = (positionOf(p) - point).distance;
        if (gap < nearest) nearest = gap;
      }
      return nearest;
    }

    var chosen = side;
    if (clearance(landing(side)) < kPlayerIconSize * 0.7 * holder.scale &&
        clearance(landing(-side)) > clearance(landing(side))) {
      chosen = -side;
    }
    // ...and not over the line, if the other side is on the court. A corner
    // shooter stands a stride from the sideline and the ball at his outside
    // hand sat in the crowd.
    if (court != null &&
        !court.contains(landing(chosen)) &&
        court.contains(landing(-chosen))) {
      chosen = -chosen;
    }
    final step = spot(chosen) - d;
    result[ball.id] = turnVector(step, (4 - boardTurns) % 4) * weight;
    intoHolders?[ball.id] = holder;
    // A man can have more than one ball — two-ball dribbling is a warm-up in
    // half the sports here. Remember whose they are, along with the spot
    // between his feet and which way is sideways TO HIM; the spread below
    // needs to know how many there turned out to be before it can centre
    // them, and it measures from the middle, not from the side one of them
    // happened to be given.
    (mine[him.id] ??= <_Held>[]).add((
      id: ball.id,
      middle: spot(0) - d,
      weight: weight,
      across: Offset(-forward.dy, forward.dx) * (hold.side * him.scale * 2),
    ));
  }
  // Two balls at one man's feet were drawn one in front of the other: the
  // side offset is a step along the SCREEN's x, so for a player facing
  // across the screen "his other side" is in front of him, not beside him.
  // Spread them across his facing instead, centred between his feet, so two
  // read as one in each hand and three as a row. Two end up exactly where
  // the old left/right flip put them on a board the right way up.
  for (final held in mine.values) {
    if (held.length < 2) continue;
    for (var i = 0; i < held.length; i++) {
      final h = held[i];
      final lateral = h.across * (i - (held.length - 1) / 2);
      result[h.id] =
          turnVector(h.middle + lateral, (4 - boardTurns) % 4) * h.weight;
    }
  }
  return result;
}

/// Where the ball stands at beat [beat], for the facing rules — null when
/// the board has no ball. The volleyball fold needs it to know which way a
/// player must not turn; see faceAcrossNet.
Offset? ballStandingAt(List<PlayerIcon> players, int beat) {
  for (final x in players) {
    if (x.isBall) return ballPositionAt(players, x, beat);
  }
  return null;
}

/// The Apple Pencil pointer drawing on the board right now, if any. Read by
/// the players, which ignore a palm's drag while it is set.
@visibleForTesting
int? pencilPointer;

/// A board-space vector as it appears on a screen turned [quarterTurns]
/// clockwise — the rotation RotatedBox applies, without the translation,
/// which an offset does not care about.
Offset turnVector(Offset v, int quarterTurns) {
  switch (quarterTurns % 4) {
    case 1:
      return Offset(-v.dy, v.dx);
    case 2:
      return Offset(-v.dx, -v.dy);
    case 3:
      return Offset(v.dy, -v.dx);
    default:
      return v;
  }
}

/// How far from a player's middle a standing marker has to be before the
/// figure stops burying it: half the figure, plus half a cone.
double get _kStandClear => kPlayerIconSize * 0.92;

/// Draw-time lift for equipment a player is standing in front of.
///
/// A drill puts a coach at his station and his cone a step behind him —
/// twenty board units, thirteen points. That was daylight when a player was
/// a 36pt disc. A figure is 47pt tall and most of it is above the middle, so
/// the cone went behind his head and what showed was its tip over one
/// shoulder and its base over the other: on the board it read as a second,
/// faded player standing behind the first, on a beat where nobody had moved.
///
/// The marker is lifted just clear of the head, along the way it already
/// leans, so the station still reads as being behind the player. Like
/// [fanOutOffsets] this moves the drawing only. Flat equipment is left alone:
/// a base, a marker disc and a throw-down ring are on the ground, and a
/// player standing over one is the picture a coach meant.
Map<String, Offset> markerClearOffsets(
  List<PlayerIcon> players,
  Offset Function(PlayerIcon) positionOf, {
  int boardTurns = 0,
}) {
  // Only people who STAND there. The lift exists for a coach at his
  // station with a cone a step behind him — the cone went behind his head
  // and read as a second, faded figure. A player who is running has no
  // station: they pass the equipment and are gone, and nudging it as they
  // go makes static equipment look like it moved. "Warm-up dribbling gates"
  // is the case that proves it — the drill is a player dribbling THROUGH
  // each pair of cones, 18 points from one of them, and pushing the gate
  // open is the one thing the picture must not do.
  final people = players
      .where((p) => !p.isMarker && !p.isBall && p.moves.isEmpty)
      .toList(growable: false);
  if (people.isEmpty) return const {};
  final result = <String, Offset>{};
  for (final m in players) {
    if (!m.isMarker || !kStandingMarkers.contains(m.markerShape)) continue;
    final at = positionOf(m);
    for (final p in people) {
      // On screen: the figure stands upright whichever way the board is
      // turned, so "behind the head" is a screen direction.
      final d = turnVector(at - positionOf(p), boardTurns);
      // Ramped by distance, with no box to cross.
      //
      // This used to test whether the cone fell inside a rectangle behind
      // the player's head and, if it did, jump it the whole way clear. Two
      // edges to trip over: the box itself, and — because the lift is
      // computed along `d` — the direction flipping as the player walked
      // over the cone. Either way the equipment twitched on a beat where
      // nothing about it had changed. Measured at 64pt of travel for 1pt of
      // player movement.
      //
      // Now the lift simply fades in over the clearing distance, so a run
      // passing a cone nudges it and lets it settle back. fanOutOffsets
      // solved the same problem for players; this is the same shape.
      final reach = _kStandClear * p.scale;
      if (d.distance >= reach) continue;
      // Screen-up when the player is on top of it: with no separation left
      // there is no direction to preserve, and normalising a near-zero
      // vector is what made it flip.
      final dir = d.distance < reach * 0.35
          ? const Offset(0, -1)
          : d / d.distance;
      final lift = (1 - d.distance / reach).clamp(0.0, 1.0);
      result[m.id] = turnVector(
        dir * (reach - d.distance) * lift,
        (4 - boardTurns) % 4,
      );
      break;
    }
  }
  return result;
}

/// Draw-time separation for players standing in the same place.
///
/// A run that ends where another player is standing hid one of them
/// completely — the arrow arrived at what looked like a single token. These
/// offsets are added to the [Positioned] only: `player.position` is untouched,
/// so the stored board, drag maths (which works off deltas) and the exported
/// coordinates are all unchanged. Because the offset moves the whole widget,
/// its gesture detector moves with it, so a tap still selects the token that
/// is under the finger.
///
/// Markers and balls are deliberately left out. Equipment under a player and a
/// ball at someone's feet are the arrangement a coach meant, not a collision.
///
/// The shift ramps with how close the players actually are — full at dead
/// centre, nothing at [_kFanThreshold] — so nothing pops as they converge
/// during playback or under a drag.
Map<String, Offset> fanOutOffsets(
  List<PlayerIcon> players,
  Offset Function(PlayerIcon) positionOf,
) {
  final subjects = players
      .where((p) => !p.isMarker && !p.isBall)
      .toList(growable: false);
  if (subjects.length < 2) return const {};

  // Connected components: A near B and B near C puts all three in one group,
  // which is what keeps a three-player pile-up from being fanned as a pair
  // plus a stray.
  final seen = <int>{};
  final result = <String, Offset>{};
  for (var i = 0; i < subjects.length; i++) {
    if (!seen.add(i)) continue;
    final group = <int>[i];
    for (var g = 0; g < group.length; g++) {
      for (var j = 0; j < subjects.length; j++) {
        if (seen.contains(j)) continue;
        final d =
            (positionOf(subjects[group[g]]) - positionOf(subjects[j])).distance;
        if (d < _kFanThreshold) {
          seen.add(j);
          group.add(j);
        }
      }
    }
    if (group.length < 2) continue;

    // Stable order, so the arrangement cannot shuffle on an unrelated rebuild.
    final members = group.map((k) => subjects[k]).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    var centre = Offset.zero;
    var closest = double.infinity;
    var biggest = 1.0;
    for (var a = 0; a < members.length; a++) {
      centre += positionOf(members[a]);
      biggest = biggest > members[a].scale ? biggest : members[a].scale;
      for (var b = a + 1; b < members.length; b++) {
        final d = (positionOf(members[a]) - positionOf(members[b])).distance;
        if (d < closest) closest = d;
      }
    }
    centre = centre / members.length.toDouble();
    final spread = (1 - closest / _kFanThreshold).clamp(0.0, 1.0);
    if (spread == 0) continue;
    // More tokens need more room: three in a line pushed only as far as a
    // pair leaves the middle one still overlapping both its neighbours.
    final crowd = 1 + 0.35 * (members.length - 2);
    final push = _kFanRadius * biggest * spread * crowd;

    for (var k = 0; k < members.length; k++) {
      // Push outward from the group's centre, never re-place onto a ring.
      // Ringing them re-centres the group, which pulled two players who were
      // 20pt apart to 17pt apart — the fan made the overlap worse for every
      // gap except dead centre. A pure outward push can only ever add
      // separation.
      final away = positionOf(members[k]) - centre;
      final dir = away.distance < 0.5
          // Exactly stacked: no direction to push along, so spread them
          // evenly around the circle instead.
          ? Offset(
              math.cos(2 * math.pi * k / members.length),
              math.sin(2 * math.pi * k / members.length),
            )
          : away / away.distance;
      result[members[k].id] = dir * push;
    }
  }
  return result;
}

class TacticsCanvas extends StatefulWidget {
  /// A read-only copy of a board — a drill's detail page, the home page's
  /// thumbnail — rather than THE board.
  ///
  /// Two things here belong to the live board alone and must not be built a
  /// second time: [boardRepaintKey] and [externalRepaintKey] are top-level
  /// GlobalKeys, so a second canvas anywhere in the tree steals them (Flutter
  /// throws "Duplicate GlobalKeys" the moment both are mounted, which is
  /// every push transition from a page showing a preview). They exist for
  /// capture — screenshots, PDF, video, the external display — and a preview
  /// is captured by nothing. Skipping the external layer also saves a
  /// preview from painting a 960x540 second copy of itself on every frame.
  final bool preview;

  /// Quarter turns clockwise the board is shown at — 1 in landscape, where
  /// the page turns the whole canvas. Bodies counter-turn by it so they stay
  /// upright; see BoardOrientation.
  final int boardTurns;
  const TacticsCanvas({super.key, this.preview = false, this.boardTurns = 0});

  @override
  State<TacticsCanvas> createState() => _TacticsCanvasState();
}

class _TacticsCanvasState extends State<TacticsCanvas> {
  // The last tap on a text element, for telling a second tap from a first.
  String? _lastTextTapId;
  DateTime? _lastTextTapAt;

  TacticsState? _stateOrNull;
  TacticsState get _state => _stateOrNull!;

  /// True while a multi-select pan is moving the group (started on a
  /// selected stroke). When false, multi-select pans draw the lasso rect.
  bool _multiSelectStrokeDragging = false;

  /// Last finger position while laying a run by dragging in add-move mode.
  Offset? _addMovePanPos;

  /// The player under the finger on a volleyball rotation board, for the
  /// patch of court he may legally stand on (RotationLegalAreaPainter).
  String? _rotationDragId;

  // Apple Pencil (tablet only; a phone's board is unchanged). The Pencil
  // draws in any mode — Draw, or Move without switching — and a finger
  // moves players. While the Pencil is on the glass a touch is a palm: it
  // neither draws nor drags. The Pencil's line is drawn here from raw
  // pointer events rather than by the board's pan, so Move mode needs no
  // pan recogniser fighting the players' own drags.
  bool _panIgnored = false;
  bool _touchStroke = false;

  bool _pencilCanDraw(TacticsState state) =>
      !state.presentationMode &&
      !state.isAnimating &&
      !state.multiSelectMode &&
      !(state.isAddingMove && state.selectedPlayerId != null) &&
      !(state.isDrawingMode && state.eraserMode);

  void _pencilDown(PointerDownEvent e, TacticsState state) {
    if (e.kind != PointerDeviceKind.stylus || pencilPointer != null) return;
    if (!_pencilCanDraw(state)) return;
    // Grabbing the selected line to move it is the pan's job.
    if (state.isDrawingMode &&
        state.selectedStrokeId != null &&
        state.hitTestStroke(e.localPosition) == state.selectedStrokeId) {
      return;
    }
    // A palm got there first and has started a line: it was never meant.
    if (_touchStroke) {
      state.cancelStroke();
      _touchStroke = false;
      _panIgnored = true;
    }
    if (state.selectedStrokeId != null) state.selectStroke(null);
    pencilPointer = e.pointer;
    state.startStroke(e.localPosition);
  }

  /// The element's menu at [at]: edit, duplicate, add a run, remove — each
  /// the same action the edit bar runs.
  Future<void> _elementMenu(
      TacticsState state, PlayerIcon player, Offset at) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final text = isTextElement(player);
    final edit = player.isBall
        ? 'edit_ball'
        : player.isMarker
            ? 'edit_marker'
            : 'edit_player';
    PopupMenuItem<String> item(String v, IconData icon, String label,
            {Color? tint}) =>
        PopupMenuItem<String>(
          value: v,
          child: Row(children: [
            Icon(icon, size: 19, color: tint ?? T.textDim),
            const SizedBox(width: 12),
            Flexible(
              child: Text(label,
                  style: TextStyle(color: tint ?? T.text, fontSize: 15)),
            ),
          ]),
        );
    final picked = await showMenu<String>(
      context: context,
      color: T.surface,
      position: RelativeRect.fromRect(
          at & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        item('edit', Icons.edit_outlined, edit.tr()),
        item('duplicate', Icons.copy_rounded, 'element_duplicate'.tr()),
        if (!text) item('run', Icons.timeline_rounded, 'move_add'.tr()),
        item('remove', Icons.delete_outline_rounded, 'remove'.tr(),
            tint: T.danger),
      ],
    );
    if (!mounted || picked == null) return;
    switch (picked) {
      case 'edit':
        state.selectPlayer(player.id);
        if (text) state.requestLabelEdit(player.id);
      case 'duplicate':
        state.copyPlayer(player.id);
        final id = state.pastePlayer();
        if (id != null) state.selectPlayer(id);
      case 'run':
        state.selectPlayer(player.id);
        state.setAddingMove(true);
      case 'remove':
        state.removePlayer(player.id);
    }
  }

  void _pencilMove(PointerMoveEvent e, TacticsState state) {
    if (e.pointer != pencilPointer) return;
    state.addPoint(e.localPosition);
  }

  void _pencilUp(PointerEvent e, TacticsState state, {bool cancel = false}) {
    if (e.pointer != pencilPointer) return;
    pencilPointer = null;
    cancel ? state.cancelStroke() : state.endStroke();
  }

  /// Erase any stroke under [p] (drawing-mode eraser sub-mode).
  void _eraseAt(TacticsState state, Offset p) {
    final hit = state.hitTestStroke(p);
    if (hit != null) {
      state.deleteStroke(hit);
      HapticFeedback.selectionClick();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stateOrNull = context.read<TacticsState>();
      _state.addListener(_rebuild);
      _rebuild();
    });
  }

  @override
  void dispose() {
    _state.removeListener(_rebuild);
    pencilPointer = null;
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  CustomPainter _courtPainter(SportType sport) {
    final layout = _state.courtLayout(sport);
    final surface = _state.courtColor(sport);
    switch (sport) {
      case SportType.badminton:
        return BadmintonCourtPainter(layout: layout, surface: surface);
      case SportType.basketball:
        return BasketballCourtPainter(layout: layout, floor: surface);
      case SportType.tennis:
        return TennisCourtPainter(layout: layout, surface: surface);
      case SportType.tableTennis:
        return TableTennisCourtPainter(layout: layout, surface: surface);
      case SportType.volleyball:
        return VolleyballCourtPainter(layout: layout, surface: surface);
      case SportType.pickleball:
        return PickleballCourtPainter(layout: layout, surface: surface);
      case SportType.soccer:
        return SoccerCourtPainter(
          fieldType: _state.soccerFieldType,
          turf: _state.soccerTurf,
          sideways: widget.boardTurns.isOdd,
        );
      case SportType.fieldHockey:
        return FieldHockeyCourtPainter(layout: layout, surface: surface);
      case SportType.rugby:
        return RugbyCourtPainter(layout: layout, surface: surface);
      case SportType.baseball:
        return BaseballCourtPainter(layout: layout, surface: surface);
      case SportType.handball:
        return HandballCourtPainter(layout: layout, surface: surface);
      case SportType.waterPolo:
        return WaterPoloCourtPainter(layout: layout, surface: surface);
      case SportType.sepakTakraw:
        return SepakTakrawCourtPainter(layout: layout, surface: surface);
      case SportType.beachTennis:
        return BeachTennisCourtPainter(layout: layout, surface: surface);
      case SportType.footvolley:
        return FootvolleyCourtPainter(layout: layout, surface: surface);
    }
  }

  /// One element in the exported image. Two passes use it — equipment before
  /// the ghosts, everyone else after — so the PNG layers the way the screen
  /// does.
  Widget _externalIcon(PlayerIcon player) {
    Offset pos = player.position;
    final animSrc = _state.animatedPositions[player.id];
    final sw = _state.canvasSize.width;
    final sh = _state.canvasSize.height;
    // _buildExternalContent bails before it can call this when the canvas has
    // no size, but the check is cheap and an Infinity here would be silent.
    if (animSrc != null && sw > 0 && sh > 0) {
      pos = Offset(animSrc.dx / sw * 540.0, animSrc.dy / sh * 960.0);
    }
    final size = kPlayerIconSize * player.scale;
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: IgnorePointer(
        child: RotatedBox(
          // counter-rotate: canvas is 90° CCW, so icons need 90° CW
          quarterTurns: 1,
          child: PlayerIconWidget(player: player, sport: _state.sportType),
        ),
      ),
    );
  }

  Widget _buildExternalContent() {
    const pw = 540.0;
    const ph = 960.0;
    final sw = _state.canvasSize.width;
    final sh = _state.canvasSize.height;
    if (sw <= 0 || sh <= 0) return const SizedBox(width: 960, height: 540);
    Offset sc(Offset p) => Offset(p.dx / sw * pw, p.dy / sh * ph);
    final players = _inPaintOrder(_state.players);
    final sPlayers = players
        .map(
          (p) => p.copyWith(
            position: sc(p.position),
            moves: p.moves.map(sc).toList(),
          ),
        )
        .toList();
    final sStrokes = _visibleStrokes(
      _state,
      players,
    ).map((s) => s.copyWith(points: s.points.map(sc).toList())).toList();
    // RotatedBox(quarterTurns: 3) = 90° CCW: portrait bottom → landscape left (home side)
    // Its tokens counter-turn by hand below, so the board's own orientation
    // must not reach them or they would turn twice.
    return BoardOrientation(
      quarterTurns: 0,
      child: RotatedBox(
        quarterTurns: 3,
        child: SizedBox(
          width: pw,
          height: ph,
          child: Stack(
            children: [
              CustomPaint(
                painter: _courtPainter(_state.sportType),
                size: const Size(pw, ph),
                child: const SizedBox(width: pw, height: ph),
              ),
              CustomPaint(
                painter: DrawingPainter(
                  strokes: sStrokes,
                  currentStroke: null,
                  selectedStrokeId: null,
                ),
                size: const Size(pw, ph),
              ),
              // Equipment under the ghosts, same as on screen.
              ...sPlayers.where((p) => p.isMarker).map(_externalIcon),
              // Ghost icons at starting positions
              if (_state.showMoveLines)
                ...sPlayers.where((p) => p.moves.isNotEmpty).map((player) {
                  final size = kPlayerIconSize * player.scale;
                  final hasPhoto =
                      player.photoId != null &&
                      !player.isMarker &&
                      !player.isBall;
                  return Positioned(
                    left: player.position.dx - size / 2,
                    top: player.position.dy - size / 2,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: hasPhoto
                          ? PhotoPlayerShape(
                              player: player,
                              isSelected: false,
                              isGhost: true,
                            )
                          : player.isBall
                          ? Opacity(
                              opacity: 0.45,
                              child: Center(
                                child: FractionallySizedBox(
                                  widthFactor: ballDrawFactor(
                                    player.sportType ?? _state.sportType,
                                  ),
                                  heightFactor: ballDrawFactor(
                                    player.sportType ?? _state.sportType,
                                  ),
                                  child: ballWidget(
                                    player.sportType ?? _state.sportType,
                                  ),
                                ),
                              ),
                            )
                          : RotatedBox(
                              quarterTurns: BoardOrientation.counterTurns(
                                context,
                              ),
                              child: CustomPaint(
                                painter: TopDownPlayerPainter(
                                  color: player.color,
                                  borderColor: Colors.white,
                                  borderWidth: 1.5,
                                  gender: player.gender,
                                  figure: TopDownPlayerPainter.figureFor(
                                    _state.sportType,
                                    player,
                                  ),
                                  sport: _state.sportType,
                                  heading: playerFacing(player),
                                  boardTurns: widget.boardTurns,
                                  isGhost: true,
                                ),
                              ),
                            ),
                    ),
                  );
                }),
              // Waypoint dots
              if (!_state.isAnimating && _state.showMoveLines)
                ...sPlayers.expand((player) {
                  return player.moves.asMap().entries.map((entry) {
                    final isLast = entry.key == player.moves.length - 1;
                    final pos = entry.value;
                    if (isLast) {
                      return Positioned(
                        left: pos.dx - kPlayerIconSize / 2,
                        top: pos.dy - kPlayerIconSize / 2,
                        child: IgnorePointer(
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: SizedBox(
                              width: kPlayerIconSize,
                              height: kPlayerIconSize,
                              child:
                                  player.photoId != null &&
                                      !player.isMarker &&
                                      !player.isBall
                                  ? PhotoPlayerShape(
                                      player: player,
                                      isSelected: false,
                                    )
                                  : player.isBall
                                  ? Center(
                                      child: FractionallySizedBox(
                                        widthFactor: ballDrawFactor(
                                          player.sportType!,
                                        ),
                                        heightFactor: ballDrawFactor(
                                          player.sportType!,
                                        ),
                                        child: ballWidget(player.sportType!),
                                      ),
                                    )
                                  : CustomPaint(
                                      painter: player.isMarker
                                          ? MarkerPainter(
                                              shape: player.markerShape,
                                              color: player.color,
                                            )
                                          : TopDownPlayerPainter(
                                              color: player.color,
                                              borderColor: player.moveColor,
                                              borderWidth: 2.5,
                                              gender: player.gender,
                                              figure:
                                                  TopDownPlayerPainter.figureFor(
                                                    _state.sportType,
                                                    player,
                                                  ),
                                              sport: _state.sportType,
                                              heading: playerFacing(player),
                                              boardTurns: widget.boardTurns,
                                            ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }
                    const dotSize = 28.0;
                    return Positioned(
                      left: pos.dx - dotSize / 2,
                      top: pos.dy - dotSize / 2,
                      child: IgnorePointer(
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: player.moveColor,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }),
              ...sPlayers.where((p) => !p.isMarker).map(_externalIcon),
              if (_state.showMoveLines)
                CustomPaint(
                  painter: PlayerMovesPainter(
                    players: sPlayers,
                    sport: _state.sportType,
                    targetStep: _state.atStep > 0
                        ? _state.atStep
                        : _state.targetStep,
                    completedSteps: _state.isAnimating
                        ? (_state.animToStep > _state.animFromStep
                              ? _state.atStep + 1
                              : _state.atStep)
                        : null,
                  ),
                  size: const Size(pw, ph),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_stateOrNull == null) {
      return Container(color: T.surface);
    }
    final state = _state;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Offscreen landscape canvas for external display
        if (!widget.preview)
          Positioned(
            left: -20000,
            top: 0,
            child: RepaintBoundary(
              key: externalRepaintKey,
              child: SizedBox(
                width: 960,
                height: 540,
                child: _buildExternalContent(),
              ),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final canvasW = constraints.maxWidth;
            final canvasH = constraints.maxHeight;
            final newSize = Size(canvasW, canvasH);
            if (state.canvasSize != newSize) {
              state.setCanvasSizeSilent(newSize);
            }
            // The figures' size on this board: grown on a tablet board,
            // the drill's own (a tight scrum) on any, and shrunk by a
            // half's zoom so they keep their size on the screen while the
            // court grows under them. All of it is exactly 1 on a phone.
            gTightFigureScale = state.figureScale;
            gViewZoom = widget.preview ? 1.0 : state.frameZoom;
            gBoardFigureScale = boardFigureScaleFor(newSize,
                    sport: state.sportType, sideways: widget.boardTurns.isOdd) /
                gViewZoom;
            if (!widget.preview && state.frameNeedsApply) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && state.frameNeedsApply) state.applyViewFrame();
              });
            }

            final players = _inPaintOrder(state.players);

            final eraser = state.isDrawingMode && state.eraserMode;
            final pencilAware = MediaQuery.sizeOf(context).shortestSide >= 600;
            final draggingStroke =
                state.isDrawingMode &&
                state.selectedStrokeId != null &&
                !eraser;
            final isAddMove =
                state.isAddingMove && state.selectedPlayerId != null;
            final locked = state.presentationMode;
            // Presentation locks the board and hands every gesture to the
            // InteractiveViewer. Zoom mode mounts the viewer too, but for
            // two fingers only (panEnabled off): one finger still taps,
            // drags and draws on the board — a coach who has zoomed in on
            // the circle wants to work there, and with the board locked
            // under the zoom nothing answered a tap (reported off a phone,
            // 2026-10-17). In normal editing the board carries NO viewer.
            final useViewer = locked || state.zoomMode;

            // Canvas-level single-finger gestures: drawing, erasing,
            // multi-select lasso, or laying a run. All off while the board
            // is locked (presentation).
            final pannable =
                !locked &&
                (state.isDrawingMode || state.multiSelectMode || isAddMove);

            final board = GestureDetector(
              // The line starts where the finger went DOWN. By default a
              // pan reports where it was recognised — past the slop, and a
              // fast first stroke of a mouse or Pencil can be a long way
              // past it — so a straight line set off from nowhere near the
              // point the coach pressed. Reported off an iPad, 2026-10-16.
              dragStartBehavior: DragStartBehavior.down,
              onPanStart: pannable
                  ? (d) {
                      _panIgnored = pencilAware &&
                          (pencilPointer != null ||
                              (d.kind == PointerDeviceKind.stylus &&
                                  state.isDrawingMode &&
                                  !eraser &&
                                  !draggingStroke));
                      if (_panIgnored) return;
                      if (eraser) {
                        _eraseAt(state, d.localPosition);
                      } else if (state.isDrawingMode) {
                        if (draggingStroke) {
                          final hitId = state.hitTestStroke(d.localPosition);
                          if (hitId == state.selectedStrokeId) return;
                          state.selectStroke(null);
                        }
                        state.startStroke(d.localPosition);
                        _touchStroke = pencilAware;
                      } else if (state.multiSelectMode) {
                        // Pan started on a stroke that's already in the
                        // multi-select set → drag the whole group instead
                        // of starting a new lasso. Otherwise, lasso.
                        final hitId = state.hitTestStroke(d.localPosition);
                        if (hitId != null &&
                            state.multiSelectStrokeIds.contains(hitId)) {
                          _multiSelectStrokeDragging = true;
                        } else {
                          _multiSelectStrokeDragging = false;
                          state.beginMultiSelectRect(d.localPosition);
                        }
                      } else if (isAddMove) {
                        _addMovePanPos = d.localPosition;
                      }
                    }
                  : null,
              onPanUpdate: pannable
                  ? (d) {
                      if (_panIgnored) return;
                      if (eraser) {
                        _eraseAt(state, d.localPosition);
                      } else if (state.isDrawingMode) {
                        if (draggingStroke) {
                          state.moveStroke(state.selectedStrokeId!, d.delta);
                        } else {
                          state.addPoint(d.localPosition);
                        }
                      } else if (state.multiSelectMode) {
                        if (_multiSelectStrokeDragging) {
                          state.moveMultiSelectBy(d.delta);
                        } else {
                          state.updateMultiSelectRect(d.localPosition);
                        }
                      } else if (isAddMove) {
                        _addMovePanPos = d.localPosition;
                      }
                    }
                  : null,
              onPanEnd: pannable
                  ? (_) {
                      _touchStroke = false;
                      if (_panIgnored) {
                        _panIgnored = false;
                        return;
                      }
                      if (eraser) {
                        return;
                      } else if (state.isDrawingMode) {
                        if (draggingStroke) {
                          state.moveStrokeEnd(state.selectedStrokeId!);
                        } else {
                          state.endStroke();
                        }
                      } else if (state.multiSelectMode) {
                        if (_multiSelectStrokeDragging) {
                          state.moveMultiSelectEnd();
                          _multiSelectStrokeDragging = false;
                        } else {
                          state.endMultiSelectRect();
                        }
                      } else if (isAddMove && _addMovePanPos != null) {
                        state.addPlayerMove(
                          state.selectedPlayerId!,
                          _addMovePanPos!,
                        );
                        HapticFeedback.selectionClick();
                        _addMovePanPos = null;
                      }
                    }
                  : null,
              onTapUp: (!state.isAnimating && !locked)
                  ? (d) {
                      if (state.multiSelectMode) {
                        // In select mode: hit a stroke → toggle its membership;
                        // hit truly empty canvas → clear the whole selection.
                        // Player taps go through the per-player onTap, so they
                        // don't reach here.
                        final hitId = state.hitTestStroke(d.localPosition);
                        if (hitId != null) {
                          state.toggleMultiSelectStroke(hitId);
                        } else if (state.hasMultiSelection) {
                          state.clearMultiSelect();
                        }
                      } else if (state.isDrawingMode) {
                        if (eraser) {
                          _eraseAt(state, d.localPosition);
                        } else {
                          final hitId = state.hitTestStroke(d.localPosition);
                          state.selectStroke(hitId);
                        }
                      } else if (isAddMove) {
                        // Explicit add-run sub-mode: a tap appends a waypoint.
                        state.addPlayerMove(
                          state.selectedPlayerId!,
                          d.localPosition,
                        );
                        HapticFeedback.selectionClick();
                      } else {
                        // Plain move mode: tapping a stroke selects it;
                        // tapping truly empty canvas clears any selection
                        // (it never silently creates content).
                        final hitId = state.hitTestStroke(d.localPosition);
                        if (hitId != null) {
                          state.selectStroke(hitId);
                        } else {
                          state.selectPlayer(null);
                          state.selectStroke(null);
                        }
                      }
                    }
                  : null,
              child: IgnorePointer(
                ignoring: locked,
                child: BoardOrientation(
                  quarterTurns: widget.boardTurns,
                  // Keyed by the figure scale: the painters compare their
                  // players, not the scale, so a board whose figures change
                  // size (a half zoomed in, a rotation across the tablet
                  // threshold) is built afresh rather than half-repainted.
                  child: KeyedSubtree(
                    key: ValueKey(kFigureScale),
                    child: _buildCanvasContent(state, players, canvasW, canvasH),
                  ),
                ),
              ),
            );

            final wrapped = RepaintBoundary(
              key: widget.preview ? null : boardRepaintKey,
              child: SizedBox(
                width: canvasW,
                height: canvasH,
                child: pencilAware && !widget.preview
                    ? Listener(
                        onPointerDown: (e) => _pencilDown(e, state),
                        onPointerMove: (e) => _pencilMove(e, state),
                        onPointerUp: (e) => _pencilUp(e, state),
                        onPointerCancel: (e) =>
                            _pencilUp(e, state, cancel: true),
                        child: board,
                      )
                    : board,
              ),
            );
            // Only mount the InteractiveViewer while zooming/presenting; in
            // normal editing apply any existing zoom statically (no gesture
            // recogniser) so player drags are never intercepted. The static
            // wrapper listens to the controller so a half-court / reset tap
            // repaints the board immediately, not on the next rebuild.
            return useViewer
                ? InteractiveViewer(
                    transformationController: state.transformationController,
                    // Zoom mode: two fingers pinch and move the view, one
                    // finger is the board's. A presentation pans with one.
                    panEnabled: locked,
                    scaleEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: wrapped,
                  )
                : ValueListenableBuilder<Matrix4>(
                    valueListenable: state.transformationController,
                    builder: (_, matrix, child) => Transform(
                      transform: matrix,
                      transformHitTests: true,
                      child: child,
                    ),
                    child: wrapped,
                  );
          },
        ),
      ],
    );
  }

  Widget _buildCanvasContent(
    TacticsState state,
    List<PlayerIcon> players,
    double canvasW,
    double canvasH,
  ) {
    // Beats elapsed, whichever way the board is being stepped: atStep when
    // played in the app, targetStep when a tool shoots a frame.
    // The beat on show. At rest it is the beat the stepper is parked on.
    // While a beat plays it is the one being played — atStep is the beats
    // already done, so going forward it is the next one — which is the
    // number PlayerMovesPainter is given as completedSteps. The ghosts and
    // the ball's start were still taking atStep, one beat behind the
    // arrows: during the second beat the pass line set off from a start
    // shifted for the first beat's holder, and the ghost ball stood where
    // the ball had been a beat earlier.
    //
    // Never past the step being stepped to. When a single step completes,
    // the driver counts the beat done and the state is rebuilt once more
    // before the animation flag drops: for that frame "the next beat" was
    // the one after the target, and its ghosts and arrows — C's run, on
    // the beat after the pass — appeared and vanished. Rewinding, never
    // below the first beat, or the last frame of a rewind to the start
    // drew the whole plan.
    final stepLimit = state.isAnimating
        ? (state.animToStep > state.animFromStep
              ? math.min(state.atStep + 1, state.animToStep)
              : math.max(state.atStep, 1))
        : (state.atStep > 0
              ? state.atStep
              : (state.targetStep > 0 ? state.targetStep : 0));
    // Where a token that is not being animated STANDS: after the beats
    // done, not the beat on show. They differ only while a beat plays, and
    // for the frame between one beat completing and the next one's first
    // tick — when nobody is in animatedPositions yet — a player who moves
    // on the coming beat was drawn at the end of it and then snapped back
    // to its start: C and X6 flashing across the pitch at the end of beat
    // one, a beat before they run.
    final restLimit = state.atStep > 0
        ? state.atStep
        : (state.targetStep > 0 ? state.targetStep : 0);

    /// Where [p] is drawn this frame: along its run while the beat plays,
    /// else where the beats so far have taken it — the same answer as the
    /// renderPosition playerIcon hands the token. Not `p.position`, which
    /// is where the board STARTS: measured from there, a ball at the feet
    /// of a man who had run up the pitch was drawn at the feet of the ghost
    /// he left behind.
    Offset drawnAt(PlayerIcon p) =>
        state.animatedPositions[p.id] ??
        (restLimit > 0 && p.moves.isNotEmpty
            ? chainEndAt(p, restLimit)
            : p.position);

    // Players standing in the same place get nudged apart in the drawing.
    // Computed from the positions actually on screen, so it follows the
    // animation as tokens converge rather than only the stored board.
    final fan = fanOutOffsets(players, drawnAt);
    // A held ball is drawn at its holder's feet — measured from where the
    // holder is actually drawn, so a ball follows a player the fan has
    // pushed aside rather than being left where the pair used to stand.
    /// Which way [p] faces as of beat [beat]: locked, else at his next
    /// action, else his team's way. The same answer the figure is drawn
    /// with, so the ball goes where the man is looking.
    double headingAt(PlayerIcon p, int beat) => p.facingLocked
        ? playerFacing(p)
        // The net fold goes on the OUTSIDE of the ?? — the fallback is a
        // heading too, and the generator's opening stance is where these
        // boards get theirs: a badminton player is posed at 135 degrees,
        // facing down the court, and a beat with no cue of its own left
        // him standing like that with his back to the net.
        : faceAcrossNet(
            boardHeading(players, p, beat) ?? playerFacing(p),
            p,
            _state.sportType,
            standingAt(p, beat),
            _state.canvasSize,
            ball: ballStandingAt(players, beat),
            ballFrom: ballStandingAt(players, beat - 1),
          );
    // "Playing" is stricter than isAnimating: the flag goes up a frame
    // before the driver has placed anything, and for that one frame the
    // board still looks exactly like the rest frame before it. Reading the
    // beat-on-show there handed the ball to the NEXT holder — a stride or a
    // pitch away, so the pull to his foot was nearly nothing — and the ball
    // hopped from the passer's boot back to its raw spot, then flew. Every
    // step from 0 opened with that flash.
    final playing = state.isAnimating && state.animatedPositions.isNotEmpty;
    final restBeat = playing ? stepLimit : restLimit;
    final holders = <String, PlayerIcon>{};
    final feet = {
      ...ballAtFeetOffsets(
        players,
        (p) => drawnAt(p) + (fan[p.id] ?? Offset.zero),
        boardTurns: widget.boardTurns,
        holderOf: (b) => ballHolderAt(b, restBeat),
        sport: state.sportType,
        court: state.sportType.fieldRect(state.canvasSize),
        intoHolders: holders,
        settled: !playing,
        headingOf: (p) => headingAt(p, restBeat),
      ),
    };
    // Paint order is depth: where each thing touches the ground, measured
    // down the SCREEN (the figures stand upright whichever way the board is
    // turned, so this is a screen direction — see turnVector). A figure's
    // shoes are 0.70 of a box below its middle and a ball's underside 0.26;
    // measured off the art, see tool/ink_probe.dart.
    //
    // A held ball is placed by its holder rather than measured: just in
    // front of him while he faces the screen, just behind him once he has
    // turned his back — the ball is then against a chest pointing into the
    // board, and painted over him it read as stuck to his shoulder blades.
    // Everyone else still compares with the ball by true depth, so a
    // defender a stride nearer the viewer than the man on the ball covers
    // it, as he would.
    double contactOf(PlayerIcon p) =>
        turnVector(
          drawnAt(p) + (fan[p.id] ?? Offset.zero),
          widget.boardTurns,
        ).dy +
        kPlayerIconSize * 0.70 * p.scale;
    double depthOf(PlayerIcon p) {
      if (!p.isBall) return contactOf(p);
      final h = holders[p.id];
      if (h == null) {
        return turnVector(
              drawnAt(p) + (feet[p.id] ?? Offset.zero),
              widget.boardTurns,
            ).dy +
            kPlayerIconSize * 0.26 * p.scale;
      }
      return contactOf(h) +
          (facesAwayOnScreen(headingAt(h, restBeat), widget.boardTurns)
              ? -0.5
              : 0.5);
    }

    players = _inPaintOrder(players, depthOf);

    /// Whether [p]'s name badge, hung under his feet, would land on the
    /// head of somebody painted over him. The badge is 13pt tall, 30pt
    /// below the middle; a figure's head is the top 18pt of ink, 24pt
    /// above its middle; both measured on the screen, where the figures
    /// stand upright. Only a NEARER figure matters — a farther one is
    /// painted first and the badge covers it, which is the normal case of
    /// a label over the grass behind.
    bool badgeOnAHead(PlayerIcon p) {
      if (p.isBall || p.isMarker || p.label.isEmpty || p.labelInside) {
        return false;
      }
      final at = turnVector(
        drawnAt(p) + (fan[p.id] ?? Offset.zero),
        widget.boardTurns,
      );
      final badge = Rect.fromCenter(
        center: at +
            Offset(0, (kPlayerIconSize * 0.5 + 11.7 * kFigureScale) * p.scale),
        width: 26 * p.scale * kFigureScale,
        height: 13 * p.scale * kFigureScale,
      );
      final mine = depthOf(p);
      for (final q in players) {
        if (identical(q, p) || q.isBall || q.isMarker) continue;
        if (depthOf(q) <= mine) continue;
        final qa = turnVector(
          drawnAt(q) + (fan[q.id] ?? Offset.zero),
          widget.boardTurns,
        );
        final head = Rect.fromLTRB(
          qa.dx - 12 * q.scale * kFigureScale,
          qa.dy - 24 * q.scale * kFigureScale,
          qa.dx + 12 * q.scale * kFigureScale,
          qa.dy - 6 * q.scale * kFigureScale,
        );
        if (badge.overlaps(head)) return true;
      }
      return false;
    }

    // Equipment a player is standing in front of, lifted clear of them.
    final clear = markerClearOffsets(
      players,
      (p) => drawnAt(p) + (fan[p.id] ?? Offset.zero),
      boardTurns: widget.boardTurns,
    );

    /// The beats elapsed as far as [p] is concerned.
    ///
    /// Zero — the whole plan — for the element being followed, matching the
    /// route PlayerMovesPainter draws for it. Without this the followed
    /// element got its whole route and a ghost from the beat on show, so on
    /// any beat but its own the arrow set off from a patch of empty grass:
    /// the run was drawn and the man who made it was not.
    /// Whether [p]'s route is drawn at all.
    ///
    /// Beat zero is a picture of where everybody stands, so it draws no
    /// routes — unless the coach asked for the plan, or is following this
    /// element, which is the other way of asking for exactly one route.
    bool routeShown(PlayerIcon p) {
      // Not `showMoveLines` first: on beat zero that flag is not the one
      // the button writes, so reading it here made the button dead — turn
      // routes off on beat three, step back to zero, and nothing could turn
      // them on again.
      if (stepLimit > 0 || state.isAnimating) return state.showMoveLines;
      return state.showPlanAtStart || state.selectedPlayerId == p.id;
    }

    int limitFor(PlayerIcon p) =>
        (!state.isAnimating &&
            state.selectedPlayerId == p.id &&
            p.moves.isNotEmpty)
        ? 0
        : stepLimit;

    /// Where a ghost stands: the spot the beat on show starts from.
    Offset ghostStart(PlayerIcon p) => stepStart(p, limitFor(p));

    /// Feet offsets for the ghosts: the whole picture as the leg BEGAN.
    ///
    /// The ball alone used to be pinned to the start of its leg while
    /// everybody else was taken from where they are drawn this frame. The
    /// offset depends on which player is nearest and how far away they are,
    /// so as the passer ran off, the tail of the pass line slid after him —
    /// up to 24.7 points across the shipped libraries, on a line whose
    /// start had not moved at all.
    ///
    /// A pass starts where it started, which means everyone standing where
    /// they stood when it did.
    // Two players who set off from the same spot leave two ghosts on one
    // point — B and X1 both stepped off the same yard and their ghosts
    // stacked into one faded blur. The same nudge the live players get.
    final ghostFan = fanOutOffsets(
      players.where((p) => !p.isBall && p.moves.isNotEmpty).toList(),
      ghostStart,
    );
    final ghostFeet = ballAtFeetOffsets(
      players,
      (p) => p.isBall ? ghostStart(p) : stepStart(p, limitFor(p)),
      boardTurns: widget.boardTurns,
      // As the leg began: whoever had it after the beat before.
      holderOf: (b) => ballHolderAt(b, limitFor(b) - 1),
      sport: state.sportType,
      court: state.sportType.fieldRect(state.canvasSize),
      // A trace is a rest frame by definition — the spot the leg set off
      // from, with the ball on that man's boot.
      settled: true,
      headingOf: (p) => headingAt(p, limitFor(p) - 1),
    );

    // While a beat plays the ball is between two holders: it leaves one
    // man's boots and arrives at another's, and the rest frames on either
    // side draw it at those boots. One holder for the whole flight cannot
    // match both: at frame one the ball hopped off the boot it had been
    // drawn on, and at the last frame it hopped onto the boot it reached.
    // So each frame's step is a blend, by how far along the leg the ball
    // is, of the step for the man it left and the step for the man it is
    // going to — which is what a pass looks like.
    //
    // Both steps are taken from the REST frames, not measured afresh where
    // the ball happens to be: the step to a man's feet is an absolute
    // target, so measured every frame it cancelled the ball's own motion —
    // a shot sat pinned to the striker's boot for a quarter of a second
    // while its route ran on ahead, then caught up in a jump, and was
    // tugged toward whoever it flew past on the way. Taken once at each
    // end and blended, the ball leaves the boot the moment the beat does.
    if (state.isAnimating) {
      for (final ball in players) {
        if (!ball.isBall) continue;
        final at = state.animatedPositions[ball.id];
        if (at == null) continue;
        final leg = ballLegAt(ball, at);
        if (leg == null) continue;
        final after = leg.phase + 1;
        final from = ghostFeet[ball.id] ?? Offset.zero;
        // The spot it is flying TO is the rest frame of the beat after —
        // the same call, with the same answers, that draws that frame once
        // the beat is over: settled, and ahead of the receiver along the
        // way he will be facing. Worked out without those it aimed at a
        // different spot, and the ball landed there and then hopped to its
        // foot when the beat was counted.
        final to =
            ballAtFeetOffsets(
              players,
              (p) => chainEndAt(p, after),
              boardTurns: widget.boardTurns,
              holderOf: (b) => ballHolderAt(b, after),
              sport: state.sportType,
              court: state.sportType.fieldRect(state.canvasSize),
              settled: true,
              headingOf: (p) => headingAt(p, after),
            )[ball.id] ??
            Offset.zero;
        feet[ball.id] = Offset.lerp(from, to, leg.t)!;
      }
    }

    /// One element on the board. Shared by the two passes below so a
    /// marker and a player are built exactly the same way — only when
    /// they are painted differs.
    Widget playerIcon(PlayerIcon player) {
      final animPos = state.animatedPositions[player.id];
      final inMulti =
          state.multiSelectMode && state.multiSelectIds.contains(player.id);
      final selected = state.selectedPlayerId == player.id || inMulti;
      final atStartTime = state.atStep == 0 && state.targetStep == 0;
      // A player whose phases start AFTER the current step
      // hasn't moved yet — their start position is still their
      // current position, so don't hide the icon as a "past
      // ghost". Without this, players whose first phase is
      // later than atStep silently disappear from the board.
      bool hasStartedMoving = false;
      final phaseLimit = state.atStep > 0
          ? state.atStep
          : (state.targetStep > 0 ? state.targetStep : 0);
      if (phaseLimit > 0 && player.moves.isNotEmpty) {
        player.syncPhases();
        for (int i = 0; i < player.moves.length; i++) {
          final ph = i < player.movePhases.length ? player.movePhases[i] : i;
          if (ph < phaseLimit) {
            hasStartedMoving = true;
            break;
          }
        }
      }
      // A token carried by the beat faces down its run; everyone else
      // faces their next action as of the beat on show — the one being
      // played, not the beats done. In the last few frames of a run the
      // token counts as arrived, and it took the stance of the beat BEFORE
      // the one it had just run: F turned to face the ball where it had
      // been, then turned back when the beat was counted. A flash at the
      // end of every step, on every runner.
      final beat = state.isAnimating ? stepLimit : phaseLimit;
      final moving =
          animPos != null &&
          (animPos - chainEndAt(player, state.atStep)).distance > 0.5;
      final heading = player.facingLocked
          ? playerFacing(player)
          // In motion too: a table tennis player steps back from the table
          // facing it; drawn along his travel he spun round mid-step.
          : moving && !squareToNet(state.sportType)
          ? playerHeadingAt(player, animPos)
          : faceAcrossNet(
              boardHeading(players, player, beat) ?? playerFacing(player),
              player,
              state.sportType,
              standingAt(player, beat),
              state.canvasSize,
              ball: ballStandingAt(players, beat),
              ballFrom: ballStandingAt(players, beat - 1),
            );
      return _PlayerOnBoard(
        key: ValueKey(player.id),
        player: player,
        heading: heading,
        labelAbove: badgeOnAHead(player),
        // With no animation running (a shot frame) the token still stands
        // where the beats so far have taken it, solid — the same place the
        // animated token would be. Left at its start it read as a player
        // who had not moved, once the earlier legs stopped being drawn.
        renderPosition:
            animPos ??
            (restLimit > 0 && player.moves.isNotEmpty
                ? chainEndAt(player, restLimit)
                : null),
        drawOffset:
            (fan[player.id] ?? Offset.zero) +
            (feet[player.id] ?? Offset.zero) +
            (clear[player.id] ?? Offset.zero),
        isSelected: selected,
        isPrimary:
            selected &&
            !state.multiSelectMode &&
            state.selectedWaypointIndex == null,
        isAtCurrentStep: atStartTime || !hasStartedMoving,
        isDrawingMode: state.isDrawingMode || state.isAnimating,
        isMultiSelectMode: state.multiSelectMode,
        isInMultiSelect: inMulti,
        onTap: () {
          if (state.multiSelectMode) {
            state.toggleMultiSelectId(player.id);
          } else if (isTextElement(player)) {
            // One tap selects and KEEPS it selected; a second within the
            // double-tap window opens the words to be rewritten.
            //
            // Counted here rather than with a double-tap recogniser, because
            // a GestureDetector that has one holds every single tap back for
            // the whole window to see whether a second is coming — and a
            // selection that lands a third of a second late feels broken.
            // A tap here is answered at once; only the second one knows it
            // was a second one.
            final now = DateTime.now();
            final again = _lastTextTapId == player.id &&
                _lastTextTapAt != null &&
                now.difference(_lastTextTapAt!) < kDoubleTapTimeout;
            _lastTextTapId = player.id;
            _lastTextTapAt = now;
            state.selectPlayer(player.id);
            if (again) state.requestLabelEdit(player.id);
          } else {
            state.selectPlayer(selected ? null : player.id);
          }
        },
        // Tapping a player selects it — the floating edit bar
        // then appears, so a separate long-press dialog is no
        // longer needed (one unified edit surface).
        onLongPress: null,
        // Right-click (and a tablet's long press): the same actions the
        // edit bar has, where the pointer is.
        onContextMenu: state.multiSelectMode ||
                state.isAnimating ||
                state.presentationMode
            ? null
            : (at) => _elementMenu(state, player, at),
        // Only a rotation board (volleyball) watches its drags: the patch
        // of court the player under the finger may stand on.
        onDragStart: state.rotation == null
            ? null
            : () {
                if (_rotationDragId == player.id || !mounted) return;
                setState(() => _rotationDragId = player.id);
              },
        onDragEnd: state.rotation == null
            ? null
            : () {
                if (_rotationDragId != player.id || !mounted) return;
                setState(() => _rotationDragId = null);
              },
      );
    }

    PlayerMovesPainter routes(RouteLayer layer) => PlayerMovesPainter(
      layer: layer,
      // Down the screen, in the board's coordinates:
      // the figures' feet are that way whichever way
      // the board is turned.
      footward: turnVector(const Offset(0, 1), (4 - widget.boardTurns) % 4),

      players: players,
      sport: state.sportType,
      // Selecting an element follows it: see
      // PlayerMovesPainter.focusId. Only on the board —
      // the external display is what a room is watching,
      // and it must not dim because someone touched the
      // phone.
      focusId: state.selectedPlayerId,
      // The figures' own nudge as well as the balls'
      // feet: a line has to end where the token is drawn.
      endShift: {...fan, ...feet},
      startShift: {...ghostFan, ...ghostFeet},
      // Only while animating: at rest the ball IS at the
      // leg's end and endShift is the right answer.
      // Every ball, from the first animating frame: a
      // ball the driver has not placed yet is where it
      // rests, so its line is zero long and grows, rather
      // than drawn whole to the receiver for one frame
      // and then snapped back to the ball.
      livePos: state.isAnimating
          ? {
              for (final p in players)
                if (p.isBall)
                  p.id:
                      (state.animatedPositions[p.id] ?? drawnAt(p)) +
                      (feet[p.id] ?? Offset.zero),
            }
          : const {},
      // Beat zero draws nothing but the one route a
      // coach asked for — see routeShown above.
      onlyFocus: stepLimit == 0 && !state.isAnimating && !state.showPlanAtStart,
      targetStep: state.atStep > 0 ? state.atStep : state.targetStep,
      // The leg being run is the one to draw: going
      // forward that is the beat after the ones done.
      // The same number the ghosts use, and clamped
      // the same way.
      completedSteps: state.isAnimating ? stepLimit : null,
    );

    return Stack(
      children: [
        // Court background
        CustomPaint(
          painter: _courtPainter(state.sportType),
          size: Size(canvasW, canvasH),
          child: SizedBox(width: canvasW, height: canvasH),
        ),
        // Drawing layer (filter by phase during step playback). In the
        // board's own frame, like the court under it: a line is a mark on
        // the floor and turns with the floor. It was counter-turned here,
        // the way the figures are so they stay upright — and a 900x1360
        // layer turned a quarter inside a 900x1360 box is laid out
        // sideways, so on an iPad turned sideways every line was drawn
        // turned 90° from where it was traced, and from where it is hit-
        // tested (hitTestStroke works in the board's frame). Reported off
        // an iPad, 2026-10-16.
        CustomPaint(
          painter: DrawingPainter(
            strokes: _visibleStrokes(state, players),
            currentStroke: state.currentStroke,
            selectedStrokeId: state.selectedStrokeId,
            multiSelectStrokeIds: state.multiSelectStrokeIds,
          ),
          size: Size(canvasW, canvasH),
        ),
        // Equipment first — under the ghosts as well as under
        // the live tokens. Reordering only the icon pass left a
        // hurdle on top of the faint start-position marker of the
        // player it belongs to.
        ...players.where((p) => p.isMarker).map(playerIcon),
        // Ghost icons at initial positions for players with moves.
        // Under the waypoint layer: the dashed ghost is where a
        // player WAS, the end-of-run icon is where someone IS, and
        // when a runner takes the very spot another player just
        // left (every rotation drill) the ghost used to paint over
        // him, so the board showed the man who had gone instead of
        // the man who arrived.
        ...players
            .where((p) => p.moves.isNotEmpty && routeShown(p))
            .where((p) {
              // The ball leaves a trace at the spot its leg began,
              // at the feet of whoever played it: without one the
              // pass arrow sets off from bare grass and the board
              // never says where the ball came from. While it is
              // playing the trace appears the moment the ball has
              // left the spot, the same as a runner's — it used to
              // wait for the beat to end, so the ball flew from
              // bare grass and its start was drawn in afterwards.
              // Not before it has left, though: under the live ball
              // the two are one ball drawn twice.
              if (p.isBall && state.isAnimating) {
                final at = state.animatedPositions[p.id];
                if (at == null) return false;
                if ((at - ghostStart(p)).distance < kPlayerIconSize * 0.2) {
                  return false;
                }
              }
              // A ghost the ball lands on is not drawn. A player who
              // steps forward to receive leaves his ghost a stride
              // behind him — exactly where the ball arrives at his
              // feet — and the ball then sat on the ghost's head: a
              // man under a ball. The dashed run from that spot to
              // the live player already says where he came from.
              // Measured on the screen, where the figure stands
              // upright: the figure's own ink — 14pt either side, 24
              // up and 26 down of the ghost's middle — grown by the
              // ball's radius, so touching counts: a ball resting
              // against a ghost's head is a ball on a head too.
              // Only for a stride, though. The rule above is about
              // a man who stepped a yard forward and left his ghost
              // under the ball; where the run is long the ghost is
              // the only thing saying where it began, and dropping
              // it left a dashed arrow coming out of bare court with
              // nobody at its tail — a multi-shuttle board, the
              // player sent corner to corner from a base the
              // shuttle happens to rest on.
              if (!p.isBall &&
                  (drawnAt(p) - ghostStart(p)).distance <
                      kPlayerIconSize * 1.5 * p.scale) {
                final gs = ghostStart(p);
                for (final b in players) {
                  if (!b.isBall) continue;
                  final r =
                      kPlayerIconSize *
                      ballDrawFactor(b.sportType ?? _state.sportType) /
                      2 *
                      b.scale;
                  final d = turnVector(
                    drawnAt(b) + (feet[b.id] ?? Offset.zero) - gs,
                    widget.boardTurns,
                  );
                  final k = p.scale * kFigureScale;
                  if (d.dx.abs() <= 14 * k + r &&
                      d.dy >= -24 * k - r &&
                      d.dy <= 26 * k + r) {
                    return false;
                  }
                }
              }
              // Mirror of the rule above, the other way round: once
              // the run has been played the end icon is the live one,
              // and a ghost less than a token away only covers it.
              final limit = limitFor(p);
              if (limit == 0) return true;
              // Only the beat on show leaves a ghost, at the spot its
              // leg starts from; a player standing still this beat
              // has nothing to be a ghost of.
              final legs = stepLegs(p, limit);
              if (legs.isEmpty) return false;
              // For a ball, measure where the two are DRAWN, not how
              // far the leg is. A ball is pulled to its holder's
              // feet, so a handoff — where it changes hands without
              // travelling — moves it six points on paper and a
              // stride on the board. Judged on the leg it failed the
              // threshold and no trace was drawn at all: the board
              // said "1 hands it off to 2" with the ball already at
              // 2 and nothing to say it had ever been at 1.
              if (p.isBall) {
                final ghostAt =
                    stepStart(p, limit) + (ghostFeet[p.id] ?? Offset.zero);
                final liveAt = drawnAt(p) + (feet[p.id] ?? Offset.zero);
                // Ball, man, ball. A shot ends over the shooter's
                // head while his trace from the catch is still at
                // his hip, so one figure carries two balls and the
                // arrow that joins them runs behind him — the board
                // reads as two balls rather than one going up. The
                // same ink box as the rule above, on the screen.
                final r =
                    kPlayerIconSize *
                    ballDrawFactor(p.sportType ?? _state.sportType) /
                    2 *
                    p.scale;
                for (final man in players) {
                  if (man.isBall || man.isMarker) continue;
                  final mid = drawnAt(man);
                  bool on(Offset at) {
                    final d = turnVector(at - mid, widget.boardTurns);
                    final k = man.scale * kFigureScale;
                    return d.dx.abs() <= 14 * k + r &&
                        d.dy >= -24 * k - r &&
                        d.dy <= 26 * k + r;
                  }

                  if (on(ghostAt) && on(liveAt)) return false;
                }
                return (liveAt - ghostAt).distance >= nudgeThreshold(p);
              }
              return (legs.last.value - stepStart(p, limit)).distance >=
                  nudgeThreshold(p);
            })
            .map((player) {
              final size = kPlayerIconSize * player.scale;
              // At the feet of whoever played it, the same as a live
              // ball; the raw spot is a token's length ahead of them,
              // which on a standing figure is their head.
              final ghostAt =
                  ghostStart(player) +
                  (player.isBall
                      ? ghostFeet[player.id] ?? Offset.zero
                      : ghostFan[player.id] ?? Offset.zero);
              final hasPhoto =
                  player.photoId != null && !player.isMarker && !player.isBall;
              return Positioned(
                key: ValueKey('ghost_${player.id}'),
                left: ghostAt.dx - size / 2,
                top: ghostAt.dy - size / 2,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: hasPhoto
                      ? PhotoPlayerShape(
                          player: player,
                          isSelected: false,
                          isGhost: true,
                        )
                      // A moving ball leaves a ghost too, and until
                      // the ball could move nothing exercised this
                      // branch for one — the person-shaped ghost
                      // painter drew a small grey figure where the
                      // pass starts.
                      : player.isBall
                      ? Opacity(
                          opacity: 0.45,
                          child: Center(
                            child: FractionallySizedBox(
                              widthFactor: ballDrawFactor(
                                player.sportType ?? _state.sportType,
                              ),
                              heightFactor: ballDrawFactor(
                                player.sportType ?? _state.sportType,
                              ),
                              child: ballWidget(
                                player.sportType ?? state.sportType,
                              ),
                            ),
                          ),
                        )
                      : RotatedBox(
                          quarterTurns: (4 - widget.boardTurns) % 4,
                          child: Stack(
                            children: [
                              CustomPaint(
                                painter: TopDownPlayerPainter(
                                  color: player.color,
                                  borderColor: Colors.white,
                                  borderWidth: 2,
                                  gender: player.gender,
                                  figure: TopDownPlayerPainter.figureFor(
                                    state.sportType,
                                    player,
                                  ),
                                  sport: state.sportType,
                                  // A ghost obeys the net too: on
                                  // a badminton board the trace left
                                  // at the rear corner is a man who
                                  // had turned his back on it.
                                  heading: faceAcrossNet(
                                    playerFacing(player),
                                    player,
                                    state.sportType,
                                    ghostStart(player),
                                    state.canvasSize,
                                    ball: ballStandingAt(players, 0),
                                  ),
                                  boardTurns: widget.boardTurns,
                                  isGhost: true,
                                ),
                                size: Size.infinite,
                              ),
                              // The number sits on the shirt, the same
                              // place and the same size as on the live
                              // token — centred in the box it landed on
                              // the neck, half over the head, so the
                              // ghost's number and the player's number
                              // read as two different marks.
                              if (player.labelInside)
                                Align(
                                  alignment: playerLabelAlign(
                                    state.sportType,
                                    player,
                                  ),
                                  child: Text(
                                    player.label,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      fontSize:
                                          15 * player.scale * kFigureScale,
                                      height: 1,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              );
            }),
        // Waypoint dots — stay visible through animation so each
        // step-forward tap doesn't flash every middle dot off and
        // back on. The phaseLimit filter (driven by atStep) still
        // hides phases that haven't started yet.
        ...players.where(routeShown).expand((player) {
          // The legs of the beat on show, keyed by their index
          // in the chain so a dot still selects its own waypoint.
          //
          // The same limit the routes and the ghosts take (limitFor):
          // a followed element's route is drawn whole past beat zero,
          // and its dots went on showing the beat alone — five legs of
          // arrows turning on bare court, with no stop and no end
          // figure on any of them. Reported off an iPad, 2026-10-16.
          final limit = limitFor(player);
          final legs = stepLegs(player, limit);
          final from = stepStart(player, limit);
          final atStartTime = state.atStep == 0 && state.targetStep == 0;
          // A ball riding along with the players keeps only its
          // final dot — that one IS the ball at its current spot.
          // The intermediate numbered badges marked stops the
          // players' own chains already mark, one more disc on
          // every cone.
          final ballEscorted =
              player.isBall && ballTravelsWithPlayers(player, players);
          // At step 0 the solid token is still at the start, so
          // a run shorter than the token would drop the faded end
          // icon straight on top of it — the same player drawn
          // twice. The nudge arrow carries the direction instead.
          final shortRun =
              legs.isNotEmpty &&
              (legs.last.value - from).distance < nudgeThreshold(player);
          final chainSelected = state.selectedPlayerId == player.id;
          return legs
              .where((entry) {
                final isEnd = entry.key == legs.last.key;
                // While the ball is in flight its own token says
                // where it is; a badge on the raw point it is
                // heading for sits a stride from where it will be
                // drawn — a ring on the grass that turns out to be
                // nothing.
                if (player.isBall && state.isAnimating) return false;
                if (shortRun && atStartTime && isEnd) return false;
                // While the board is playing, the token is on its
                // way to this spot. A faded copy of it waiting there
                // is the same player drawn twice, and standing next
                // to somebody else's token it reads as a player who
                // has already arrived: press play on a rotation and
                // a pale A appears beside B before anybody has moved.
                if (state.isAnimating && atStartTime && isEnd) {
                  return false;
                }
                // Past beat zero the live token itself stands at
                // the end of the leg — renderPosition put it there
                // — so the end copy, which is promoted to a solid
                // figure once the timeline has moved, is the same
                // player drawn twice. Not quite on top of each
                // other, either: the copy takes the stance the
                // player has after every beat, the token the one
                // for this beat, and where the two differ a second
                // stick and a second pair of boots show from behind
                // — a coach read it as two men in one place. The
                // promotion is older than renderPosition and was
                // standing in for a token that used to stay at its
                // start. The copy is kept while its chain is
                // selected, where it is the handle for the waypoint.
                if (isEnd && !player.isBall && !atStartTime && !chainSelected) {
                  return false;
                }
                // On the whole route the stop the token has reached
                // this beat is under the token; a disc there peeked
                // out round his boots like a second ring.
                if (limit != stepLimit &&
                    !isEnd &&
                    entry.value == chainEndAt(player, restLimit)) {
                  return false;
                }
                if (!ballEscorted) return true;
                return isEnd;
              })
              .map((entry) {
                final isLast = entry.key == legs.last.key;
                return _WaypointDot(
                  key: ValueKey('wp_${player.id}_${entry.key}'),
                  player: player,
                  index: entry.key,
                  // The last dot of a ball IS the ball, drawn a
                  // second time over the live token. It has to take
                  // the same step to the feet, or the board shows two
                  // balls — one at the player's boots and one on his
                  // head, which is where the pair used to overlap.
                  position:
                      entry.value +
                      (player.isBall && isLast
                          ? feet[player.id] ?? Offset.zero
                          : Offset.zero),
                  // A person's turning point sits where the line
                  // does, at his feet. The last dot is the figure
                  // itself and stays on its middle.
                  drawOffset: (!player.isBall && !player.isMarker && !isLast)
                      ? turnVector(
                              const Offset(0, 1),
                              (4 - widget.boardTurns) % 4,
                            ) *
                            (kPlayerIconSize * 0.70 * player.scale)
                      : Offset.zero,
                  isLast: isLast,
                  isSelected: chainSelected,
                  isPrimary:
                      chainSelected && state.selectedWaypointIndex == entry.key,
                  // A whole route's end may lie beats ahead of the
                  // token: a copy there is a destination, drawn as one.
                  isAtCurrentStep: isLast
                      ? !atStartTime &&
                            (limit == stepLimit ||
                                player.movePhases[entry.key] < restLimit)
                      : true,
                  onLongPress: isLast
                      ? () => state.selectPlayer(player.id)
                      : null,
                );
              });
        }),
        // The routes go UNDER the people. They are marks on the
        // ground, and a body standing across one hides that
        // stretch of it — including the arrowhead, when the body
        // is the receiver's: a pass drawn over everyone ran up the
        // receiver's shirt to a head on his number. Where a pass
        // arrives is said twice already, by the shaft running into
        // him and by the ball at his feet; where a run arrives is
        // the man himself, standing on it. (A split that kept the
        // heads on top was tried first and put the head on the
        // chest instead of the shirt, which is no better.) Gated by
        // the same per-element question as the ghosts and the
        // waypoint dots, so beat zero's button governs all of them.
        if (players.any(routeShown))
          IgnorePointer(
            child: CustomPaint(
              painter: routes(RouteLayer.all),
              size: Size(canvasW, canvasH),
            ),
          ),
        // A volleyball rotation board while a player is being dragged:
        // the patch of court he may legally stand on, under the people.
        if (_rotationDragId != null)
          ..._rotationLegalArea(state, canvasW, canvasH),
        // Players and the ball, over the ghosts and the routes.
        ...players.where((p) => !p.isMarker).map(playerIcon),
        // A volleyball rotation board with its overlap check on: the
        // pairs at fault, over the people they are about.
        if (state.rotation?.check == true) ..._rotationFaults(state, canvasW, canvasH),
        // Animation driver (zero-size, drives per-frame updates)
        _AnimationDriver(
          isAnimating: state.isAnimating,
          players: players,
          targetStep: state.targetStep,
          fromStep: state.animFromStep,
          toStep: state.animToStep,
          sequentialMode: state.sequentialMode,
          speed: state.animSpeed,
          loop: state.loopAnimation,
        ),
        // Lasso overlay — drawn while the user is rectangle-selecting
        // in multi-select mode.
        if (state.multiSelectDragRect != null)
          IgnorePointer(
            child: CustomPaint(
              painter: _LassoRectPainter(state.multiSelectDragRect!),
              size: Size(canvasW, canvasH),
            ),
          ),
      ],
    );
  }

  /// Where the player being dragged ([_rotationDragId]) may legally stand
  /// (see TacticsState.rotationLegalArea). Nothing when the board is not
  /// judging him — the check off, the server exempt, a beat on show.
  List<Widget> _rotationLegalArea(
      TacticsState state, double canvasW, double canvasH) {
    final footward =
        turnVector(const Offset(0, 1), (4 - widget.boardTurns) % 4);
    final area = state.rotationLegalArea(_rotationDragId!, footward: footward);
    if (area == null) return const [];
    final (rect, inside) = area;
    return [
      IgnorePointer(
        child: CustomPaint(
          key: const ValueKey('rotation-legal-area'),
          painter: RotationLegalAreaPainter(
            rect: rect,
            inside: inside,
            figureScale: kFigureScale,
          ),
          size: Size(canvasW, canvasH),
        ),
      ),
    ];
  }

  /// The overlap faults of a volleyball rotation board, drawn at the feet
  /// they are judged by (see TacticsState.rotationFaults). Nothing when the
  /// six are legal.
  List<Widget> _rotationFaults(
      TacticsState state, double canvasW, double canvasH) {
    final footward =
        turnVector(const Offset(0, 1), (4 - widget.boardTurns) % 4);
    final faults = state.rotationFaults(footward: footward);
    if (faults.isEmpty) return const [];
    final byId = {for (final p in state.players) p.id: p};
    Offset feet(String id) {
      final p = byId[id]!;
      return p.position + footward * (26.0 * kFigureScale * p.scale);
    }

    final court = state.sportType.fieldRect(Size(canvasW, canvasH));
    return [
      IgnorePointer(
        child: CustomPaint(
          key: const ValueKey('rotation-faults'),
          painter: RotationFaultPainter(
            pairs: [for (final f in faults) (feet(f.a), feet(f.b))],
            message: rotationFaultMessage(
                faults, (id) => byId[id]?.label ?? ''),
            // In the middle of the other half: the side being checked
            // stands on its own, the front row right under the net.
            messageAt: Offset(
                court.center.dx,
                court.top +
                    court.height *
                        (state.rotation!.team == PlayerTeam.away ? 0.75 : 0.25)),
            counterTurns: (4 - widget.boardTurns) % 4,
            figureScale: kFigureScale,
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
          ),
          size: Size(canvasW, canvasH),
        ),
      ),
    ];
  }

  /// Return strokes visible at the current playback step.
  /// Strokes with isFullSpan are always visible.
  /// During step playback, show strokes whose phase range overlaps current step.
  static List<DrawingStroke> _visibleStrokes(
    TacticsState state,
    List<PlayerIcon> players,
  ) {
    final phaseLimit = state.atStep > 0
        ? state.atStep
        : (state.targetStep > 0 ? state.targetStep : 0);
    if (phaseLimit == 0) return state.strokes; // show all
    // phaseLimit is the number of beats elapsed (atStep). A stroke whose
    // phase value is strictly less than phaseLimit has already begun.
    return state.strokes.where((s) {
      if (s.isFullSpan) return true;
      for (int ph = s.startPhase; ph <= s.endPhase; ph++) {
        if (ph < phaseLimit) return true;
      }
      return false;
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation driver — zero-size, drives step-by-step move animation
// ─────────────────────────────────────────────────────────────────────────────
class _AnimationDriver extends StatefulWidget {
  final bool isAnimating;
  final List<PlayerIcon> players;
  final int targetStep; // 0 = all
  final int fromStep;
  final int toStep; // 0 = play all from fromStep
  final bool sequentialMode;
  final double speed; // playback speed multiplier (0.5 / 1 / 2)
  final bool loop; // restart from phase 0 when the run finishes

  const _AnimationDriver({
    required this.isAnimating,
    required this.players,
    required this.targetStep,
    this.fromStep = 0,
    this.toStep = 0,
    this.sequentialMode = false,
    this.speed = 1.0,
    this.loop = false,
  });

  @override
  State<_AnimationDriver> createState() => _AnimationDriverState();
}

class _AnimationDriverState extends State<_AnimationDriver>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _curved;
  bool _isBackward = false;
  // Sequential mode: which player index is currently animating
  bool _singleStep = false; // true = only animate one phase then stop

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(_AnimationDriver old) {
    super.didUpdateWidget(old);
    if (widget.isAnimating && !old.isAnimating) {
      _buildPhaseGroups();
      // Per-phase duration scales inversely with the chosen playback speed.
      _ctrl.duration = Duration(
        milliseconds: (700 / widget.speed).clamp(120, 4000).round(),
      );
      _isBackward = widget.toStep < widget.fromStep;
      // Single step if toStep is exactly 1 away from fromStep
      _singleStep = (widget.toStep - widget.fromStep).abs() == 1;

      if (_maxPhase < 0) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<TacticsState>().finishAnimation(),
        );
        return;
      }

      if (_isBackward) {
        // _phaseIdx = phase value to rewind on this leg.
        _phaseIdx = widget.fromStep - 1;
        if (_phaseIdx < 0 || _phaseIdx < widget.toStep) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<TacticsState>().finishAnimation(),
          );
        } else {
          _startLeg();
        }
      } else {
        // _phaseIdx = phase value to animate on this leg.
        _phaseIdx = widget.fromStep;
        final endIdx = widget.toStep > 0 ? widget.toStep : (_maxPhase + 1);
        if (_phaseIdx > _maxPhase || _phaseIdx >= endIdx) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<TacticsState>().finishAnimation(),
          );
        } else {
          _startLeg();
        }
      }
    } else if (!widget.isAnimating && old.isAnimating) {
      _ctrl.stop();
      _phaseIdx = 0;
      _singleStep = false;
      _isBackward = false;
    }
  }

  /// Rewind and run this leg, but never during a build.
  ///
  /// didUpdateWidget runs inside the build phase, and forward(from: 0) sets
  /// the controller's value synchronously — so its first tick lands on
  /// updateAnimatedPositions and the state notifies its listeners while the
  /// tree is being built. The first animation of a session got away with it
  /// (the value was already 0, so nothing changed and nothing fired); every
  /// one after it started from 1.0 and did.
  void _startLeg() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isAnimating) _ctrl.forward(from: 0);
    });
  }

  // Phase-based animation: collect all (player, moveIndex) grouped by phase.
  // _phaseIdx is the phase VALUE currently animating (not an index into
  // distinct used phases) — so empty phases in the middle of the range
  // still get a beat in continuous playback.
  Map<int, List<({PlayerIcon player, int moveIdx})>> _phaseGroups = {};
  int _maxPhase = -1;
  int _phaseIdx = 0;

  void _buildPhaseGroups() {
    _phaseGroups = {};
    _maxPhase = -1;
    for (final player in widget.players) {
      player.syncPhases();
      for (int i = 0; i < player.moves.length; i++) {
        final phase = i < player.movePhases.length ? player.movePhases[i] : i;
        _phaseGroups.putIfAbsent(phase, () => []).add((
          player: player,
          moveIdx: i,
        ));
        if (phase > _maxPhase) _maxPhase = phase;
      }
    }
  }

  /// Resting position index in [position, ...moves] for a player at the
  /// START of phase value [phaseValue] — i.e. only moves whose phase is
  /// strictly less than phaseValue have completed.
  int _playerPosAtPhase(PlayerIcon player, int phaseValue) {
    int lastCompleted = -1;
    for (int i = 0; i < player.moves.length; i++) {
      final ph = i < player.movePhases.length ? player.movePhases[i] : i;
      if (ph < phaseValue) {
        if (i > lastCompleted) lastCompleted = i;
      }
    }
    return lastCompleted + 1;
  }

  /// Resting position index AFTER phase value [phaseValue] completes
  /// (used while rewinding so the player snaps to its end-of-phase pose).
  int _playerPosAfterPhase(PlayerIcon player, int phaseValue) {
    int lastCompleted = -1;
    for (int i = 0; i < player.moves.length; i++) {
      final ph = i < player.movePhases.length ? player.movePhases[i] : i;
      if (ph <= phaseValue) {
        if (i > lastCompleted) lastCompleted = i;
      }
    }
    return lastCompleted + 1;
  }

  void _onTick() {
    if (!widget.isAnimating) return;
    final t = _curved.value;
    final positions = <String, Offset>{};

    if (_maxPhase < 0) {
      context.read<TacticsState>().updateAnimatedPositions(positions);
      return;
    }

    // _phaseIdx is the phase value currently animating. Empty phase = no
    // active group → all players hold their resting positions for the beat.
    final activeGroup = _phaseGroups[_phaseIdx] ?? const [];

    for (final player in widget.players) {
      if (player.moves.isEmpty) continue; // no moves at all, skip
      final all = [player.position, ...player.moves];

      // Check if this player has a move in the current phase
      final activeEntry = activeGroup
          .where((e) => e.player.id == player.id)
          .toList();

      if (activeEntry.isNotEmpty) {
        // This player IS moving in this phase
        final moveIdx = activeEntry.first.moveIdx;
        final fromIdx = moveIdx.clamp(0, all.length - 1);
        final toIdx = (moveIdx + 1).clamp(0, all.length - 1);
        // Sequential mode: stagger players within the phase so each runs
        // its leg one after another instead of all moving together.
        double mt = t;
        if (widget.sequentialMode && activeGroup.length > 1) {
          final j = activeGroup.indexWhere((e) => e.player.id == player.id);
          final k = activeGroup.length;
          mt = (t * k - j).clamp(0.0, 1.0);
        }
        if (_isBackward) {
          positions[player.id] = Offset.lerp(all[toIdx], all[fromIdx], mt)!;
        } else {
          positions[player.id] = Offset.lerp(all[fromIdx], all[toIdx], mt)!;
        }
      } else {
        // This player is NOT moving in this phase
        // Only set position if they have completed at least one move before this phase
        final restIdx = _isBackward
            ? _playerPosAfterPhase(player, _phaseIdx)
            : _playerPosAtPhase(player, _phaseIdx);
        if (restIdx > 0) {
          // Player has moved before — hold at their resting position
          positions[player.id] = all[restIdx.clamp(0, all.length - 1)];
        }
        // else: restIdx==0 means player hasn't moved yet, don't set animated position
        // so the player renders at their original player.position naturally
      }
    }

    // A carried ball glues to its holder, overriding any moves of its own: it
    // sits at the same rest offset from the holder's live (animated) position.
    for (final ball in widget.players) {
      if (!ball.isBall || ball.attachedTo == null) continue;
      final holderIdx = widget.players.indexWhere(
        (p) => p.id == ball.attachedTo,
      );
      if (holderIdx < 0) continue;
      final holder = widget.players[holderIdx];
      final holderPos = positions[holder.id] ?? holder.position;
      positions[ball.id] = holderPos + (ball.position - holder.position);
    }
    context.read<TacticsState>().updateAnimatedPositions(positions);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    if (_isBackward) {
      _phaseIdx--;
      context.read<TacticsState>().advanceAtStep(_phaseIdx + 1);
      // Stop once the scrubber's target step is reached (toStep), not just
      // at phase 0 — so a multi-step rewind lands where the user dragged.
      if (_singleStep || _phaseIdx < widget.toStep || _phaseIdx < 0) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<TacticsState>().finishAnimation(),
        );
      } else {
        _ctrl.forward(from: 0);
      }
    } else {
      _phaseIdx++;
      context.read<TacticsState>().advanceAtStep(_phaseIdx);
      // Forward runs stop at toStep (the scrubber target / maxMoveSteps).
      final endIdx = widget.toStep > 0 ? widget.toStep : (_maxPhase + 1);
      if (!_singleStep && _phaseIdx >= endIdx && widget.loop) {
        // Loop: jump back to the first phase and keep playing.
        _phaseIdx = 0;
        context.read<TacticsState>().advanceAtStep(0);
        _ctrl.forward(from: 0);
      } else if (_singleStep || _phaseIdx >= endIdx) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<TacticsState>().finishAnimation(),
        );
      } else {
        _ctrl.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─────────────────────────────────────────────────────────────────────────────
// Player on board (draggable, supports animated position override)
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerOnBoard extends StatefulWidget {
  final PlayerIcon player;
  final Offset? renderPosition; // animated override
  /// Where the player faces this frame; the canvas works it out from the
  /// whole board (see boardHeading).
  final double heading;

  /// Draw-time nudge from [fanOutOffsets]. Added to the Positioned only —
  /// never to player.position — so the board's data, the drag deltas and the
  /// exported coordinates all stay on the real point.
  final Offset drawOffset;
  final bool isSelected;
  final bool isPrimary;
  final bool isAtCurrentStep; // start position is the current timeline step
  final bool isDrawingMode;

  /// True when the board is in the multi-select mode (taps toggle set
  /// membership instead of opening the edit panel). Controls the gesture
  /// dispatch in [_PlayerOnBoardState].
  final bool isMultiSelectMode;

  /// True when this player is currently in the multi-select set. Drives
  /// group drag — panning a member translates the whole set.
  final bool isInMultiSelect;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool labelAbove;

  /// A single-player drag beginning and ending (not a group drag, not the
  /// Pencil's palm).
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const _PlayerOnBoard({
    super.key,
    required this.player,
    this.renderPosition,
    required this.heading,
    this.labelAbove = false,
    this.drawOffset = Offset.zero,
    required this.isSelected,
    this.isPrimary = false,
    this.isAtCurrentStep = true,
    required this.isDrawingMode,
    this.isMultiSelectMode = false,
    this.isInMultiSelect = false,
    this.onTap,
    this.onLongPress,
    this.onContextMenu,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<_PlayerOnBoard> createState() => _PlayerOnBoardState();
}

class _PlayerOnBoardState extends State<_PlayerOnBoard> {
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  /// This drag is the Pencil (it draws instead — see _pencilDown) or a palm
  /// resting while the Pencil draws. Tablet only.
  bool _ignoreDrag = false;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final pos = (widget.renderPosition ?? player.position) + widget.drawOffset;
    final size = kPlayerIconSize * player.scale;
    // Start-of-chain icons (player has moves, not animating) render as a
    // faded ghost when the timeline is past step 0 — because the player's
    // "current" position is somewhere along the chain, not at the start.
    // At step 0 the start IS current, so show it solid. Primary tap always
    // reveals the full icon.
    final isStartWithMoves =
        widget.renderPosition == null && player.moves.isNotEmpty;
    final showGhostForStart =
        isStartWithMoves && !widget.isPrimary && !widget.isAtCurrentStep;
    // In multi-select mode a non-member player must NOT register a pan
    // recognizer at all — otherwise it would claim drags that started on
    // top of the player and the user couldn't lasso through it. Members
    // keep the pan so they can drag the whole set as a unit. Outside
    // multi-select mode, pan is always available (single-player drag).
    final canPan = !widget.isMultiSelectMode || widget.isInMultiSelect;
    final iconWidget = PlayerIconWidget(
      player: player,
      isSelected: widget.isSelected,
      sport: context.read<TacticsState>().sportType,
      heading: widget.heading,
      labelAbove: widget.labelAbove,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onContextMenu: widget.onContextMenu,
      onScaleStart: canPan
          ? (d) {
              _ignoreDrag =
                  MediaQuery.sizeOf(context).shortestSide >= 600 &&
                  (d.kind == PointerDeviceKind.stylus ||
                      pencilPointer != null);
              _baseScale = player.scale;
              _baseRotation = player.rotation;
              if (!_ignoreDrag && !widget.isInMultiSelect) {
                widget.onDragStart?.call();
              }
            }
          : null,
      onScaleUpdate: canPan
          ? (d) {
              if (_ignoreDrag) return;
              final state = context.read<TacticsState>();
              // In the board's frame. A text element's detector sits inside
              // its own turn, so its delta has to be turned back first.
              final delta = isTextElement(player)
                  ? untwistForText(player, d.focalPointDelta,
                      extraQuarters: BoardOrientation.counterTurns(context))
                  : d.focalPointDelta;
              if (widget.isInMultiSelect) {
                state.moveMultiSelectBy(delta);
                return;
              }
              state.movePlayer(player.id, player.position + delta);
              if (d.pointerCount >= 2) {
                state.resizePlayer(player.id, _baseScale * d.scale);
                // The same gesture already carried the twist; it was simply
                // being thrown away. Two fingers pinch AND turn, which is
                // what hands do to a piece on a board.
                state.rotatePlayer(player.id, _baseRotation + d.rotation);
              }
            }
          : null,
      onScaleEnd: canPan
          ? (d) {
              widget.onDragEnd?.call();
              if (_ignoreDrag) {
                _ignoreDrag = false;
                return;
              }
              final state = context.read<TacticsState>();
              if (widget.isInMultiSelect) {
                state.moveMultiSelectEnd();
                return;
              }
              state.movePlayerEnd(player.id, player.position);
              if (d.pointerCount >= 2) {
                state.resizePlayerEnd(player.id);
              }
            }
          : null,
    );
    // Hide the full icon entirely when start is not at the current step —
    // the dashed ghost (TopDownPlayerPainter isGhost:true) drawn at the same
    // position in the layer below will show through, giving a dashed outline.
    final visibleIcon = showGhostForStart
        ? Opacity(opacity: 0.0, child: iconWidget)
        : iconWidget;
    // Primary cyan glow only when the full icon is shown — a glow around an
    // invisible ghost reads as a stray blob. Chain selection on the start
    // position is implied by the glowing waypoints/end of the chain.
    //
    // Equipment and balls only. The ring is a disc the size of the token's
    // box, which was the whole of a player back when a player was a circle
    // in it; behind a figure that stands 1.57 boxes tall it is a white
    // plate showing through at the waist. A selected person is marked by
    // the accent rim on their outline and the ring at their feet, both
    // drawn by TopDownPlayerPainter.
    final BoxShadow? glow =
        widget.isPrimary && (player.isMarker || player.isBall)
        ? const BoxShadow(color: T.selectRing, blurRadius: 0, spreadRadius: 2)
        : null;
    if (isTextElement(player)) {
      // A chip sized to its words has no size to subtract, so it is placed on
      // the point and then pulled back by half of whatever it turned out to
      // be. Every other element is a known 44pt square.
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: visibleIcon,
        ),
      );
    }
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: glow != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [glow],
              ),
              child: visibleIcon,
            )
          : visibleIcon,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Waypoint dot (draggable, long-press to delete; last waypoint shows player shape)
// ─────────────────────────────────────────────────────────────────────────────
class _WaypointDot extends StatefulWidget {
  final PlayerIcon player;
  final int index;
  final Offset position;
  final bool isLast;
  final bool isSelected;
  final bool isPrimary;
  final bool isAtCurrentStep;
  final VoidCallback? onLongPress;

  /// Drawn here, stored at [position]. A person's route runs shoe to shoe
  /// (PlayerMovesPainter.footward), so the dot where he turns is drawn at
  /// his feet too; a drag still writes back to the token's middle, which is
  /// what [position] is, or every nudge of a dot would hop it 25pt.
  final Offset drawOffset;

  const _WaypointDot({
    super.key,
    required this.player,
    required this.index,
    required this.position,
    this.drawOffset = Offset.zero,
    this.isLast = false,
    this.isSelected = false,
    this.isPrimary = false,
    this.isAtCurrentStep = true,
    this.onLongPress,
  });

  @override
  State<_WaypointDot> createState() => _WaypointDotState();
}

class _WaypointDotState extends State<_WaypointDot> {
  static const double _dotSize = 28.0;

  void _onPanUpdate(DragUpdateDetails d) {
    context.read<TacticsState>().movePlayerWaypoint(
      widget.player.id,
      widget.index,
      widget.position + d.delta,
    );
  }

  void _onPanEnd(DragEndDetails _) {
    context.read<TacticsState>().movePlayerWaypointEnd(widget.player.id);
  }

  void _onDefaultLongPress() {
    context.read<TacticsState>().removePlayerWaypoint(
      widget.player.id,
      widget.index,
    );
  }

  void _onTap() {
    context.read<TacticsState>().selectPlayerWaypoint(
      widget.player.id,
      widget.index,
    );
  }

  @override
  Widget build(BuildContext context) {
    // A ball is never drawn at a waypoint, not even the last one. There is
    // one ball on the pitch and the coach follows it; a picture of it at the
    // end of its route — its final stop at beat zero, its destination while
    // it is in flight — is a second ball, which is the first thing the eye
    // goes to and the one thing on the board that must not be doubled. Its
    // stops keep the numbered badge every other waypoint uses, which is what
    // says the passing order, and the live token is the ball.
    if (widget.isLast && !widget.player.isBall) {
      // End icon is "current" when the timeline has advanced past step 0.
      // When still at step 0 the end is a future destination — render the
      // normal player shape as a dashed ghost outline (same style as the
      // start ghost) so start/end use consistent "not current" styling.
      final fadeEnd = !widget.isAtCurrentStep && !widget.isPrimary;
      final hasPhoto =
          widget.player.photoId != null &&
          !widget.player.isMarker &&
          !widget.player.isBall;
      final Widget endIcon = SizedBox(
        width: kPlayerIconSize,
        height: kPlayerIconSize,
        child: RotatedBox(
          quarterTurns: widget.player.isMarker || widget.player.isBall
              ? 0
              : BoardOrientation.counterTurns(context),
          child: Stack(
            children: [
              if (hasPhoto)
                Opacity(
                  opacity: fadeEnd ? 0.55 : 1.0,
                  child: PhotoPlayerShape(
                    player: widget.player,
                    isSelected: widget.isSelected,
                  ),
                )
              else if (widget.player.isBall)
                // The same fraction of the cell the ball's own icon uses.
                // Filling it edge to edge made the ball grow a third the
                // moment it reached its first waypoint — travelling resized
                // it.
                Center(
                  child: FractionallySizedBox(
                    widthFactor: ballDrawFactor(widget.player.sportType!),
                    heightFactor: ballDrawFactor(widget.player.sportType!),
                    child: ballWidget(widget.player.sportType!),
                  ),
                )
              else
                CustomPaint(
                  painter: widget.player.isMarker
                      ? MarkerPainter(
                          shape: widget.player.markerShape,
                          color: widget.player.color,
                          isSelected: widget.isSelected,
                        )
                      : TopDownPlayerPainter(
                          color: widget.player.color,
                          borderColor: widget.isPrimary
                              ? T.accent
                              : (widget.isSelected
                                    ? Colors.yellow
                                    : widget.player.moveColor),
                          borderWidth: widget.isPrimary
                              ? 3.5
                              : (widget.isSelected ? 3 : 2.5),
                          isSelected: widget.isSelected && !fadeEnd,
                          isGhost: fadeEnd,
                          gender: widget.player.gender,
                          figure: TopDownPlayerPainter.figureFor(
                            context.read<TacticsState>().sportType,
                            widget.player,
                          ),
                          sport: context.read<TacticsState>().sportType,
                          // Where the run ends: the stance the player takes
                          // once every beat has run.
                          heading: widget.player.facingLocked
                              ? playerFacing(widget.player)
                              : boardHeading(
                                      context.read<TacticsState>().players,
                                      widget.player,
                                      context.read<TacticsState>().maxMoveSteps,
                                    ) ??
                                    playerFacing(widget.player),
                          boardTurns: BoardOrientation.of(context),
                        ),
                  size: Size.infinite,
                ),
              if (widget.player.label.isNotEmpty &&
                  !widget.player.isMarker &&
                  !widget.player.isBall &&
                  !hasPhoto)
                Align(
                  // On the shirt, the same place the live token carries it.
                  alignment: playerLabelAlign(
                    context.read<TacticsState>().sportType,
                    widget.player,
                  ),
                  child: Text(
                    widget.player.label,
                    style: TextStyle(
                      color: Colors.white,
                      // A number matches the live token; a name has to stay
                      // small enough to fit inside the disc at all.
                      fontWeight: widget.player.labelInside
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: (widget.player.labelInside ? 15 : 13) *
                          kFigureScale,
                      height: 1,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      return Positioned(
        left: widget.position.dx + widget.drawOffset.dx - kPlayerIconSize / 2,
        top: widget.position.dy + widget.drawOffset.dy - kPlayerIconSize / 2,
        child: GestureDetector(
          onTap: _onTap,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onLongPress: widget.onLongPress,
          child: endIcon,
        ),
      );
    }

    // Larger hit area for easier dragging. Waypoints grow with the board's
    // figures (see kFigureScale) — the tight factor is the figures' alone.
    final k = gBoardFigureScale;
    final hitSize = 40.0 * k;
    // An unselected chain's middle stops are diagram, not controls: a filled
    // coloured disc the size of a ball, carrying a number, is read as an
    // object standing on the pitch — every reviewer of the drill library
    // called them balls. Unselected they are a small hollow ring, which says
    // "a point on this line" and nothing more; the moment the player is
    // selected they become the numbered disc again, because then they ARE
    // the handles you drag and long-press. The hit area never changes, so a
    // waypoint is just as easy to grab either way.
    final quiet = !widget.isSelected && !widget.isPrimary;
    if (quiet) {
      return Positioned(
        left: widget.position.dx + widget.drawOffset.dx - hitSize / 2,
        top: widget.position.dy + widget.drawOffset.dy - hitSize / 2,
        child: GestureDetector(
          onTap: _onTap,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onLongPress: _onDefaultLongPress,
          child: SizedBox(
            width: hitSize,
            height: hitSize,
            child: Center(
              child: Container(
                width: 13 * k,
                height: 13 * k,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x59000000),
                  border: Border.all(
                    color: widget.player.moveColor,
                    width: 2.5 * k,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    // At the feet like the quiet ring and the line (drawOffset): the disc a
    // selected chain shows was placed on the point itself, a stride above
    // where its legs met, so the arrows read as missing the stop.
    // Reported 2026-10-16.
    return Positioned(
      left: widget.position.dx + widget.drawOffset.dx - hitSize / 2,
      top: widget.position.dy + widget.drawOffset.dy - hitSize / 2,
      child: GestureDetector(
        onTap: _onTap,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onLongPress: _onDefaultLongPress,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: Container(
              width: _dotSize * k,
              height: _dotSize * k,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.player.moveColor,
                border: Border.all(
                  color: widget.isPrimary
                      ? T.accent
                      : (widget.isSelected ? Colors.yellow : Colors.white),
                  width:
                      (widget.isPrimary ? 3.5 : (widget.isSelected ? 3 : 2)) *
                          k,
                ),
                boxShadow: [
                  if (widget.isPrimary)
                    const BoxShadow(
                      color: T.selectRing,
                      blurRadius: 0,
                      spreadRadius: 2,
                    )
                  else if (widget.isSelected)
                    BoxShadow(
                      color: Colors.yellow.withValues(alpha: 0.7),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10 * k,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed selection rectangle drawn while the user lassos in multi-select
/// mode. Filled with a faint highlight color and outlined with dashes so
/// it reads as transient UI, not part of the board content.
class _LassoRectPainter extends CustomPainter {
  final Rect rect;
  const _LassoRectPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = T.accent.withValues(alpha: 0.10);
    canvas.drawRect(rect, fill);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = T.accent;

    // Manual dashed outline.
    const dashOn = 6.0;
    const dashOff = 4.0;
    void dashedLine(Offset a, Offset b) {
      final dx = b.dx - a.dx, dy = b.dy - a.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len == 0) return;
      final ux = dx / len, uy = dy / len;
      double t = 0;
      while (t < len) {
        final segEnd = (t + dashOn).clamp(0, len).toDouble();
        canvas.drawLine(
          Offset(a.dx + ux * t, a.dy + uy * t),
          Offset(a.dx + ux * segEnd, a.dy + uy * segEnd),
          stroke,
        );
        t = segEnd + dashOff;
      }
    }

    dashedLine(rect.topLeft, rect.topRight);
    dashedLine(rect.topRight, rect.bottomRight);
    dashedLine(rect.bottomRight, rect.bottomLeft);
    dashedLine(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(_LassoRectPainter old) => old.rect != rect;
}
