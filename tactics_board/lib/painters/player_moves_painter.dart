import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import '../models/player_icon.dart';
import '../models/sport_type.dart';
import '../widgets/player_icon_widget.dart';

/// Which legs of this ball's route ride along with a player, and whose leg
/// each one rides with: `{ball leg index: "<player id>#<their leg index>"}`.
///
/// A pass-and-follow drill gives the ball and the runner the same route one
/// beat apart at most, and drawing both meant every edge of the diamond
/// carried two parallel dashed arrows plus the ball's own waypoint badges.
/// Where the ball's segment starts and ends within an arm's reach of some
/// player's segment in the same phase, the two are one action — a carry —
/// and the board draws it once: the player's line, waved, and no ball line
/// beside it. A leg the ball makes alone (a pass, a switch, a shot) is the
/// ball's own and keeps its line.
///
/// This was once all-or-nothing, and most routes are neither: a carry, then
/// a pass, then a carry. Those drew the ball's whole chain, so every carry
/// came out as two parallel dashed arrows a few points apart in near enough
/// the same colour, which is what a coach reported as "two lines".
Map<int, String> ballEscorts(PlayerIcon ball, List<PlayerIcon> players) {
  // At the receiver's feet the ball sits ~38pt from the receiver's point;
  // one and a half icons covers that with room, while the next cone is
  // hundreds of points away.
  const near = kPlayerIconSize * 1.5;
  final out = <int, String>{};
  if (ball.moves.isEmpty) return out;
  ball.syncPhases();
  // A board that says who is carrying it is believed. Measuring cannot
  // answer this: after a short pass to a neighbour the passer is still the
  // man standing nearest the ball at both ends of the leg, so the board was
  // dropping the pass line and drawing the passer's own run as a dribble.
  if (ball.moveCarriers.length == ball.moves.length) {
    for (int i = 0; i < ball.moves.length; i++) {
      final who = ball.moveCarriers[i];
      if (who == null) continue;
      final ph = i < ball.movePhases.length ? ball.movePhases[i] : i;
      for (final p in players) {
        if (p.id != who) continue;
        p.syncPhases();
        for (int j = 0; j < p.moves.length; j++) {
          final pph = j < p.movePhases.length ? p.movePhases[j] : j;
          if (pph == ph) {
            out[i] = '${p.id}#$j';
            break;
          }
        }
      }
    }
    return out;
  }
  for (int i = 0; i < ball.moves.length; i++) {
    final from = i == 0 ? ball.position : ball.moves[i - 1];
    final to = ball.moves[i];
    final ph = i < ball.movePhases.length ? ball.movePhases[i] : i;
    for (final p in players) {
      if (p.isBall || p.isMarker || p.moves.isEmpty) continue;
      p.syncPhases();
      for (int j = 0; j < p.moves.length; j++) {
        final pph = j < p.movePhases.length ? p.movePhases[j] : j;
        if (pph != ph) continue;
        final pFrom = j == 0 ? p.position : p.moves[j - 1];
        final pTo = p.moves[j];
        if ((pFrom - from).distance < near && (pTo - to).distance < near) {
          out[i] = '${p.id}#$j';
          break;
        }
      }
      if (out.containsKey(i)) break;
    }
  }
  return out;
}

/// Whether every leg of this ball's route rides along with somebody — the
/// test the waypoint dots still want, since a ball that never travels alone
/// has no stop of its own worth numbering.
bool ballTravelsWithPlayers(PlayerIcon ball, List<PlayerIcon> players) =>
    ball.moves.isNotEmpty &&
    ballEscorts(ball, players).length == ball.moves.length;

