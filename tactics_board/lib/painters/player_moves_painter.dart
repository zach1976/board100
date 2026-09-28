import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import '../models/player_icon.dart';
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
/// The line is 70% of the icon: at that offset the two copies still overlap,
/// but each centre is clear of the other and the pair reads as "it was here,
/// now it is there". Any closer and the start copy is a shadow behind the
/// end copy, so the board drops it. It was a whole token wide until a
/// centre-mid dropping five metres — a real move, and the point of the beat —
/// came out as a lone token with a stub arrow and no sign of where he came
/// from. Above the line they are separate on the board and the run keeps its
/// destination, even where the arrow between them has to be squeezed.
///
/// Of the icon, not of the box: a ball is drawn at 58% of its cell and a
/// cone at 62%, so a header across the six-yard box — two ball widths, and
/// plainly two balls on the grass — was being judged against a body and lost
/// its start ghost.
double nudgeThreshold(PlayerIcon p) =>
    kPlayerIconSize * 0.7 * p.scale * iconDrawFactor(p);

/// How much of its 36pt box an icon actually fills.
double iconDrawFactor(PlayerIcon p) => p.isBall
    ? kBallDrawFactor
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

class PlayerMovesPainter extends CustomPainter {
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

  /// Where a moving ball is actually drawn, this frame.
  ///
  /// The route's last point is the leg's DESTINATION. While the ball is
  /// still travelling that is not where it is, so the arrow reached the
  /// spot the ball was heading for and the ball trailed behind it — up to
  /// 300 points behind, at the start of a long pass. Given this, the head
  /// follows the ball and arrives when it does.
  final Map<String, Offset> livePos;

  const PlayerMovesPainter({
    required this.players,
    this.livePos = const {},
    this.targetStep = 0,
    this.completedSteps,
    this.focusId,
    this.onlyFocus = false,
    this.endShift = const {},
    this.startShift = const {},
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
    final tail = !faded;
    player.syncPhases();

    // phaseLimit is the number of beats elapsed (atStep). Past step 0 only
    // the beat on show is drawn — its legs, from where the player stood as
    // it began. The earlier legs were the previous steps' pictures, and
    // stacked up they hid the one that mattered; the later ones have not
    // started. Step 0 is the overview and draws the whole plan.
    final int phaseLimit = whole ? 0 : (completedSteps ?? targetStep);
    final legs = stepLegs(player, phaseLimit);
    if (legs.isEmpty) return;
    final points = [
      stepStart(player, phaseLimit),
      ...legs.map((e) => e.value),
    ];
    if (player.isBall) {
      points[0] += startShift[player.id] ?? Offset.zero;
      final live = livePos[player.id];
      if (live != null) {
        // Mid-flight: end the line where the ball is, not where it is going.
        points[points.length - 1] = live;
      } else {
        points[points.length - 1] += endShift[player.id] ?? Offset.zero;
      }
    }
    // bbox half + shadow/border margin — keep arrow clear of the icon's drop
    // shadow. Of the icon as DRAWN: a ball fills 58% of its box, so a
    // player's radius left the arrowhead a third of a token short of it and
    // the line looked like it was aimed at the grass beside the ball.
    final iconRadius =
        kPlayerIconSize / 2 * player.scale * iconDrawFactor(player) + 3;

    for (int i = 0; i < points.length - 1; i++) {
      // Three kinds of line, which is the whole point of drawing them:
      // a dash is a run, a wave is a carry, a solid line is the ball on its
      // own. A carry belongs to the man doing it — the ball's copy of that
      // leg is not drawn, or the board shows the same action twice, two
      // parallel arrows a few points apart.
      final carrying = carries.contains('${player.id}#${legs[i].key}');
      if (player.isBall && carrying) continue;
      final style = carrying
          ? _Line.wave
          : player.isBall
              ? _Line.solid
              : _Line.dash;
      final from = points[i];
      final to = points[i + 1];
      // Offset both ends: start from source edge, end at destination edge
      final startRadius = i == 0 ? iconRadius : _waypointRadius;
      final isLastSegment = i == points.length - 2;
      final endRadius = isLastSegment ? iconRadius : _waypointRadius;
      final dist = (to - from).distance;
      if (dist < nudgeThreshold(player)) {
        _drawNudge(canvas, color, from, to, endRadius,
            strong: strong, fade: tail, style: style);
        continue;
      }
      // Two tokens far enough apart to read can still be closer than the two
      // clearances want. Shrinking both in proportion keeps a short arrow
      // pointing the right way; at full radius the offsets would cross over
      // and the arrowhead would be drawn at the wrong end.
      final room = min(1.0, dist / (startRadius + endRadius + 10));
      final adjustedFrom = _offsetToward(from, to, startRadius * room);
      final adjustedTo = _offsetToward(to, from, endRadius * room);
      _drawLine(canvas, color, adjustedFrom, adjustedTo,
          strong: strong, fade: tail, style: style);
      _drawArrowHead(canvas, color, adjustedFrom, adjustedTo,
          strong: strong);
    }

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

    final outlinePath = _arrowPath(to, angle, size + 3);
    canvas.drawPath(
      outlinePath,
      Paint()
        ..color = strong ? const Color(0x66000000) : const Color(0x47000000)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      _arrowPath(to, angle, size),
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
      oldDelegate.players != players ||
      oldDelegate.focusId != focusId ||
      oldDelegate.onlyFocus != onlyFocus ||
      !mapEquals(oldDelegate.endShift, endShift) ||
      !mapEquals(oldDelegate.startShift, startShift) ||
      !mapEquals(oldDelegate.livePos, livePos);
}
