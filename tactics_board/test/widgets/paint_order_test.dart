import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
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

  test('画的先后是深度：谁在屏幕上更靠下，谁后画', () {
    // C 在球上，X2 比 C 更靠近看的人一步：X2 要盖住球，球盖住 C。
    final c = _player('C', PlayerTeam.home);
    final x2 = _player('X2', PlayerTeam.away);
    final ball = _ball('ball');
    final depth = {'C': 100.0, 'ball': 100.5, 'X2': 140.0};
    expect(
        inPaintOrderForTest([x2, ball, c], depth: (p) => depth[p.id]!)
            .map((p) => p.id)
            .toList(),
        ['C', 'ball', 'X2']);
    // 他背对着看的人：球贴在他胸口，而胸口朝里 —— 画在他上面就成了
    // 黏在肩胛骨上的一颗球。持球人和球的先后由朝向定，不量深度。
    final behind = {'C': 100.0, 'ball': 99.5, 'X2': 140.0};
    expect(
        inPaintOrderForTest([x2, ball, c], depth: (p) => behind[p.id]!)
            .map((p) => p.id)
            .toList(),
        ['ball', 'C', 'X2']);
    // 没有板子可量（预览、测试）：球在人上面，和从前一样。
    expect(inPaintOrderForTest([c, ball]).map((p) => p.id).toList(),
        ['C', 'ball']);
    // 同深度按加入顺序，不会在无关的重建里互换。
    final tie = {'C': 100.0, 'X2': 100.0};
    expect(
        inPaintOrderForTest([x2, c], depth: (p) => tie[p.id]!)
            .map((p) => p.id)
            .toList(),
        ['X2', 'C']);
  });

  test('facesAwayOnScreen：八格转身图里朝上的那三格是背面', () {
    // 0 = 正朝屏幕上方，也就是背对看的人。
    expect(facesAwayOnScreen(0, 0), isTrue);
    expect(facesAwayOnScreen(pi / 4, 0), isTrue);
    expect(facesAwayOnScreen(-pi / 4, 0), isTrue);
    expect(facesAwayOnScreen(pi / 2, 0), isFalse, reason: '侧身');
    expect(facesAwayOnScreen(pi, 0), isFalse, reason: '正面朝看的人');
    // 板子横过来，人在屏幕上仍然站直，所以要把板子的转数算进去。
    expect(facesAwayOnScreen(pi / 2, 3), isTrue);
    expect(facesAwayOnScreen(0, 1), isFalse);
  });

  test('order within one kind survives — two cones do not swap', () {
    final cones = [_hurdle('first'), _hurdle('second'), _hurdle('third')];
    expect(inPaintOrderForTest(cones).map((p) => p.id).toList(),
        ['first', 'second', 'third']);
  });
}
