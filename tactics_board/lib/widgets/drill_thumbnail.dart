import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/drill.dart';
import '../models/sport_type.dart';
import '../ui/tokens.dart';
import 'tactics_canvas.dart' show kBoardRefWidth, kBoardRefHeight;

/// A drill, small enough to scan a list of a hundred.
///
/// Deliberately NOT a shrunken [TacticsCanvas]: the canvas is the real board
/// — sprites, animation controllers, gesture recognisers, a repaint boundary
/// — and a hundred of them in a scrolling list is a hundred of all that.
///
/// What it draws is a coaching diagram, not a snapshot of coordinates. A
/// snapshot — dots where people start, a line where the ball's centre went —
/// was tried and could not be read: the ball's path ran beside the players
/// rather than between them, and the run that IS an overlap was not drawn at
/// all. A coach reads a drill the way it is chalked on a whiteboard: solid
/// arrows for passes, from one player to the next; dashed arrows for runs;
/// and nothing else competing with them.
///
/// It is cropped to what the drill occupies. Nearly every drill happens in a
/// box in the middle or a corner of the pitch, and a thumbnail of the whole
/// pitch spent most of itself on empty grass.
class DrillThumbnail extends StatelessWidget {
  final Drill drill;
  final SportType sport;

  /// The long side. The short one follows from the sport's own proportions.
  final double height;

  const DrillThumbnail({
    super.key,
    required this.drill,
    required this.sport,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    // Where the app puts the pitch inside the board, as fractions of the
    // authored canvas. Read from the same fieldRect the board itself uses,
    // so the crop cannot drift from what a coach sees on opening the drill.
    final fr = sport.fieldRect(const Size(kBoardRefWidth, kBoardRefHeight));
    final pitch = Rect.fromLTWH(
      fr.left / kBoardRefWidth,
      fr.top / kBoardRefHeight,
      fr.width / kBoardRefWidth,
      fr.height / kBoardRefHeight,
    );
    final scene = _Scene.read(drill, pitch);

    return ClipRRect(
      borderRadius: BorderRadius.circular(T.rSm),
      child: SizedBox(
        width: height * (fr.width / fr.height),
        height: height,
        child: CustomPaint(
          painter: _ThumbPainter(
              scene, drill.offSurface, DefaultTextStyle.of(context).style),
        ),
      ),
    );
  }
}

enum _Kind { home, away, gear }

/// Below this a "move" is an adjustment, not a run. Measured across the
/// library: the runs that DEFINE a drill — an overlap, a third-man run, a
/// slalom — are all 0.31 of the pitch or longer, and every stepping-in,
/// opening-up, closing-down shuffle is 0.17 or shorter, the hand-authored
/// 4v2 rondo's included. Drawn as arrows the shuffles were noise around every
/// ring, and worse, they moved the receiver's mark so the passes no longer
/// met the circles.
const double _kRunMin = 0.20;

/// The threshold for a drill this big. A conditioning drill lives in a
/// 10 m T or a 16 m star, and every run in it is under 0.10 of the pitch;
/// with the fixed threshold its thumbnail was a man and four cones and no
/// arrows at all. Scaled to the drill's own extent below 0.45 of the pitch
/// (the window's minimum), the T-run's shuffles are runs and the rondo's
/// shuffles still are not.
double _runMinFor(double extent) =>
    extent >= 0.45 ? _kRunMin : _kRunMin * (extent / 0.45) * 0.9;

/// One thing on the pitch and where it goes, in pitch-fraction coordinates.
class _Mark {
  final Offset at;
  final List<Offset> run;
  final _Kind kind;
  final String label;
  final double runMin;
  const _Mark(this.at, this.run, this.kind, this.label,
      [this.runMin = _kRunMin]);

  /// A real run, not an adjustment. Judged by how far the run gets from
  /// the start, not by where it ends: a shuttle that comes back to its cone
  /// ends where it began and is still ten metres of running.
  bool get runs =>
      run.isNotEmpty &&
      run.map((p) => (p - at).distance).reduce(math.max) >= runMin;

