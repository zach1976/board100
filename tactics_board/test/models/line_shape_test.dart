import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/drawing_stroke.dart';
import 'package:tactics_board/models/tactic_meta.dart';
import 'package:tactics_board/state/tactics_state.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('DrawingStroke shape', () {
    test('defaults to freehand', () {
      expect(DrawingStroke(id: '1', points: []).shape, LineShape.freehand);
    });

    test('survives a toJson/fromJson round trip', () {
      final s = DrawingStroke(
        id: 'a',
        points: [const Offset(0, 0), const Offset(10, 10)],
        style: StrokeStyle.dashed,
        arrow: ArrowStyle.tbar,
        shape: LineShape.wavy,
      );
      final back = DrawingStroke.fromJson(s.toJson());
      expect(back.shape, LineShape.wavy);
      expect(back.arrow, ArrowStyle.tbar);
      expect(back.style, StrokeStyle.dashed);
    });

    test('legacy payload without a shape key loads as freehand', () {
      final json = DrawingStroke(id: 'a', points: [const Offset(0, 0)]).toJson()
        ..remove('shape');
      expect(DrawingStroke.fromJson(json).shape, LineShape.freehand);
    });

    test('an out-of-range enum index falls back instead of throwing', () {
      final json = DrawingStroke(id: 'a', points: [const Offset(0, 0)]).toJson()
        ..['shape'] = 99
        ..['arrow'] = 42;
      final back = DrawingStroke.fromJson(json);
      expect(back.shape, LineShape.freehand);
      expect(back.arrow, ArrowStyle.end);
    });

    test('existing arrow indices keep their meaning', () {
      // Boards saved before cross/tbar existed encoded none/end/both as 0/1/2.
      expect(ArrowStyle.values[0], ArrowStyle.none);
      expect(ArrowStyle.values[1], ArrowStyle.end);
      expect(ArrowStyle.values[2], ArrowStyle.both);
    });
  });

  group('straight strokes collapse to their endpoints', () {
    TacticsState draw(LineShape shape) {
      final s = TacticsState()..setLineShape(shape);
      s.startStroke(const Offset(0, 0));
      s.addPoint(const Offset(5, 40));
      s.addPoint(const Offset(10, 0));
      s.endStroke();
      return s;
    }

    test('straight keeps only first and last point', () {
      final s = draw(LineShape.straight);
      expect(s.strokes.single.points, [const Offset(0, 0), const Offset(10, 0)]);
    });

    test('freehand keeps every point', () {
      expect(draw(LineShape.freehand).strokes.single.points.length, 3);
    });

    test('wavy keeps every point', () {
      expect(draw(LineShape.wavy).strokes.single.points.length, 3);
    });

    test('a collapsed stroke still hit-tests along its visible line', () {
      final s = draw(LineShape.straight);
      // Midpoint of the rendered line, far from the discarded (5,40) bulge.
      expect(s.hitTestStroke(const Offset(5, 0)), isNotNull);
      expect(s.hitTestStroke(const Offset(5, 40)), isNull);
    });

    test('the default line shape is straight', () {
      expect(TacticsState().lineShape, LineShape.straight);
    });

    test('a jittery freehand drag meant to be straight simplifies away', () {
      final s = TacticsState()..setLineShape(LineShape.freehand);
      s.startStroke(const Offset(0, 0));
      // A nearly-straight drag with sub-pixel wobble (all within ~1px of the
      // chord) — the kind of hand noise that used to render as a wavy curve.
      s.addPoint(const Offset(25, 1));
      s.addPoint(const Offset(50, 0));
      s.addPoint(const Offset(75, 1));
      s.addPoint(const Offset(100, 0));
      s.endStroke();
      expect(s.strokes.single.points, [const Offset(0, 0), const Offset(100, 0)]);
    });

    test('a deliberately curved freehand drag keeps its bend', () {
      final s = TacticsState()..setLineShape(LineShape.freehand);
      s.startStroke(const Offset(0, 0));
      s.addPoint(const Offset(50, 40)); // well past the 3px threshold
      s.addPoint(const Offset(100, 0));
      s.endStroke();
      expect(s.strokes.single.points.length, greaterThan(2));
    });
  });

  group('TacticMeta', () {
    test('fromJson takes the name from the filename, not the payload', () {
      final meta = TacticMeta.fromJson(
        {'name': 'stale', 'folder': 'Drills'},
        name: 'Press Break',
      );
      expect(meta.name, 'Press Break');
      expect(meta.folder, 'Drills');
    });

    test('a payload with no metadata yields empty defaults', () {
      final meta = TacticMeta.fromJson({}, name: 'Old Board');
      expect(meta.folder, '');
      expect(meta.description, '');
      expect(meta.coachingPoints, '');
      expect(meta.isEmpty, isTrue);
    });

    test('round trips through json', () {
      final now = DateTime(2026, 7, 10, 12, 30);
      final meta = TacticMeta(
        name: 'Zone',
        folder: 'Defence',
        description: '2-3 zone',
        coachingPoints: 'Hands up',
        createdAt: now,
        updatedAt: now,
      );
      final back = TacticMeta.fromJson(meta.toJson(), name: 'Zone');
      expect(back.folder, 'Defence');
      expect(back.description, '2-3 zone');
      expect(back.coachingPoints, 'Hands up');
      expect(back.createdAt, now);
      expect(back.updatedAt, now);
    });

    test('copyWith preserves createdAt', () {
      final meta = TacticMeta.initial('a', now: DateTime(2020));
      final later = meta.copyWith(updatedAt: DateTime(2026));
      expect(later.createdAt, DateTime(2020));
      expect(later.updatedAt, DateTime(2026));
    });
  });
}
