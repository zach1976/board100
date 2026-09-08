import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

/// A run that ends where another player is standing used to hide one of them
/// completely: the arrow arrived at what looked like a single token.
PlayerIcon _p(String id, Offset at) =>
    PlayerIcon(id: id, label: id, team: PlayerTeam.home, position: at);

PlayerIcon _marker(String id, Offset at) => PlayerIcon(
      id: id,
      label: '',
      team: PlayerTeam.neutral,
      position: at,
      markerShape: MarkerShape.cone,
    );

PlayerIcon _ball(String id, Offset at) => PlayerIcon(
      id: id,
      label: '',
      team: PlayerTeam.neutral,
      position: at,
      sportType: SportType.soccer,
    );

Offset _stored(PlayerIcon p) => p.position;

void main() {
  test('two players on the same point are pushed apart, symmetrically', () {
    final board = [_p('2', const Offset(200, 200)), _p('3', const Offset(200, 200))];
    final fan = fanOutOffsets(board, _stored);

    expect(fan.length, 2);
    // Opposite directions, equal distance: the pair straddles the real point
    // rather than one of them wandering off it.
    expect((fan['2']! + fan['3']!).distance, closeTo(0, 0.001));
    expect(fan['2']!.distance, closeTo(fan['3']!.distance, 0.001));
    // Far enough apart that both numbers can be read on a 44pt token.
    expect((fan['2']! - fan['3']!).distance, greaterThan(30));
  });

  test('players already apart are left exactly where they are', () {
    final board = [_p('2', const Offset(100, 100)), _p('3', const Offset(300, 300))];
    expect(fanOutOffsets(board, _stored), isEmpty);
  });

  test('the push ramps away to nothing, so no token pops at the threshold', () {
    double pushAt(double gap) {
      final fan = fanOutOffsets(
        [_p('2', const Offset(200, 200)), _p('3', Offset(200 + gap, 200))],
        _stored,
      );
      return fan.isEmpty ? 0 : fan['2']!.distance;
    }

    expect(pushAt(20), lessThan(pushAt(0)));
    expect(pushAt(39.5), lessThan(pushAt(20)));
    expect(pushAt(39.5), lessThan(1.0));
  });

  test('the fan never brings two players closer than they really are', () {
    // Re-placing the pair on a ring around their centre did exactly that:
    // at a 20pt gap it drew them 17pt apart. Any gap, drawn >= real.
    for (final gap in [0.0, 5.0, 12.0, 20.0, 30.0, 39.0]) {
      final board = [
        _p('2', const Offset(200, 200)),
        _p('3', Offset(200 + gap, 200)),
      ];
      final fan = fanOutOffsets(board, _stored);
      final drawn = ((board[0].position + (fan['2'] ?? Offset.zero)) -
              (board[1].position + (fan['3'] ?? Offset.zero)))
          .distance;
      expect(drawn, greaterThanOrEqualTo(gap - 0.001),
          reason: 'a $gap pt gap was drawn as $drawn');
    }
  });

  test('equipment and the ball are left alone — that arrangement is meant', () {
    final board = [
      _p('2', const Offset(200, 200)),
      _marker('cone', const Offset(200, 200)),
      _ball('ball', const Offset(200, 200)),
    ];
    // Only one subject in the cluster, so nothing moves at all.
    expect(fanOutOffsets(board, _stored), isEmpty);
  });

  test('three in a pile fan out as one group, not a pair and a stray', () {
    final board = [
      _p('2', const Offset(200, 200)),
      _p('3', const Offset(205, 200)),
      _p('4', const Offset(210, 200)),
    ];
    final fan = fanOutOffsets(board, _stored);
    expect(fan.length, 3);
    // Every pair ends up separated, which a pair-plus-stray would not manage.
    final at = {
      for (final p in board) p.id: p.position + fan[p.id]!,
    };
    for (final a in at.keys) {
      for (final b in at.keys) {
        if (a == b) continue;
        expect((at[a]! - at[b]!).distance, greaterThan(20),
            reason: '$a and $b are still on top of each other');
      }
    }
  });
}
