import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// No preset may land two people inside each other.
///
/// Every full-squad preset used to: a 4-3-3 against a 4-3-3 put the two
/// centre forwards on the same point, and 4-2-3-1 did it to its own striker
/// and attacking midfielder, so a coach's first board opened with four
/// figures stacked on the halfway line. This drives the real placement —
/// both teams, the way the Add sheet does it — and measures what the painter
/// draws: the person's own 26 x 52 box, not the token's cell.
void main() {
  const figureW = 26.0, figureH = 52.0;
  // The board a phone draws, which is what the spacing is in terms of.
  const canvas = Size(386, 657);

  String? overlap(List<PlayerIcon> players) {
    final people =
        players.where((p) => !p.isMarker && !p.isBall).toList(growable: false);
    for (var i = 0; i < people.length; i++) {
      for (var j = i + 1; j < people.length; j++) {
        final a = people[i], b = people[j];
        final w = figureW * (a.scale + b.scale) / 2;
        final h = figureH * (a.scale + b.scale) / 2;
        final dx = (a.position.dx - b.position.dx).abs();
        final dy = (a.position.dy - b.position.dy).abs();
        if (dx < w && dy < h) {
          return '${a.label}@${a.position} and ${b.label}@${b.position} '
              '— dx=${dx.toStringAsFixed(1)} dy=${dy.toStringAsFixed(1)} '
              '(need dx>=$w or dy>=$h)';
        }
      }
    }
    return null;
  }

  // Water polo's 6v5 is the one that is meant to be crowded: it is a man-up
  // power play, six attackers packed round the 2m line against five, and the
  // preset draws them where a coach draws them. Spacing it out would be
  // drawing a different drill. Everything else must clear.
  // The other man-up shapes and the 3-3 set (three on the 2 m line) are
  // the same kind of board: bodies round the posts by design.
  const known = {
    'waterPolo': {
      'formation_6v5',
      'formation_6v5_33',
      'formation_6v5_umbrella',
      'formation_wp_33',
    }
  };

  test('no formation puts two figures inside each other', () {
    var checked = 0;
    for (final sport in SportType.values) {
      for (final f in sport.formations) {
        if (known[sport.name]?.contains(f.nameKey) ?? false) continue;
        final s = TacticsState(sportType: sport, preview: true);
        s.setCanvasSizeSilent(canvas);
        s.addTeamFromFormation(f, PlayerTeam.home);
        s.addTeamFromFormation(f, PlayerTeam.away);
        final bad = overlap(s.players);
        expect(bad, isNull,
            reason: '${sport.name}/${f.nameKey}: $bad');
        checked++;
        s.dispose();
      }
    }
    expect(checked, greaterThan(20));
  });
}