  /// Where a diagram draws this person. A real run ends where it ends —
  /// a pass onto a runner goes to where he arrives, and a pass after a carry
  /// leaves from where the carry stopped. A nudge (the ring drills' small
  /// radial shuffles) is not a run and does not move the mark.
  Offset get shown => runs ? run.last : at;
}

/// A pass: from one player's centre to the next, in pitch fractions.
class _Pass {
  final Offset from;
  final Offset to;
  const _Pass(this.from, this.to);
}

/// The drill, read once from its board and turned into the things a diagram
/// draws: people, where each of them runs, the passes between them, and the
/// window of pitch that holds it all.
class _Scene {
  final List<_Mark> marks;
  final List<_Pass> passes;
  final Offset? ball;
  final Rect window;

  /// The shirts the drill's own route names — the ones its sentence is
  /// about, and so the ones worth a number in a picture this small.
  final Set<String> named;

  const _Scene(this.marks, this.passes, this.ball, this.window, this.named);

  static _Scene read(Drill drill, Rect pitch) {
    final board = drill.board;
    final w = (board['canvasWidth'] as num?)?.toDouble() ?? 1000.0;
    final h = (board['canvasHeight'] as num?)?.toDouble() ?? 1500.0;
    final players = board['players'];
    if (players is! List || w <= 0 || h <= 0 ||
        pitch.width <= 0 || pitch.height <= 0) {
      return const _Scene([], [], null, Rect.fromLTWH(0, 0, 1, 1), {});
    }

    Offset? point(dynamic raw) {
      if (raw is! List || raw.length < 2) return null;
      final x = (raw[0] as num?)?.toDouble();
      final y = (raw[1] as num?)?.toDouble();
      if (x == null || y == null) return null;
      return Offset((x / w - pitch.left) / pitch.width,
          (y / h - pitch.top) / pitch.height);
    }

    // How much of the pitch the drill uses, for the run threshold.
    var lo = const Offset(2, 2), hi = const Offset(-1, -1);
    for (final raw in players) {
      if (raw is! Map) continue;
      for (final pt in [raw['position'], ...(raw['moves'] as List? ?? const [])]) {
        final p = point(pt);
        if (p == null) continue;
        lo = Offset(math.min(lo.dx, p.dx), math.min(lo.dy, p.dy));
        hi = Offset(math.max(hi.dx, p.dx), math.max(hi.dy, p.dy));
      }
    }
    final runMin = _runMinFor(math.max(hi.dx - lo.dx, hi.dy - lo.dy));

    final marks = <_Mark>[];
    List<Offset>? ballPath;
    for (final raw in players) {
      if (raw is! Map) continue;
      final at = point(raw['position']);
      if (at == null) continue;
      final run = <Offset>[
        for (final mv in (raw['moves'] as List? ?? const []))
          if (point(mv) case final p?) p,
      ];
      // PlayerTeam is serialised as its index: 0 home, 1 away, 2 the
      // equipment that is not a person. markerShape 0 among those is the
      // ball; anything else is a cone, a ladder, a hurdle.
      final team = raw['team'];
      final label = (raw['label'] as String? ?? '').trim();
      if (team == 0) {
        marks.add(_Mark(at, run, _Kind.home, label, runMin));
      } else if (team == 1) {
        marks.add(_Mark(at, run, _Kind.away, label, runMin));
      } else if (raw['markerShape'] == 0) {
        ballPath ??= [at, ...run];
      } else {
        marks.add(_Mark(at, const [], _Kind.gear, ''));
      }
    }

    // Passes come from the route the drill declares for itself — "Ball
    // path: 1 → 2 → 3 → 4 → 1", in shirt numbers — not from guessing which
    // person each stop of the ball's path is nearest to. Guessing snapped a
    // rondo's passes into the defenders, who move toward the ball line
    // precisely because they are trying to cut it out, and it assumed a
    // player's k-th move happens on beat k, which nothing guarantees. The
    // declaration is exact and it is what the coach reads on the page.
    //
    // A stop that is not a shirt number — "goal", "basket", "net" — is a
    // shot or a delivery to space: the ball's own last point is used, so the
    // arrow still shows where it went.
    final people = marks.where((m) => m.kind != _Kind.gear).toList();
    final passes = <_Pass>[];
    Offset? ball;
    final route = _route(drill);
    if (route.isNotEmpty && people.isNotEmpty) {
      _Mark? holder;
      final side = () {
        for (final m in people) {
          if (m.label == route.first) return m.kind;
        }
        return _Kind.home;
      }();
      _Mark? byLabel(String l) {
        for (final m in people) {
          if (m.kind == side && m.label == l) return m;
        }
        return null;
      }

      Offset? prev;
      for (var i = 0; i < route.length; i++) {
        final m = byLabel(route[i]);
        final Offset? here;
        if (m != null) {
          // The passer leaves from where he is when he passes: his start,
          // or the end of the carry that brought him here.
          here = i == 0 ? m.at : m.shown;
          holder ??= m;
        } else if (ballPath != null && ballPath.isNotEmpty) {
          here = ballPath.last;
        } else {
          here = null;
        }
        if (here == null) continue;
        if (i == 0) {
          ball = here;
        } else if (prev != null && (here - prev).distance > 0.01) {
          passes.add(_Pass(prev, here));
        }
        prev = here;
      }
    } else if (ballPath != null && ballPath.isNotEmpty) {
      // No declared route — a carry, a shot from a standing start. The ball
      // is drawn where it begins and the runs say the rest.
      ball = ballPath.first;
    }

    return _Scene(marks, passes, ball, _window(marks, passes, ball),
        route.toSet());
  }