/// A run too short to draw as a translation.
///
/// A token is 44pt on a 402pt board — about 8.6 m of a full pitch — so a
/// defender shifting three metres moves less than his own width. The arrow
/// between two icons needs a radius of clearance at each end, which is more
/// than the whole move, so the line vanishes under the tokens and the start
/// copy of the player lands on top of the end copy: one man drawn twice with
/// nothing legible between. Below this the board says it the only way it
/// honestly can at this scale — one copy of the player, and a stub arrow
/// butted against him showing which way he shifts.
///
/// The line is a quarter of the icon. It was 70%, and before that a whole
/// token: each time it came down because a real move — a centre-mid dropping
/// five metres, a presser stepping in to tackle — came out as a lone token
/// with a stub arrow and no sign of where he came from. At 70% that was
/// still a quarter of every run in the library, 938 legs, each an arrow
/// from nowhere. The figure draws 26pt wide by 56pt tall, so a start copy
/// a dozen points off is not a shadow behind the end copy: its head or its
/// boots show, and the pair reads as "it was here, now it is there", with
/// the squeezed arrow between them saying which way. Below a quarter the
/// two really are one figure, and the stub is all that can honestly be said.
///
/// Of the icon, not of the box: a ball is drawn at 58% of its cell and a
/// cone at 62%, so a header across the six-yard box — two ball widths, and
/// plainly two balls on the grass — was being judged against a body and lost
/// its start ghost.
double nudgeThreshold(PlayerIcon p) =>
    kPlayerIconSize * 0.25 * p.scale * iconDrawFactor(p);

/// How much of its 36pt box an icon actually fills.
double iconDrawFactor(PlayerIcon p) => p.isBall
    ? ballDrawFactor(p.sportType ?? SportType.soccer)
    : p.isMarker
        ? markerArtScale(p.markerShape)
        : 1.0;


/// The legs a player runs on the beat that is showing, as (index into
/// moves, point). With [phaseLimit] beats elapsed the beat on show is
/// phaseLimit-1. phaseLimit 0 is the overview: every leg.
List<MapEntry<int, Offset>> stepLegs(PlayerIcon player, int phaseLimit) {
  player.syncPhases();
  final out = <MapEntry<int, Offset>>[];
  for (var i = 0; i < player.moves.length; i++) {
    final ph = i < player.movePhases.length ? player.movePhases[i] : i;
    if (phaseLimit <= 0 || ph == phaseLimit - 1) {
      out.add(MapEntry(i, player.moves[i]));
    }
  }
  return out;
}

/// Who has the ball once [phaseLimit] beats have run, by the board's own
/// word: the holder after the last leg of any earlier beat, else whoever it
/// was placed with. Null when the board does not say, or the ball was last
/// played to a spot — the caller then falls back to the nearest man.
String? ballHolderAt(PlayerIcon ball, int phaseLimit) {
  if (ball.moveHolders.length != ball.moves.length) return null;
  ball.syncPhases();
  String? who = ball.holder;
  for (var i = 0; i < ball.moves.length; i++) {
    final ph = i < ball.movePhases.length ? ball.movePhases[i] : i;
    if (ph < phaseLimit) who = ball.moveHolders[i];
  }
  return who;
}

/// Which leg of the ball's route a point lies on, and how far along it.
class BallLegPosition {
  const BallLegPosition(this.phase, this.t);
  /// The beat the leg belongs to.
  final int phase;
  /// 0 at the leg's start, 1 at its end.
  final double t;
}

/// The leg the ball is on while it is drawn at [at] — the one it is nearest
/// to — and its progress along it. Null for a ball with no route.
BallLegPosition? ballLegAt(PlayerIcon ball, Offset at) {
  if (ball.moves.isEmpty) return null;
  ball.syncPhases();
  BallLegPosition? best;
  var bestDist = double.infinity;
  var from = ball.position;
  for (var i = 0; i < ball.moves.length; i++) {
    final to = ball.moves[i];
    final ph = i < ball.movePhases.length ? ball.movePhases[i] : i;
    final seg = to - from;
    final len2 = seg.dx * seg.dx + seg.dy * seg.dy;
    final t = len2 < 1e-6
        ? 0.0
        : (((at - from).dx * seg.dx + (at - from).dy * seg.dy) / len2)
            .clamp(0.0, 1.0);
    final d = (from + seg * t - at).distance;
    if (d < bestDist) {
      bestDist = d;
      best = BallLegPosition(ph, t);
    }
    from = to;
  }
  return best;
}

