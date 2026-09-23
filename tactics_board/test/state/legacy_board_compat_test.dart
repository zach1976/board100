import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// Boards saved by the builds that are on the store still open.
///
/// The fixtures are not round-trips through today's toJson — that only
/// proves the current build agrees with itself. They are written out by hand
/// in the exact shape the older builds wrote (taken from their toJson at
/// ced2daa6, the 1.1.24 release, and from before 1.1.20's "rich save"), and
/// put on disk where those builds put them, then read through loadTactics —
/// the same path the app takes when a coach taps one under "my boards".
///
/// What each old shape lacks that today's writer adds:
///   1.1.24   no `pages`/`pageIndex`; players carry no `rotation`
///   <1.1.20  no `meta` wrapper; strokes carry a single `phase` instead of
///            `startPhase`/`endPhase`; players carry none of the later
///            optional fields (gender, markerShape, photoId, role, …)
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // path_provider has no plugin here, so _tacticsDir falls back to the
    // system temp directory; prefs are reached for on load.
    SharedPreferences.setMockInitialValues({});
  });

  Directory dir() =>
      Directory('${Directory.systemTemp.path}/tactics/${SportType.soccer.name}');

  Future<void> writeBoard(String name, Map<String, dynamic> payload) async {
    final d = dir();
    if (!await d.exists()) await d.create(recursive: true);
    await File('${d.path}/$name.json').writeAsString(jsonEncode(payload));
  }

  Future<void> removeBoard(String name) async {
    final f = File('${dir().path}/$name.json');
    if (await f.exists()) await f.delete();
  }

  test('a board saved by 1.1.24 opens with every player and line on it',
      () async {
    const name = 'legacy_compat_1_1_24';
    // Verbatim 1.1.24 shape: toJson + meta, one page at the top level.
    await writeBoard(name, {
      'sportType': SportType.soccer.index,
      'players': [
        {
          'id': 'p1',
          'label': '7',
          'team': 0,
          'sportType': null,
          'position': [120.0, 300.0],
          'scale': 1.0,
          'moves': [
            [160.0, 240.0],
            [200.0, 180.0],
          ],
          'movePhases': [0, 1],
          'moveColor': 0xFF3A7DFF,
          'customColor': null,
          'gender': 0,
          'markerShape': 0,
          'photoId': null,
          'role': 'CM',
          'attachedTo': null,
        },
        {
          'id': 'ball',
          'label': '',
          'team': 2,
          'sportType': SportType.soccer.index,
          'position': [130.0, 310.0],
          'scale': 1.0,
          'moves': <List<double>>[],
          'movePhases': <int>[],
          'moveColor': 0xFF3A7DFF,
          'customColor': null,
          'gender': 0,
          'markerShape': 0,
          'photoId': null,
          'role': null,
          'attachedTo': 'p1',
        },
      ],
      'strokes': [
        {
          'id': 's1',
          'points': [
            [50.0, 50.0],
            [90.0, 90.0],
            [130.0, 130.0],
          ],
          'color': 0xFFFFFFFF,
          'width': 3.0,
          'style': 0,
          'arrow': 1,
          'shape': 0,
          'startPhase': 0,
          'endPhase': 1,
        },
      ],
      'canvasWidth': 400.0,
      'canvasHeight': 700.0,
      'meta': {
        'name': name,
        'folder': 'Set pieces',
        'description': 'Near-post corner',
        'coachingPoints': 'Attack the ball',
        'createdAt': '2026-07-01T10:00:00.000',
        'updatedAt': '2026-07-02T10:00:00.000',
      },
    });
    addTearDown(() => removeBoard(name));

    final s = TacticsState(sportType: SportType.soccer, preview: true);
    await s.loadTactics(name);

    expect(s.pageCount, 1, reason: 'a pre-pages file is one page');
    expect(s.players.map((p) => p.id), ['p1', 'ball']);
    final p1 = s.players.first;
    expect(p1.label, '7');
    expect(p1.role, 'CM');
    expect(p1.moves.length, 2);
    expect(p1.movePhases, [0, 1]);
    expect(p1.rotation, 0, reason: 'no rotation in the file reads as none');
    expect(s.players.last.isBall, isTrue);
    expect(s.players.last.attachedTo, 'p1');
    expect(s.strokes.length, 1);
    expect(s.strokes.first.startPhase, 0);
    expect(s.strokes.first.endPhase, 1);
    expect(s.strokes.first.points.length, 3);
    expect(s.currentTacticName, name);
    expect(s.currentTacticMeta?.folder, 'Set pieces');
    expect(s.currentTacticMeta?.description, 'Near-post corner');
    expect(s.currentTacticMeta?.coachingPoints, 'Attack the ball');
  });

  test('a board saved before 1.1.20 opens: no meta, one-phase strokes',
      () async {
    const name = 'legacy_compat_pre_1_1_20';
    await writeBoard(name, {
      'sportType': SportType.soccer.index,
      'players': [
        {
          'id': 'p1',
          'label': '9',
          'team': 1,
          'position': [200.0, 350.0],
          'scale': 1.0,
          'moves': [
            [220.0, 300.0],
          ],
          'moveColor': 0xFFFF5A5F,
        },
      ],
      'strokes': [
        {
          'id': 's1',
          'points': [
            [10.0, 10.0],
            [60.0, 60.0],
          ],
          'color': 0xFFFFFF00,
          'width': 2.0,
          'style': 1,
          'arrow': 0,
          'shape': 0,
          'phase': 2,
        },
      ],
      'canvasWidth': 400.0,
      'canvasHeight': 700.0,
    });
    addTearDown(() => removeBoard(name));

    final s = TacticsState(sportType: SportType.soccer, preview: true);
    await s.loadTactics(name);

    expect(s.pageCount, 1);
    expect(s.players.length, 1);
    expect(s.players.first.label, '9');
    expect(s.players.first.moves.length, 1);
    // Loaded as written — no phase list — which is safe because every reader
    // of movePhases guards `i < movePhases.length ? movePhases[i] : i`, and
    // the painters call syncPhases() first, which numbers them:
    expect(s.players.first.movePhases, isEmpty);
    s.players.first.syncPhases();
    expect(s.players.first.movePhases, [0]);
    expect(s.strokes.length, 1);
    expect(s.strokes.first.startPhase, 2,
        reason: 'the single legacy phase becomes both ends');
    expect(s.strokes.first.endPhase, 2);
    expect(s.currentTacticName, name);
    // No meta in the file means none in memory either — that is by design,
    // the list gets defaults from readTacticMeta ?? initial. What matters is
    // that the coach can keep working on it: the next save writes a meta.
    expect(s.currentTacticMeta, isNull);
    await s.saveTactics(name);
    final meta = await s.readTacticMeta(name);
    expect(meta?.name, name, reason: 'saving the old file gives it a meta');
    final again = TacticsState(sportType: SportType.soccer, preview: true);
    await again.loadTactics(name);
    expect(again.players.first.label, '9',
        reason: 'and the re-saved file still opens with its content');
    expect(again.strokes.first.startPhase, 2);
  });

  test('the old file is listed under my boards by name', () async {
    const name = 'legacy_compat_listed';
    await writeBoard(name, {
      'sportType': SportType.soccer.index,
      'players': <Map<String, dynamic>>[],
      'strokes': <Map<String, dynamic>>[],
      'canvasWidth': 400.0,
      'canvasHeight': 700.0,
    });
    addTearDown(() => removeBoard(name));

    final s = TacticsState(sportType: SportType.soccer, preview: true);
    final names = (await s.listSavedTacticMetas()).map((m) => m.name);
    expect(names, contains(name));
  });
}