  /// The shirt numbers the ball visits, in order, from the drill's own note.
  ///
  /// Read from the English note because that locale always exists and the
  /// numbers are the same in every language. The line is the one the
  /// generator writes as "Ball path: 1 → 2 → 3"; a drill with no passes — a
  /// slalom, a shooting drill from a standing start — has no such line.
  static List<String> _route(Drill drill) {
    final note = drill.note['en'] ?? drill.note.values.firstOrNull ?? '';
    for (final raw in note.split('\n')) {
      if (!raw.contains('→')) continue;
      final body = raw.contains(':') ? raw.split(':').sublist(1).join(':') : raw;
      return [
        for (final t in body.split('→'))
          if (t.trim().isNotEmpty) t.trim(),
      ];
    }
    return const [];
  }

  /// The part of the pitch this drill actually uses.
  ///
  /// Square in this space, which is what keeps the picture undistorted: both
  /// axes run 0..1 across a box that is already the sport's proportions. And
  /// never tighter than 45% of the pitch — a two-player drill blown up to
  /// fill the thumbnail would say those two were standing forty metres
  /// apart.
  static Rect _window(List<_Mark> marks, List<_Pass> passes, Offset? ball) {
    final pts = <Offset>[
      for (final m in marks) ...[m.at, ...m.run],
      for (final p in passes) ...[p.from, p.to],
      if (ball != null) ball,
    ];
    if (pts.isEmpty) return const Rect.fromLTWH(0, 0, 1, 1);
    var left = pts.map((p) => p.dx).reduce(math.min);
    var right = pts.map((p) => p.dx).reduce(math.max);
    var top = pts.map((p) => p.dy).reduce(math.min);
    var bottom = pts.map((p) => p.dy).reduce(math.max);
    // Room for the tokens, drawn centred on their point.
    const pad = 0.10;
    left -= pad;
    right += pad;
    top -= pad;
    bottom += pad;
    // Never tighter than 45% of the pitch for a drill that uses the
    // pitch — but a conditioning drill in a 10 m T is allowed to fill
    // the picture; at 45% it was a man and four dots in one corner.
    final extent = math.max(right - left, bottom - top) - 2 * pad;
    final floor = extent < 0.25 ? 0.28 : 0.45;
    final span = math.max(math.max(right - left, bottom - top), floor)
        .clamp(0.0, 1.0);
    var rect = Rect.fromCenter(
        center: Offset((left + right) / 2, (top + bottom) / 2),
        width: span,
        height: span);
    // Slide back inside the pitch rather than shrinking: a drill in the
    // corner should be framed on the corner, not zoomed out to re-centre.
    // "Inside" allows a strip beyond the lines, because a corner taker or
    // a thrower stands outside them and is part of the picture; the
    // strip is only as wide as those people need.
    final lo = math.min(0.0, math.min(left + pad, top + pad) - 0.02);
    final hiX = math.max(1.0, right - pad + 0.02);
    final hiY = math.max(1.0, bottom - pad + 0.02);
    if (rect.width >= hiX - lo) {
      rect = Rect.fromLTWH(lo, rect.top, hiX - lo, rect.height);
    } else if (rect.left < lo) {
      rect = rect.translate(lo - rect.left, 0);
    } else if (rect.right > hiX) {
      rect = rect.translate(hiX - rect.right, 0);
    }
    if (rect.height >= hiY - lo) {
      rect = Rect.fromLTWH(rect.left, lo, rect.width, hiY - lo);
    } else if (rect.top < lo) {
      rect = rect.translate(0, lo - rect.top);
    } else if (rect.bottom > hiY) {
      rect = rect.translate(0, hiY - rect.bottom);
    }
    return rect;
  }
}

class _ThumbPainter extends CustomPainter {
  final _Scene scene;