/// Where the player stands as the beat on show begins: the end of the last
/// leg of any earlier beat, else the start. The overview starts at the start.
Offset stepStart(PlayerIcon player, int phaseLimit) {
  if (phaseLimit <= 0) return player.position;
  player.syncPhases();
  var at = player.position;
  for (var i = 0; i < player.moves.length; i++) {
    final ph = i < player.movePhases.length ? player.movePhases[i] : i;
    if (ph < phaseLimit - 1) at = player.moves[i];
  }
  return at;
}

/// What a line on the board is saying: a run, a carry, or the ball alone.
enum _Line { dash, wave, solid }

/// Which half of a route this painter draws.
///
/// A route used to be painted in one pass over the people, so that an
/// arrowhead was never covered — and so that every shaft crossed every body
/// in its way, a pass line running up the receiver's shirt to a head on his
/// chest. The shafts are marks on the ground: they go UNDER the people, and
/// a body across one hides that stretch of it, as it would. The heads are
/// the one part that must always be seen — where the ball or the man
/// arrives — and they go over. Two painters, one on each side of the tokens.
enum RouteLayer { all, shafts, heads }

class PlayerMovesPainter extends CustomPainter {
  final RouteLayer layer;
  final List<PlayerIcon> players;
  final int targetStep; // 0 = all; used when not animating
  final int? completedSteps; // non-null during animation: show only this many segments

  /// The one element to follow, if a coach has picked one.
  ///
  /// A full plan at step 0 is every route at once, which is the picture that
  /// says what the drill is and is useless for answering "where does G go?".
  /// Selecting an element answers it: its own route is drawn whole — every
  /// beat of it, even when the board is parked on beat three — and everybody
  /// else's drops to a tenth of its weight so the pitch is still legible
  /// around it. Nothing is hidden, which matters: a run that is only a run
  /// because of where the others went must still be readable against them.
  final String? focusId;

  /// Draw nothing but the followed route. Beat zero is a picture of where
  /// everybody stands; the plan behind it is shown on request, and following
  /// one element is that request narrowed to one.
  final bool onlyFocus;

  /// Where a ball is drawn, less where its route says it is — the step to
  /// the feet of whoever it stopped with (see ballAtFeetOffsets). The
  /// route's last point takes the same step, so the arrowhead lands on the
  /// ball rather than on a patch of grass a token's length short of it.
  final Map<String, Offset> endShift;

  /// The same, for the ball left behind at the start of the leg. Without it
  /// the line sets off from the spot the file names and the trace of the
  /// ball sits a token away from it.
  final Map<String, Offset> startShift;

  /// Which way is down the SCREEN, as a unit vector in board coordinates.
  ///
  /// A route is stored as the token's centre, and a token is the middle of
  /// a figure who stands 25pt taller than that and whose feet are 25pt
  /// lower. A line drawn centre to centre set off from one man's chest and
  /// ran into the next man's stomach. Shifted by the figure's foot offset it
  /// runs shoe to shoe, which is where a man actually goes. The figures
  /// stand upright whichever way the board is turned, so "down" is a screen
  /// direction the board hands in. Zero means no shift — a caller with no
  /// figures, or the old picture.
  final Offset footward;

  /// Where a moving ball is actually drawn, this frame.
  ///
  /// The route's last point is the leg's DESTINATION. While the ball is
  /// still travelling that is not where it is, so the arrow reached the
  /// spot the ball was heading for and the ball trailed behind it — up to
  /// 300 points behind, at the start of a long pass. Given this, the head
  /// follows the ball and arrives when it does.
  final Map<String, Offset> livePos;

