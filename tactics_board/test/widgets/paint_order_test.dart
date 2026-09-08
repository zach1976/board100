import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

/// Equipment goes under people.
///
/// The board draws its elements in the order they were added, so four hurdles
/// dropped after the players they belong to covered those players' numbers.
PlayerIcon _player(String id, PlayerTeam team) => PlayerIcon(
      id: id, label: id, team: team, position: const Offset(100, 100));

PlayerIcon _hurdle(String id) => PlayerIcon(
      id: id,
      label: '',
      team: PlayerTeam.neutral,
      position: const Offset(100, 100),
      markerShape: MarkerShape.hurdle,
    );

PlayerIcon _ball(String id) => PlayerIcon(
      id: id,
      label: '',
      team: PlayerTeam.neutral,
      position: const Offset(100, 100),
      sportType: SportType.soccer,
    );

void main() {
  test('markers paint under players, the ball on top', () {
    final board = [
      _player('2', PlayerTeam.home),
      _ball('ball'),
      _hurdle('h1'),
      _player('A', PlayerTeam.away),
      _hurdle('h2'),
    ];

    expect(inPaintOrderForTest(board).map((p) => p.id).toList(),
        ['h1', 'h2', '2', 'A', 'ball']);
  });

  test('order within one kind survives — two cones do not swap', () {
    final cones = [_hurdle('first'), _hurdle('second'), _hurdle('third')];
    expect(inPaintOrderForTest(cones).map((p) => p.id).toList(),
        ['first', 'second', 'third']);
  });
}