  /// A drill run off the pitch — a gym circuit, a classroom walk-through —
  /// gets the neutral ground rather than turf it never touches.
  final bool offSurface;

  /// The ambient text style, for the shirt numbers: a bare TextSpan names no
  /// font family, and in the renderer that means the box font.
  final TextStyle base;

  const _ThumbPainter(this.scene, this.offSurface, this.base);

  Offset _at(Offset p, Size size) => Offset(
        (p.dx - scene.window.left) / scene.window.width * size.width,
        (p.dy - scene.window.top) / scene.window.height * size.height,
      );

  @override
  void paint(Canvas canvas, Size size) {
    // Always the turf and its lines: a drill whose taker stands outside
    // the corner flag is still played on a pitch, and the lines are what
    // show him to be outside it.
    canvas.drawRect(Offset.zero & size, Paint()..color = T.turf);

    final unit = size.shortestSide;
    final tokenR = unit * 0.10;

    // ── markings, barely there ──────────────────────────────────────────
    // Drawn in pitch coordinates and cropped with everything else, so a
    // drill framed on one corner still shows the touchline it is played
    // against. Faint, because they are context and the arrows are content.
    {
      final line = Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawRect(
          Rect.fromPoints(_at(Offset.zero, size), _at(const Offset(1, 1), size)),
          line);
      canvas.drawLine(_at(const Offset(0, 0.5), size),
          _at(const Offset(1, 0.5), size), line);
      canvas.drawCircle(_at(const Offset(0.5, 0.5), size),
          0.135 / scene.window.width * size.width, line);
    }

    // ── cones and gear, under everything ────────────────────────────────
    for (final m in scene.marks.where((m) => m.kind == _Kind.gear)) {
      final at = _at(m.at, size);
      final s = unit * 0.05;
      canvas.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - s)
          ..lineTo(at.dx + s, at.dy + s)
          ..lineTo(at.dx - s, at.dy + s)
          ..close(),
        Paint()..color = const Color(0xFFE0703A),
      );
    }

    // ── runs: dashed, in the runner's colour, with an arrowhead ─────────
    for (final m in scene.marks.where((m) => m.run.isNotEmpty)) {
      if (!m.runs) continue;
      final colour = (m.kind == _Kind.home ? T.home : T.away);
      final paint = Paint()
        ..color = colour.withValues(alpha: 0.9)
        ..strokeWidth = unit * 0.026
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final pts = [m.at, ...m.run].map((p) => _at(p, size)).toList();
      // Start at the edge of the token, not its centre.
      pts[0] = _shorten(pts[0], pts[1], tokenR);
      for (var i = 1; i < pts.length; i++) {
        _dashed(canvas, pts[i - 1], pts[i], paint, unit * 0.06, unit * 0.04);
      }
      _head(canvas, pts[pts.length - 2], pts.last, paint..style = PaintingStyle.fill, unit * 0.075);
    }