  /// The sport the board is set to, which decides whether a holder on the
  /// move is carrying the ball or merely walking while it waits for him.
  /// Null keeps the old behaviour — a carry is a carry — for the callers
  /// that have no board to ask.
  final SportType? sport;

  const PlayerMovesPainter({
    required this.players,
    this.layer = RouteLayer.all,
    this.livePos = const {},
    this.sport,
    this.targetStep = 0,
    this.completedSteps,
    this.focusId,
    this.onlyFocus = false,
    this.endShift = const {},
    this.startShift = const {},
    this.footward = Offset.zero,
  });

  /// The focused element, but only when it has a route to follow — selecting
  /// a cone must not fade the whole board to look at nothing.
  PlayerIcon? get _focus {
    final id = focusId;
    if (id == null) return null;
    for (final p in players) {
      if (p.id == id && p.moves.isNotEmpty) return p;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final focus = _focus;
    if (onlyFocus && focus == null) return;
    // Every leg on which somebody is carrying the ball, as "<id>#<leg>" —
    // the player's key and the ball's both, so each side knows to draw the
    // carry once and to leave the other's copy of it alone.
    final carries = <String>{};
    for (final p in players) {
      if (!p.isBall) continue;
      ballEscorts(p, players).forEach((leg, who) {
        carries.add(who);
        carries.add('${p.id}#$leg');
      });
    }
    for (final player in players) {
      if (player.moves.isEmpty) continue;
      if (onlyFocus && player.id != focus!.id) continue;
      if (focus == null) {
        _paintMoves(canvas, player, carries: carries);
      } else if (player.id == focus.id) {
        // Whole route, not the beat on show — but not mid-animation, where
        // the drawing IS the clock and drawing ahead of it would be a lie.
        _paintMoves(canvas, player,
            whole: completedSteps == null, carries: carries);
      } else {
        // Behind the one being followed, not gone. At 0x1A — 10% — an
        // unfollowed route was a smudge on the grass: the gradient tail
        // takes its source end to 30% of that, so the faintest part of a
        // pass was 3% over a pitch that is already green. It is the one
        // being followed that stands out, by being thicker, solid and at
        // full strength; these only have to stay readable.
        canvas.saveLayer(
            Offset.zero & size, Paint()..color = const Color(0x8CFFFFFF));
        _paintMoves(canvas, player, faded: true, carries: carries);
        canvas.restore();
      }
    }
  }

  static const _strokeWidth = 2.8;
  static const _arrowSize = 13.0;
  static const _waypointRadius = 17.0; // half of 28.0 dot + shadow margin

  void _paintMoves(Canvas canvas, PlayerIcon player,
      {bool whole = false,
      bool faded = false,
      Set<String> carries = const {}}) {
    // The route being followed is drawn at full strength for its whole
    // length. Every other arrow fades from 30% at its source to full colour
    // at its destination — a sense of direction that costs nothing when the
    // arrow is one of twenty, and costs the picture when it is the only one
    // a coach asked to see: a short run is mostly source, so the line a
    // coach had just selected was the palest thing on the pitch.
    final strong = whole;
    final color = player.moveColor;
    // A route already drawn through a half-transparent layer does not also
    // get the fading tail: the two multiply, and the start of the line
    // disappears altogether.
    //
    // Nor does the ball's. The fade is a sense of direction for a dashed
    // run; a pass or a shot has an arrowhead for that, and its line sets
    // off from the passer's boots — straight up through his shirt. At 55%
    // a light-blue line over a blue kit is not there, so the shot appeared
    // to begin at his head, a token above the ball it left. Reported off a
    // phone during device QA of 2.0.1.
    final tail = !faded && !player.isBall;
    player.syncPhases();

    // phaseLimit is the number of beats elapsed (atStep). Past step 0 only
    // the beat on show is drawn — its legs, from where the player stood as
    // it began. The earlier legs were the previous steps' pictures, and
    // stacked up they hid the one that mattered; the later ones have not
    // started. Step 0 is the overview and draws the whole plan.
    final int phaseLimit = whole ? 0 : (completedSteps ?? targetStep);
    final legs = stepLegs(player, phaseLimit);
    if (legs.isEmpty) return;
    // Every point, not only the ends: a man's waypoints are where he turns,
    // and he turns on his feet.
    final feet = (player.isBall || player.isMarker)
        ? Offset.zero
        : footward * (kPlayerIconSize * 0.70 * player.scale);
    final points = [
      stepStart(player, phaseLimit) + feet,
      ...legs.map((e) => e.value + feet),
    ];
    // The ends follow the token: a ball is drawn at its holder's foot and a
    // crowded figure is nudged aside, and a line that ends where the token
    // WOULD have been stops a stride short of where it is.
    points[0] += startShift[player.id] ?? Offset.zero;
    final live = player.isBall ? livePos[player.id] : null;
    if (live != null) {
      // Mid-flight: end the line where the ball is, not where it is going.
      points[points.length - 1] = live;
    } else {
      points[points.length - 1] += endShift[player.id] ?? Offset.zero;
    }
    // bbox half + shadow/border margin — keep arrow clear of the icon's drop
    // shadow. Of the icon as DRAWN: a ball fills 58% of its box, so a
    // player's radius left the arrowhead a third of a token short of it and
    // the line looked like it was aimed at the grass beside the ball.
    //
    // A person is not a disc either: the figure is 23.5pt across, not 36,
    // and the routes are painted UNDER the people, so the head only has to
    // reach the silhouette — the body hides whatever lies beyond. Backed
    // off a whole token radius the head stopped a stride short of its
    // runner, and whoever happened to stand in that stride was read as
    // where the run ended.
    //
    // A person's line ends at the feet. How far back from them the head has
    // to sit depends on where the line comes from: the figure stands 50pt
    // UP from its feet and 12pt to either side, and the routes are painted
    // under the people, so a run arriving from above has its whole last
    // stride — head and all — behind the body, while one arriving from below
    // meets nothing but the shoe. See [_personClear].
    final iconRadius = player.isBall || player.isMarker
        ? kPlayerIconSize / 2 * player.scale * iconDrawFactor(player) + 3
        : 5.0 * player.scale;
    final person = !player.isBall && !player.isMarker && footward != Offset.zero;

    for (int i = 0; i < points.length - 1; i++) {
      // Three kinds of line, which is the whole point of drawing them:
      // a dash is a run, a wave is a carry, a solid line is the ball on its
      // own. A carry belongs to the man doing it — the ball's copy of that
      // leg is not drawn, or the board shows the same action twice, two
      // parallel arrows a few points apart.
      final carrying = carries.contains('${player.id}#${legs[i].key}');
      if (player.isBall && carrying) continue;
      // The squiggle only where a ball can actually travel with a player.
      // A shuttle is struck, never carried, so on a badminton court the
      // man walking to meet it read as dribbling it there; his is a run
      // like any other. The ball's own copy of the leg stays dropped
      // either way — it rides with him, and two lines for one movement is
      // the thing [carries] exists to prevent.
      final style = carrying && (sport?.canCarryBall ?? true)
          ? _Line.wave
          : player.isBall
              ? _Line.solid
              : _Line.dash;
      final from = points[i];
      final to = points[i + 1];
      // Offset both ends: start from source edge, end at destination edge
      final isLastSegment = i == points.length - 2;
      final startRadius = i == 0
          ? (person ? _personClear(to - from, player.scale) : iconRadius)
          : _waypointRadius;
      final endRadius = isLastSegment
          ? (person ? _personClear(from - to, player.scale) : iconRadius)
          : _waypointRadius;
      final dist = (to - from).distance;
      // A ball that has not left yet has no line. Mid-flight the line ends
      // where the ball is, and in the first frames of a pass that is a few
      // points from where it began — which the stub arrow turned into a
      // 17pt arrow pointing wherever those few points happened to lie,
      // there for a moment and then gone.
      //
      // The same holds for a ball that never leaves at all: the generator
      // keeps one leg that goes nowhere, the turnover, where a presser
      // steps in and takes it off the man standing on it. The beat is real
      // — the ball changes hands — but nothing travels, so there is
      // nothing to draw a line for, and a stub beside a ball that has not
      // moved is the dangling arrow all over again.
      if (player.isBall && dist < nudgeThreshold(player)) continue;
      if (dist < nudgeThreshold(player)) {
        // A stub is all head: it exists to say where something arrives.
        if (layer != RouteLayer.shafts) {
          _drawNudge(canvas, color, from, to, endRadius,
              strong: strong, fade: tail, style: style);
        }
        continue;
      }
      // Two tokens far enough apart to read can still be closer than the two
      // clearances want. Shrinking both in proportion keeps a short arrow
      // pointing the right way; at full radius the offsets would cross over
      // and the arrowhead would be drawn at the wrong end.
      final room = min(1.0, dist / (startRadius + endRadius + 10));
      final adjustedFrom = _offsetToward(from, to, startRadius * room);
      final adjustedTo = _offsetToward(to, from, endRadius * room);
      if (layer != RouteLayer.heads) {
        _drawLine(canvas, color, adjustedFrom, adjustedTo,
            strong: strong, fade: tail, style: style);
      }
      if (layer == RouteLayer.shafts) continue;
      _drawArrowHead(canvas, color, adjustedFrom, adjustedTo,
          strong: strong);
    }

  }

  /// How far a line has to stay back from a figure's feet so that its head
  /// shows, given the direction it leaves the feet in ([away], board
  /// coordinates, not necessarily unit).
  ///
  /// The figure is a box on the screen: 12pt either side of the feet and
  /// 50pt up from them. The answer is where a ray from the feet leaves that
  /// box — straight up, the whole 50; sideways, 12; straight down, nothing —
  /// plus a few points of air. Worked in screen space via [footward],
  /// because the box stands upright whichever way the board is turned.
  double _personClear(Offset away, double scale) {
    final len = away.distance;
    if (len < 1e-6) return 5.0 * scale;
    final u = away / len;
    final down = footward;
    final right = Offset(footward.dy, -footward.dx);
    final ux = u.dx * right.dx + u.dy * right.dy;
    final uy = u.dx * down.dx + u.dy * down.dy;
    final hw = 12.0 * scale, up = 50.0 * scale;
    var t = double.infinity;
    if (ux.abs() > 1e-6) t = hw / ux.abs();
    if (uy < -1e-6) t = t < up / -uy ? t : up / -uy;
    if (uy > 1e-6) t = 0;
    if (t == double.infinity) t = hw;
    return t + 4.0 * scale;
  }

  /// The stub for a move the icons are too big to show — see
  /// [nudgeThreshold]. It ends where the conventional arrow would, just clear
  /// of the destination, and runs back from there far enough to be read.
  void _drawNudge(Canvas canvas, Color color, Offset from, Offset to,
      double endRadius,
      {bool strong = false, bool fade = true, _Line style = _Line.dash}) {
    final delta = to - from;
    final dist = delta.distance;
    if (dist < 0.5) return;
    final dir = delta / dist;
    final tip = to - dir * endRadius;
    final tail = tip - dir * 17.0;
    _drawLine(canvas, color, tail, tip,
        strong: strong, fade: fade, style: style);
    _drawArrowHead(canvas, color, tail, tip, strong: strong);
  }

  static Offset _offsetToward(Offset from, Offset to, double radius) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist <= radius) return from;
    return Offset(from.dx + dx / dist * radius, from.dy + dy / dist * radius);
  }

  /// One line, drawn the way its action is drawn on a whiteboard: a run is
  /// dashed, a carry waves, the ball on its own is a solid line.
  void _drawLine(Canvas canvas, Color color, Offset from, Offset to,
      {bool strong = false, bool fade = true, _Line style = _Line.dash}) {
    final width = strong ? _strokeWidth + 1.0 : _strokeWidth;
    // A darker edge, not a shadow. Every path used to carry a black halo
    // at 50%, which on a deeper pitch reads as a second thicker line beside
    // the first; 28% is enough to hold the arrow against grass and white
    // pitch markings both.
    final outlinePaint = Paint()
      ..color = strong ? const Color(0x66000000) : const Color(0x47000000)
      ..strokeWidth = width + 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Gradient tail: faded at the source, full color near the destination —
    // gives a sense of direction/recency without changing the dashed style.
    final linePaint = Paint()
      ..shader = (strong || !fade)
          ? null
          // 0.55 at the source, not 0.30: with a token's clearance taken
          // off each end a pass between neighbours is forty points of
          // line, and at 0.30 the half of it nearest the passer was gone
          // against green. There is still a direction to it.
          : ui.Gradient.linear(from, to, [color.withValues(alpha: 0.55), color])
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = style == _Line.wave
        ? _wavePath(from, to)
        : (Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy));

    for (final paint in [outlinePaint, linePaint]) {
      if (style != _Line.dash) {
        canvas.drawPath(path, paint);
        continue;
      }
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

  /// The squiggle a coach draws for a man running with the ball.
  ///
  /// A whole number of periods, so the wave crosses the straight line at
  /// both ends: the tail leaves the carrier's boot and the head meets the
  /// arrow dead on, instead of setting off sideways. The period stretches
  /// to fit rather than the wave being cut short — a long carry waves more
  /// times, not further out, so the same action reads the same at any
  /// length. 9pt of swing on a 2.8pt line is enough to tell from a dash
  /// across a phone-sized board without turning the pitch into a scribble.
  Path _wavePath(Offset from, Offset to) {
    final delta = to - from;
    final dist = delta.distance;
    final path = Path()..moveTo(from.dx, from.dy);
    if (dist < 1) {
      return path..lineTo(to.dx, to.dy);
    }
    final dir = delta / dist;
    final normal = Offset(-dir.dy, dir.dx);
    const amplitude = 4.5;
    final periods = max(1, (dist / 26.0).round());
    final period = dist / periods;
    for (double t = 1.5; t < dist; t += 1.5) {
      final swing = amplitude * sin(t / period * 2 * pi);
      final at = from + dir * t + normal * swing;
      path.lineTo(at.dx, at.dy);
    }
    return path..lineTo(to.dx, to.dy);
  }

  void _drawArrowHead(Canvas canvas, Color color, Offset from, Offset to,
      {bool strong = false}) {
    final angle = atan2(to.dy - from.dy, to.dx - from.dx);
    final size = strong ? _arrowSize + 2 : _arrowSize;

    // A dark rim round the head, so it reads on light turf and over a
    // white line. It used to be a second, bigger triangle filled behind the
    // first — grown from the same tip, so all of the extra lay along the two
    // trailing edges and none at the point, and at board size that is a
    // darker arrowhead peeping out from behind the real one: "the arrow is
    // drawn twice". A stroke hugs all three edges evenly.
    final head = _arrowPath(to, angle, size);
    canvas.drawPath(
      head,
      Paint()
        ..color = strong ? const Color(0x66000000) : const Color(0x47000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strong ? 3.0 : 2.4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      head,
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
      oldDelegate.layer != layer ||
      oldDelegate.footward != footward ||
      oldDelegate.completedSteps != completedSteps ||
      oldDelegate.targetStep != targetStep ||
      oldDelegate.players != players ||
      oldDelegate.focusId != focusId ||
      oldDelegate.onlyFocus != onlyFocus ||
      !mapEquals(oldDelegate.endShift, endShift) ||
      !mapEquals(oldDelegate.startShift, startShift) ||
      !mapEquals(oldDelegate.livePos, livePos);
}
