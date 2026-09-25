// Every player's facing at every beat of every drill — computed by the app.
//
// The audit used to mirror boardHeading() in Python. Two things make that a
// losing game: the rule changes, and the app works in screen points while a
// board file is in board units, which are NOT scaled evenly (1000x1500 into
// 540x960) — so an angle measured on the file is not the angle the phone
// draws, and a mirror is wrong at every 22.5° boundary even when it is
// faithful. This runs the real rule through a real TacticsState and writes
// what it says; tools/facing_audit.py reads the numbers and judges them.
//
//     cd tactics_board && flutter test tool/facing_dump.dart
//         → tools/facing_headings.json
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

/// The phone's board, the size tactics_canvas lays out.
const kW = 540.0, kH = 960.0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dump every facing the board would draw', () async {
    final repo = Directory.current.parent;
    final drillDir = Directory('${Directory.current.path}/assets/drills');
    final out = <String, dynamic>{};
    final files = drillDir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      final sport = f.uri.pathSegments.last.replaceAll('.json', '');
      if (sport == 'index') continue;
      final drills = (jsonDecode(f.readAsStringSync())['drills'] as List);
      final rows = <Map<String, dynamic>>[];
      for (final dr in drills) {
        final state = TacticsState();
        state.loadFromJson(
            Map<String, dynamic>.from((dr as Map)['board'] as Map));
        state.setCanvasSizeSilent(const Size(kW, kH));
        final all = state.players;
        final people =
            all.where((p) => !p.isBall && !p.isMarker).toList(growable: false);
        final balls = all.where((p) => p.isBall).toList(growable: false);
        final steps = state.maxMoveSteps;
        List<double> xy(Offset o) => [o.dx, o.dy];
        rows.add({
          'id': dr['id'],
          'name': (dr['name'] as Map)['en'],
          'steps': steps,
          'ball': [
            for (var s = 0; s <= steps; s++)
              balls.isEmpty ? null : xy(ballPositionAt(all, balls.first, s)),
          ],
          'players': [
            for (final p in people)
              {
                'label': p.label.isEmpty ? p.id : p.label,
                'team': p.team.name,
                // null where the board gives no cue and the token falls back
                // to the team's default facing.
                'h': [
                  for (var s = 0; s <= steps; s++) boardHeading(all, p, s),
                ],
                'at': [for (var s = 0; s <= steps; s++) xy(standingAt(p, s))],
              },
          ],
        });
      }
      out[sport] = rows;
    }
    File('${repo.path}/tools/facing_headings.json')
        .writeAsStringSync(jsonEncode(out));
    // ignore: avoid_print
    print('wrote tools/facing_headings.json: '
        '${out.values.fold<int>(0, (a, b) => a + (b as List).length)} drills');
  });
}
