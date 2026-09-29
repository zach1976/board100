import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/painters/player_moves_painter.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

/// 球停在谁脚下，听板子的，不听「谁最近」。
///
/// transition_6v6 第 2 拍：F 传给 C，球落点离 C 24 点（生成器放的「脚下」），
/// 离 F 却只有 15.8 点。按最近的人算，球被画回 F 的另一只脚，和起点的虚影球
/// 并排、中间一截存根箭头——「两个球，什么也不是」。2026-09-29 真机 QA 报的。
/// 全库 1571 段球路里 720 段的终点两米内站着两个人。
void main() {
  PlayerIcon man(String id, Offset at) => PlayerIcon(
      id: id, label: id, team: PlayerTeam.home, position: at);

  test('板子说是 C 的球，就画在 C 脚下，哪怕 F 站得更近', () {
    final f = man('F', const Offset(173, 355));
    final c = man('C', const Offset(139, 336));
    final ball = PlayerIcon(
      id: 'b', label: '', team: PlayerTeam.neutral, sportType: SportType.soccer,
      position: const Offset(197, 359),
      moves: const [Offset(161, 345)], movePhases: const [0],
      moveHolders: const ['C'], holder: 'F',
    );
    final players = [f, c, ball];
    Offset at(PlayerIcon p) => p.isBall ? ball.moves.last : p.position;
    final nearest = ballAtFeetOffsets(players, at)[ball.id]!;
    final named = ballAtFeetOffsets(players, at,
        holderOf: (b) => ballHolderAt(b, 1))[ball.id]!;
    final end = ball.moves.last;
    // The nearest rule hands it to F.
    expect((end + nearest - f.position).distance,
        lessThan((end + nearest - c.position).distance));
    // The board's word hands it to C: the same step the rule takes when C
    // is the only man on the pitch, F having become irrelevant.
    final onlyC = ballAtFeetOffsets([c, ball], at)[ball.id]!;
    expect(named, onlyC);
    expect(named, isNot(nearest));
  });

  test('ballHolderAt 走过每一拍：开始是 holder，之后是那一拍的接球人', () {
    final ball = PlayerIcon(
      id: 'b', label: '', team: PlayerTeam.neutral, sportType: SportType.soccer,
      position: Offset.zero,
      moves: const [Offset(1, 0), Offset(2, 0), Offset(3, 0)],
      movePhases: const [0, 1, 2],
      moveHolders: const ['F', 'C', null], holder: 'X',
    );
    expect(ballHolderAt(ball, 0), 'X');
    expect(ballHolderAt(ball, 1), 'F');
    expect(ballHolderAt(ball, 2), 'C');
    expect(ballHolderAt(ball, 3), isNull, reason: '射门之后没人持球');
    // A board that does not say gives nothing, and the caller measures.
    final mute = PlayerIcon(
      id: 'm', label: '', team: PlayerTeam.neutral, sportType: SportType.soccer,
      position: Offset.zero, moves: const [Offset(1, 0)], movePhases: const [0],
    );
    expect(ballHolderAt(mute, 1), isNull);
  });
}
