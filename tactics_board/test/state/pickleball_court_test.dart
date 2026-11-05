import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// The pickleball court is drawn at 0.82 of the board instead of 0.88, so
/// a receiver can stand with his feet behind the far baseline. A board
/// saved on the old court must open with everybody on the same lines —
/// kitchen line, baseline, sideline — and a board saved since must not move.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const canvas = Size(402, 730);
  const kitchenNear = 0.5 + 2.13 / 13.41;

  // SportType.fieldRect as it was for the old court (0.88).
  Rect oldCourt(Size s) {
    const aspect = 6.1 / 13.41;
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

  Offset onCourt(Rect r, double x, double y) =>
      Offset(r.left + x * r.width, r.top + y * r.height);

  // Where a point lands on the current court, as court fractions.
  Offset fractions(Offset p, Size s) {
    final r = SportType.pickleball.fieldRect(s);
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

  Map<String, dynamic> savedOnOld(Size s) {
    final r = oldCourt(s);
    return {
      'sportType': SportType.pickleball.index,
      'players': [
        // on the near kitchen line, dinks to the far one
        person('k', onCourt(r, 0.3, kitchenNear), [onCourt(r, 0.7, 1 - kitchenNear)]),
        person('srv', onCourt(r, 0.72, 1.03)),       // behind the baseline
        person('ret', onCourt(r, 0.28, -0.02)),
        person('post', onCourt(r, 1.0, 0.5)),        // the right net post
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
    };
  }

  void expectAt(TacticsState st, String id, double x, double y, Size s) {
    final p = fractions(st.players.firstWhere((p) => p.id == id).position, s);
    expect(p.dx, closeTo(x, 1e-6), reason: '$id across');
    expect(p.dy, closeTo(y, 1e-6), reason: '$id down');
  }

  test('the court is smaller than it was, with room behind the far baseline', () {
    final now = SportType.pickleball.fieldRect(canvas);
    expect(now.height, closeTo(730 * 0.82, 1e-6));
    expect(now.height, lessThan(oldCourt(canvas).height));
    // room above the far baseline for a whole figure (52pt) standing
    // with his feet behind it
    expect(now.top, greaterThan(52 + 4));
  });

  for (final saved in const [Size(402, 730), Size(1000, 1500), Size(820, 1060)]) {
    test('a board from the old court keeps every line on ${saved.width}x${saved.height}', () {
      final st = TacticsState(sportType: SportType.pickleball, preview: true)
        ..setCanvasSizeSilent(canvas);
      st.loadFromJson(savedOnOld(saved));
      expectAt(st, 'k', 0.3, kitchenNear, canvas);
      final k = st.players.firstWhere((p) => p.id == 'k');
      final to = fractions(k.moves.single, canvas);
      expect(to.dx, closeTo(0.7, 1e-6));
      expect(to.dy, closeTo(1 - kitchenNear, 1e-6));
      expectAt(st, 'srv', 0.72, 1.03, canvas);
      expectAt(st, 'ret', 0.28, -0.02, canvas);
      expectAt(st, 'post', 1.0, 0.5, canvas);
    });
  }

  test('strokes from the old court follow it, on the canvas they were drawn on', () {
    final st = TacticsState(sportType: SportType.pickleball, preview: true)
      ..setCanvasSizeSilent(canvas);
    st.loadFromJson(savedOnOld(canvas));
    final pts = [for (final p in st.strokes.single.points) fractions(p, canvas)];
    expect(pts.first.dx, closeTo(0, 1e-6));
    expect(pts.first.dy, closeTo(0, 1e-6));
    expect(pts.last.dx, closeTo(1, 1e-6));
    expect(pts.last.dy, closeTo(1, 1e-6));
  });

  test('a board saved on the new court is not moved, and says so again', () {
    final st = TacticsState(sportType: SportType.pickleball, preview: true)
      ..setCanvasSizeSilent(canvas);
    final r = SportType.pickleball.fieldRect(canvas);
    final at = onCourt(r, 0.28, -0.05);
    st.loadFromJson({
      'sportType': SportType.pickleball.index,
      'players': [person('p', at)],
      'strokes': const [],
      'canvasWidth': canvas.width,
      'canvasHeight': canvas.height,
      'pbCourt': 2,
    });
    expect(st.players.firstWhere((p) => p.id == 'p').position, at);
    final out = st.toJson();
    expect(out['pbCourt'], 2);
    final again = TacticsState(sportType: SportType.pickleball, preview: true)
      ..setCanvasSizeSilent(canvas)
      ..loadFromJson(out);
    expect(again.players.firstWhere((p) => p.id == 'p').position, at);
  });

  test('a migrated legacy board saves as the new court and does not move again', () {
    final st = TacticsState(sportType: SportType.pickleball, preview: true)
      ..setCanvasSizeSilent(canvas);
    st.loadFromJson(savedOnOld(canvas));
    final out = st.toJson();
    expect(out['pbCourt'], 2);
    final again = TacticsState(sportType: SportType.pickleball, preview: true)
      ..setCanvasSizeSilent(canvas)
      ..loadFromJson(out);
    expectAt(again, 'ret', 0.28, -0.02, canvas);
    expectAt(again, 'k', 0.3, kitchenNear, canvas);
  });

  test('other sports never carry or read pbCourt', () {
    final st = TacticsState(sportType: SportType.badminton, preview: true)
      ..setCanvasSizeSilent(canvas);
    st.loadFromJson({
      'sportType': SportType.badminton.index,
      'players': [person('p', const Offset(100, 200))],
      'strokes': const [],
      'canvasWidth': canvas.width,
      'canvasHeight': canvas.height,
    });
    expect(st.players.firstWhere((p) => p.id == 'p').position,
        const Offset(100, 200));
    expect(st.toJson().containsKey('pbCourt'), isFalse);
  });

  test('a new page says which court it is on', () {
    // (tools/drills/engine.py to_display_frame writes it on every drill.)
    final st = TacticsState(sportType: SportType.pickleball, preview: true)
      ..setCanvasSizeSilent(canvas);
    st.addPage();
    expect(st.toJson()['pages'][1]['pbCourt'], 2);
  });
}
