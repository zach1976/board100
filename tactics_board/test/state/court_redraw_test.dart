import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// Tennis, beach tennis and volleyball are drawn at 0.84 of the board
/// instead of 0.85, so a far-side man can stand with his feet behind the
/// baseline. A board saved on the old court opens with everybody on the
/// same lines; one saved since carries "court": 2 and does not move.
/// (Pickleball's own redraw, "pbCourt", is pickleball_court_test.)
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const canvas = Size(402, 730);
  const sports = {
    SportType.tennis: 0.85,
    SportType.beachTennis: 0.85,
    SportType.volleyball: 0.85,
  };

  // SportType.fieldRect as it was, at the old scale.
  Rect oldCourt(SportType sport, Size s, double scale) {
    final now = sport.fieldRect(s);
    final aspect = now.width / now.height;
    double cw, ch;
    if (s.width / s.height > aspect) {
      ch = s.height * scale;
      cw = ch * aspect;
    } else {
      cw = s.width * scale;
      ch = cw / aspect;
    }
    return Rect.fromLTWH((s.width - cw) / 2, (s.height - ch) / 2, cw, ch);
  }

  Offset onCourt(Rect r, double x, double y) =>
      Offset(r.left + x * r.width, r.top + y * r.height);

  Offset fractions(SportType sport, Offset p, Size s) {
    final r = sport.fieldRect(s);
    return Offset((p.dx - r.left) / r.width, (p.dy - r.top) / r.height);
  }

  Map<String, dynamic> person(String id, Offset at,
          [List<Offset> moves = const []]) =>
      {
        'id': id,
        'label': id,
        'team': 0,
        'sportType': null,
        'position': [at.dx, at.dy],
        'scale': 1.0,
        'moves': [for (final m in moves) [m.dx, m.dy]],
        'movePhases': [for (var i = 0; i < moves.length; i++) i],
      };

  Map<String, dynamic> board(SportType sport, Rect r, Size s,
          {bool marked = false}) =>
      {
        'sportType': sport.index,
        'players': [
          person('srv', onCourt(r, 0.57, 1.043), [onCourt(r, 0.5, 0.6)]),
          person('ret', onCourt(r, 0.24, -0.043)),
          person('post', onCourt(r, 1.0, 0.5)),
        ],
        'strokes': [
          {
            'id': 's',
            'points': [
              [onCourt(r, 0, 0).dx, onCourt(r, 0, 0).dy],
              [onCourt(r, 1, 1).dx, onCourt(r, 1, 1).dy],
            ],
            'color': 0xFFFFFFFF,
            'width': 3.0,
          }
        ],
        'canvasWidth': s.width,
        'canvasHeight': s.height,
        if (marked) 'court': 2,
      };

  void expectAt(SportType sport, TacticsState st, String id, double x,
      double y) {
    final p = fractions(
        sport, st.players.firstWhere((p) => p.id == id).position, canvas);
    expect(p.dx, closeTo(x, 1e-6), reason: '${sport.name} $id across');
    expect(p.dy, closeTo(y, 1e-6), reason: '${sport.name} $id down');
  }

  for (final e in sports.entries) {
    final sport = e.key;
    test('${sport.name}: the court is 0.84, with a figure of room behind '
        'the far baseline', () {
      final now = sport.fieldRect(canvas);
      expect(now.height, closeTo(730 * 0.84, 1e-6));
      expect(now.height, lessThan(oldCourt(sport, canvas, e.value).height));
      // a whole figure (52pt) standing with his feet 3pt behind it
      expect(now.top, greaterThan(52 + 3));
      expect(TacticsState.kCourtRedraws[sport], ('court', 2, e.value));
    });

    for (final saved in const [Size(402, 730), Size(1000, 1500), Size(820, 1060)]) {
      test('${sport.name}: a board from the old court keeps every line on '
          '${saved.width}x${saved.height}', () {
        final st = TacticsState(sportType: sport, preview: true)
          ..setCanvasSizeSilent(canvas);
        st.loadFromJson(board(sport, oldCourt(sport, saved, e.value), saved));
        expectAt(sport, st, 'srv', 0.57, 1.043);
        expectAt(sport, st, 'ret', 0.24, -0.043);
        expectAt(sport, st, 'post', 1.0, 0.5);
        final run = fractions(sport,
            st.players.firstWhere((p) => p.id == 'srv').moves.single, canvas);
        expect(run.dx, closeTo(0.5, 1e-6));
        expect(run.dy, closeTo(0.6, 1e-6));
        final pts = [
          for (final p in st.strokes.single.points) fractions(sport, p, canvas)
        ];
        if (saved == canvas) {
          expect(pts.first.dx, closeTo(0, 1e-6));
          expect(pts.last.dy, closeTo(1, 1e-6));
        }
      });
    }

    test('${sport.name}: a board on the new court does not move, and says '
        'so again', () {
      final st = TacticsState(sportType: sport, preview: true)
        ..setCanvasSizeSilent(canvas);
      st.loadFromJson(
          board(sport, sport.fieldRect(canvas), canvas, marked: true));
      expectAt(sport, st, 'ret', 0.24, -0.043);
      final out = st.toJson();
      expect(out['court'], 2);
      expect(out.containsKey('pbCourt'), isFalse);
      final again = TacticsState(sportType: sport, preview: true)
        ..setCanvasSizeSilent(canvas)
        ..loadFromJson(out);
      expectAt(sport, again, 'ret', 0.24, -0.043);
    });

    test('${sport.name}: a new page says which court it is on', () {
      final st = TacticsState(sportType: sport, preview: true)
        ..setCanvasSizeSilent(canvas);
      st.addPage();
      expect(st.toJson()['pages'][1]['court'], 2);
    });
  }

  test('badminton and the other sports are not redrawn: no key, no move', () {
    for (final sport in [SportType.badminton, SportType.soccer]) {
      final st = TacticsState(sportType: sport, preview: true)
        ..setCanvasSizeSilent(canvas);
      st.loadFromJson({
        'sportType': sport.index,
        'players': [person('p', const Offset(100, 200))],
        'strokes': const [],
        'canvasWidth': canvas.width,
        'canvasHeight': canvas.height,
      });
      expect(st.players.firstWhere((p) => p.id == 'p').position,
          const Offset(100, 200));
      expect(st.toJson().containsKey('court'), isFalse);
    }
  });
}
