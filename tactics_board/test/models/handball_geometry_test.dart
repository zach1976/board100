// Two rules every handball board must keep, checked on the shipped JSON
// (audit 2026-10-11): no field player stands inside a goal area at any step,
// and every shot ends in the goal mouth — between the posts, over the line.
//
// The boards are stored in the display frame (402 x 730) with the 20 x 40 m
// court drawn at 90% of the height, centred (see engine.court_rect).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

const double _cw = 730 * 0.90 * 0.5; // court width on the board
const double _ch = 730 * 0.90; // court height on the board
const double _left = (402 - _cw) / 2;
const double _top = (730 - _ch) / 2;

/// Board point to metres: x across the 20 m width, y down the 40 m length.
(double, double) _metres(List p) => (
      ((p[0] as num).toDouble() - _left) / _cw * 20,
      ((p[1] as num).toDouble() - _top) / _ch * 40,
    );

/// Inside either 6 m goal area: 6 m from the goal line between the posts
/// (8.5 and 11.5 m), 6 m from the nearer post beside them.
bool _inGoalArea(double x, double y) {
  for (final (goal, sign) in [(0.0, 1.0), (40.0, -1.0)]) {
    final d = (y - goal) * sign;
    if (d < -0.5) continue;
    if (x >= 8.5 && x <= 11.5) {
      if (d < 6) return true;
    } else {
      final post = x < 8.5 ? 8.5 : 11.5;
      if (sqrt(pow(x - post, 2) + d * d) < 6) return true;
    }
  }
  return false;
}

List _at(Map p, int step) {
  var at = p['position'] as List;
  final moves = (p['moves'] as List?) ?? const [];
  final phases = (p['movePhases'] as List?) ?? const [];
  for (var i = 0; i < moves.length; i++) {
    if ((phases[i] as num) <= step) at = moves[i] as List;
  }
  return at;
}

void main() {
  final drills = (jsonDecode(File('assets/drills/handball.json')
          .readAsStringSync())['drills'] as List)
      .cast<Map>();

  test('no field player inside a goal area at any step', () {
    final bad = <String>[];
    for (final d in drills) {
      final players = (d['board']['players'] as List).cast<Map>();
      final steps = [
        for (final p in players) ...((p['movePhases'] as List?) ?? const [])
      ];
      final last = steps.isEmpty ? 0 : steps.cast<num>().reduce(max).toInt();
      for (final p in players) {
        if (p['markerShape'] != 0 || p['sportType'] != null) continue;
        if (p['role'] == 'GK') continue;
        for (var s = -1; s <= last; s++) {
          final (x, y) = _metres(_at(p, s));
          if (_inGoalArea(x, y)) {
            bad.add('${d['id']} step ${s + 1}: ${p['label']} at '
                '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}) m');
          }
        }
      }
    }
    expect(bad, isEmpty);
  });

  test('every shot ends in the goal mouth', () {
    final bad = <String>[];
    for (final d in drills) {
      for (final b in (d['board']['players'] as List).cast<Map>()) {
        if (b['sportType'] == null) continue;
        final moves = (b['moves'] as List?) ?? const [];
        final holders = (b['moveHolders'] as List?) ?? const [];
        for (var i = 0; i < moves.length && i < holders.length; i++) {
          if (holders[i] != null) continue; // caught, not shot
          final (x, y) = _metres(moves[i] as List);
          if (y > 3 && y < 37) continue; // a pass into space, not at goal
          final inMouth = x > 8.6 &&
              x < 11.4 &&
              ((y > -0.6 && y <= 0.05) || (y >= 39.95 && y < 40.6));
          if (!inMouth) {
            bad.add('${d['id']} leg ${i + 1} ends at '
                '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}) m');
          }
        }
      }
    }
    expect(bad, isEmpty);
  });
}