    // ── passes: solid white, player to player, with an arrowhead ────────
    final pass = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = unit * 0.03
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final p in scene.passes) {
      final a = _shorten(_at(p.from, size), _at(p.to, size), tokenR);
      final b = _shorten(_at(p.to, size), _at(p.from, size), tokenR * 1.15);
      canvas.drawLine(a, b, pass);
      _head(canvas, a, b, Paint()..color = pass.color, unit * 0.08);
    }

    // ── people: a filled disc with a dark rim, so two of them touching are
    //    still two ────────────────────────────────────────────────────────
    final rim = Paint()
      ..color = const Color(0xCC0B272A)
      ..strokeWidth = unit * 0.018
      ..style = PaintingStyle.stroke;
    for (final m in scene.marks.where((m) => m.kind != _Kind.gear)) {
      final at = _at(m.at, size);
      canvas.drawCircle(at, tokenR,
          Paint()..color = m.kind == _Kind.home ? T.home : T.away);
      canvas.drawCircle(at, tokenR, rim);

      // A shirt number on the people the drill's sentence names — the
      // passers, the receivers, anyone with a real run. "7 passes to 2" is
      // unreadable against a picture where nobody is 7 or 2. Everyone else
      // stays a plain disc: at this size a number in every circle is texture,
      // not information.
      // A lone player needs no number either: there is nobody to tell apart.
      final wanted = m.label.isNotEmpty &&
          scene.marks.where((o) => o.kind == m.kind).length > 1 &&
          (scene.named.contains(m.label) || m.runs);
      if (wanted) {
        final tp = TextPainter(
          text: TextSpan(
            text: m.label,
            // Merged onto the ambient style so it inherits whatever family
            // the app (or the renderer) has set; a bare TextSpan names none.
            style: base.copyWith(
              color: Colors.white,
              fontSize: tokenR * (m.label.length > 1 ? 1.05 : 1.35),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // ── the ball, where it starts ───────────────────────────────────────
    if (scene.ball != null) {
      final at = _at(scene.ball!, size);
      // Beside its holder rather than on him, so both are visible.
      final b = Offset(at.dx + tokenR * 1.05, at.dy + tokenR * 1.05);
      canvas.drawCircle(b, unit * 0.045, Paint()..color = Colors.white);
      canvas.drawCircle(b, unit * 0.045, rim);
    }
  }

  /// [a] moved toward [b] by [by].
  static Offset _shorten(Offset a, Offset b, double by) {
    final d = b - a;
    final len = d.distance;
    if (len <= by) return a;
    return a + d / len * by;
  }

  static void _dashed(Canvas canvas, Offset a, Offset b, Paint paint,
      double dash, double gap) {
    final d = b - a;
    final len = d.distance;
    if (len < 1e-3) return;
    final dir = d / len;
    var t = 0.0;
    while (t < len) {
      final s = a + dir * t;
      final e = a + dir * math.min(t + dash, len);
      canvas.drawLine(s, e, paint);
      t += dash + gap;
    }
  }

  /// A small filled triangle at [tip], pointing along [from]→[tip].
  static void _head(Canvas canvas, Offset from, Offset tip, Paint paint,
      double size) {
    final d = tip - from;
    if (d.distance < 1e-3) return;
    final dir = d / d.distance;
    final n = Offset(-dir.dy, dir.dx);
    final base = tip - dir * size;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx + n.dx * size * 0.55, base.dy + n.dy * size * 0.55)
        ..lineTo(base.dx - n.dx * size * 0.55, base.dy - n.dy * size * 0.55)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.scene.marks.length != scene.marks.length ||
      old.scene.passes.length != scene.passes.length ||
      old.scene.window != scene.window ||
      old.offSurface != offSurface;
}
