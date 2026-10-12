import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// The water polo pool went from 30 m to the 25 m World Aquatics sets.
/// A board saved on the 30 m pool must open with everybody on the same
/// lines — goal, 2 m, 6 m, halfway — not stretched or squashed.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const canvas = Size(402, 730);

  // SportType.fieldRect as it was for the 30 m pool (aspect 20/30, 0.88).
  Rect oldPool(Size s) {
    const aspect = 20 / 30;
    double cw, ch;
    if (s.width / s.height > aspect) {
      ch = s.height * 0.88;
      cw = ch * aspect;
    } else {
      cw = s.width * 0.88;
      ch = cw / aspect;
    }
    return Rect.fromLTWH((s.width - cw) / 2, (s.height - ch) / 2, cw, ch);
  }

  // A point x metres across, y metres from the top goal line.
  Offset onOld(Size s, double x, double y) {
    final r = oldPool(s);
    return Offset(r.left + x / 20 * r.width, r.top + y / 30 * r.height);
  }

  // Where a point on the 25 m pool lands, back in metres.
  Offset metres(Offset p, Size s) {
    final r = SportType.waterPolo.fieldRect(s);
    return Offset((p.dx - r.left) / r.width * 20,
        (p.dy - r.top) / r.height * 25);
  }

  Map<String, dynamic> person(String id, Offset at, [List<Offset> moves = const []]) => {
        'id': id,
        'label': id,
        'team': 0,
        'sportType': null,
        'position': [at.dx, at.dy],
        'scale': 1.0,
        'moves': [for (final m in moves) [m.dx, m.dy]],
        'movePhases': [for (var i = 0; i < moves.length; i++) i],
      };

  Map<String, dynamic> savedOn30(Size s) => {
        'sportType': SportType.waterPolo.index,
        'players': [
          person('post', onOld(s, 7, 2.5)),              // just outside 2 m
          person('cf', onOld(s, 10, 3), [onOld(s, 10, 6)]), // swims to 6 m
          person('half', onOld(s, 4, 15)),             // on halfway
          person('far6', onOld(s, 16, 24)),            // the other 6 m line
          person('gk', onOld(s, 10, 29)),              // 1 m off the far goal
        ],
        'strokes': [
          {
            'id': 's1',
            'points': [
              [onOld(s, 2, 5).dx, onOld(s, 2, 5).dy],
              [onOld(s, 18, 25).dx, onOld(s, 18, 25).dy],
            ],
            'color': 0xFFFFFFFF,
            'width': 3.0,
            'style': 0,
            'arrow': 1,
            'shape': 0,
            'startPhase': 0,
            'endPhase': 0,
          },
        ],
        'canvasWidth': s.width,
        'canvasHeight': s.height,
      };

  void expectAt(TacticsState st, String id, double x, double y, Size s) {
    final p = st.players.firstWhere((p) => p.id == id);
    final m = metres(p.position, s);
    expect(m.dx, closeTo(x, 0.01), reason: '$id across');
    expect(m.dy, closeTo(y, 0.01), reason: '$id down the pool');
  }

  test('legacy metres keep every line', () {
    expect(TacticsState.legacyPoolMetres(0), 0);
    expect(TacticsState.legacyPoolMetres(2), 2);
    expect(TacticsState.legacyPoolMetres(5), 5);
    expect(TacticsState.legacyPoolMetres(6), 6);
    expect(TacticsState.legacyPoolMetres(15), 12.5);
    expect(TacticsState.legacyPoolMetres(24), 19);
    expect(TacticsState.legacyPoolMetres(28), 23);
    expect(TacticsState.legacyPoolMetres(30), 25);
    expect(TacticsState.legacyPoolMetres(-0.5), -0.5);
    expect(TacticsState.legacyPoolMetres(31), 26);
  });

  for (final saved in [canvas, const Size(1000, 1500), const Size(900, 700)]) {
    test('a board saved on the 30 m pool at $saved opens on the same lines',
        () {
      final st = TacticsState(sportType: SportType.waterPolo, preview: true)
        ..setCanvasSizeSilent(canvas);
      st.loadFromJson(savedOn30(saved));
      expectAt(st, 'post', 7, 2.5, canvas);
      expectAt(st, 'cf', 10, 3, canvas);
      expectAt(st, 'half', 4, 12.5, canvas);
      expectAt(st, 'far6', 16, 19, canvas);
      expectAt(st, 'gk', 10, 24, canvas);
      final cf = st.players.firstWhere((p) => p.id == 'cf');
      final to = metres(cf.moves.single, canvas);
      expect(to.dy, closeTo(6, 0.01), reason: 'his run still ends on 6 m');
      // Drawn lines are moved onto the new pool in the canvas they were
      // saved on; carrying them to another canvas is not something a
      // board does for any sport (players only), so check them at home.
      final pts = [for (final p in st.strokes.single.points) metres(p, saved)];
      expect(pts.first.dy, closeTo(5, 0.01));
      expect(pts.last.dy, closeTo(20, 0.01), reason: 'far 5 m mark');
      expect(pts.last.dx, closeTo(18, 0.01));
    });
  }

  test('a board saved on the 25 m pool is not moved, and says so again', () {
    final st = TacticsState(sportType: SportType.waterPolo, preview: true)
      ..setCanvasSizeSilent(canvas);
    final r = SportType.waterPolo.fieldRect(canvas);
    final at = Offset(r.left + 0.35 * r.width, r.top + 0.1 * r.height);
    st.loadFromJson({
      'sportType': SportType.waterPolo.index,
      'players': [person('p', at)],
      'strokes': const [],
      'canvasWidth': canvas.width,
      'canvasHeight': canvas.height,
      'poolLength': 25,
    });
    expect(st.players.firstWhere((p) => p.id == 'p').position, at);
    final out = st.toJson();
    expect(out['poolLength'], 25);
    // and read back, it stays put: migrated once, never twice
    final again = TacticsState(sportType: SportType.waterPolo, preview: true)
      ..setCanvasSizeSilent(canvas)
      ..loadFromJson(out);
    expect(again.players.firstWhere((p) => p.id == 'p').position, at);
  });

  test('a migrated legacy board saves as 25 m and does not move again', () {
    final st = TacticsState(sportType: SportType.waterPolo, preview: true)
      ..setCanvasSizeSilent(canvas);
    st.loadFromJson(savedOn30(canvas));
    final out = st.toJson();
    expect(out['poolLength'], 25);
    final again = TacticsState(sportType: SportType.waterPolo, preview: true)
      ..setCanvasSizeSilent(canvas)
      ..loadFromJson(out);
    expectAt(again, 'half', 4, 12.5, canvas);
    expectAt(again, 'gk', 10, 24, canvas);
  });

  test('other sports never carry or read poolLength', () {
    final st = TacticsState(sportType: SportType.handball, preview: true)
      ..setCanvasSizeSilent(canvas);
    st.loadFromJson({
      'sportType': SportType.handball.index,
      'players': [person('p', const Offset(100, 200))],
      'strokes': const [],
      'canvasWidth': canvas.width,
      'canvasHeight': canvas.height,
    });
    expect(st.players.firstWhere((p) => p.id == 'p').position,
        const Offset(100, 200));
    expect(st.toJson().containsKey('poolLength'), isFalse);
  });
}
