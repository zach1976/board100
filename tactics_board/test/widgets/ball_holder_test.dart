import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/painters/player_moves_painter.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';
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
  PlayerIcon man2(String id, Offset at) => man(id, at);

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
    // The board's word hands it to C: the ball ends the same distance from
    // C as it would with C the only man on the pitch. Not the same OFFSET —
    // F is standing on the side the ball would otherwise take, and the
    // clear-side rule moves it to C's other foot.
    final onlyC = ballAtFeetOffsets([c, ball], at)[ball.id]!;
    expect((end + named - c.position).distance,
        closeTo((end + onlyC - c.position).distance, 0.01));
    expect(named, isNot(nearest));
  });

  test('手上的球画在手边，脚下的球画在脚边', () {
    final man = man2('P', const Offset(200, 300));
    final ball = PlayerIcon(
      id: 'b', label: '', team: PlayerTeam.neutral, sportType: SportType.soccer,
      position: const Offset(210, 305), moves: const [], movePhases: const [],
    );
    Offset at(PlayerIcon p) => p.position;
    Offset held(SportType s) =>
        ball.position + ballAtFeetOffsets([man, ball], at, sport: s)[ball.id]!
            - man.position;
    // No heading is given, so he faces the viewer and "ahead" is down the
    // screen: shoes at 0.70 of a cell plus 0.25 ahead, and 0.40 to the side
    // the ball already lay (it lies to the right).
    expect(held(SportType.soccer).dy, closeTo(kPlayerIconSize * 0.95, 0.01));
    expect(held(SportType.soccer).dx, closeTo(kPlayerIconSize * 0.40, 0.01));
    expect(held(SportType.fieldHockey).dy, closeTo(kPlayerIconSize * 0.95, 0.01),
        reason: '球杆的头在地上');
    // 抱在手里的球：固定挂在胯边，不许飘回身体中线 —— 篮球画在胸口，
    // 正好压住球衣号码，看上去是一团而不是「人 + 他抱着的球」。
    for (final s in [SportType.basketball, SportType.handball,
                     SportType.waterPolo, SportType.rugby, SportType.volleyball,
                     SportType.badminton]) {
      expect(held(s).dy, closeTo(kPlayerIconSize * 0.50, 0.01), reason: s.name);
      expect(held(s).dx, closeTo(kPlayerIconSize * 0.40, 0.01), reason: s.name);
    }
    // 球在左边，就挂在左胯 —— 只有距离是定死的，哪一边还是看球在哪。
    final left = PlayerIcon(
      id: 'b', label: '', team: PlayerTeam.neutral,
      sportType: SportType.basketball,
      position: const Offset(190, 305), moves: const [], movePhases: const [],
    );
    final off = ballAtFeetOffsets([man, left], at,
        sport: SportType.basketball)[left.id]!;
    expect((left.position + off - man.position).dx,
        closeTo(-kPlayerIconSize * 0.40, 0.01));
  });

  test('持球人挑的那一侧站着人，球就换到他另一侧', () {
    // G 持球，球在他右边；X4 就站在那一侧一步远，球画过去就到了 X4 鞋底下，
    // 按深度 X4 又在球上面 —— 人踩球。改到左边去，那边没人。
    final g = man2('G', const Offset(200, 300));
    final ball = PlayerIcon(
      id: 'b', label: '', team: PlayerTeam.neutral, sportType: SportType.soccer,
      position: const Offset(210, 305), moves: const [], movePhases: const [],
    );
    Offset at(PlayerIcon p) => p.position;
    Offset held(List<PlayerIcon> all) =>
        ball.position + ballAtFeetOffsets(all, at, sport: SportType.soccer)[ball.id]!
            - g.position;
    expect(held([g, ball]).dx, greaterThan(0), reason: '没人在，球在右边');
    final x4 = PlayerIcon(id: 'X4', label: 'X4', team: PlayerTeam.away,
        position: const Offset(216, 322));
    expect(held([g, x4, ball]).dx, lessThan(0), reason: 'X4 站在右边，球换到左边');
    // 两边都有人：留在原来那一侧，不来回跳。
    final x3 = PlayerIcon(id: 'X3', label: 'X3', team: PlayerTeam.away,
        position: const Offset(184, 322));
    expect(held([g, x4, x3, ball]).dx, greaterThan(0));
  });

  test('停下来的球整个拉到脚边，飞行中的球还是渐进的', () {
    final d = man2('D', const Offset(300, 400));
    // 球落在离 D 50 点的地方 —— 比 _kHoldReach（34.2）远，fade 只拉 23%。
    final ball = PlayerIcon(
      id: 'b', label: '', team: PlayerTeam.neutral, sportType: SportType.soccer,
      position: const Offset(270, 440), moves: const [], movePhases: const [],
    );
    Offset at(PlayerIcon p) => p.position;
    Offset held({required bool settled}) =>
        ball.position +
        ballAtFeetOffsets([d, ball], at,
            sport: SportType.soccer, settled: settled)[ball.id]! -
        d.position;
    // 一拍走完：球就在他脚边，差多远都拉到位。
    expect(held(settled: true).dx, closeTo(-kPlayerIconSize * 0.40, 0.01));
    expect(held(settled: true).dy, closeTo(kPlayerIconSize * 0.95, 0.01));
    // 传球途中：只拉一部分，球从起点滑过去，不是一开拍就吸到接球人脚上。
    final flying = held(settled: false);
    expect(flying.dy, greaterThan(kPlayerIconSize * 0.95 + 2),
        reason: '还在半路');
    expect(flying.dy, lessThan(40), reason: '但已经被拉近了一些');
  });

  test('球在持球人面朝的方向前面：背对屏幕往上，侧身往那一侧', () {
    final d = man2('D', const Offset(200, 300));
    final ball = PlayerIcon(
      id: 'b', label: '', team: PlayerTeam.neutral, sportType: SportType.soccer,
      position: const Offset(205, 310), moves: const [], movePhases: const [],
    );
    Offset at(PlayerIcon p) => p.position;
    Offset held(double heading) =>
        ball.position +
        ballAtFeetOffsets([d, ball], at, sport: SportType.soccer,
            settled: true, headingOf: (_) => heading)[ball.id]! -
        d.position;
    // 0 = 朝板子上方 = 背对看的人：球在鞋前面，也就是比鞋高。
    expect(held(0).dy, closeTo(kPlayerIconSize * (0.70 - 0.25), 0.01));
    // π = 面朝看的人：球在鞋下面。
    expect(held(pi).dy, closeTo(kPlayerIconSize * (0.70 + 0.25), 0.01));
    // 面朝右：球在右边一步，高度就是鞋。
    expect(held(pi / 2).dx, closeTo(kPlayerIconSize * (0.40 + 0.25), 0.01));
    expect(held(pi / 2).dy, closeTo(kPlayerIconSize * 0.70, 0.01));
    // 面朝左：镜像。
    expect(held(-pi / 2).dx, closeTo(-kPlayerIconSize * (0.40 + 0.25), 0.01));
  });

  test('ballLegAt：球画在哪，就知道它在哪一段、走了几成', () {
    final ball = PlayerIcon(
      id: 'b', label: '', team: PlayerTeam.neutral, sportType: SportType.soccer,
      position: const Offset(0, 0),
      moves: const [Offset(100, 0), Offset(100, 100)], movePhases: const [0, 1],
    );
    expect(ballLegAt(ball, const Offset(25, 0))!.phase, 0);
    expect(ballLegAt(ball, const Offset(25, 0))!.t, closeTo(0.25, 1e-9));
    expect(ballLegAt(ball, const Offset(100, 90))!.phase, 1);
    expect(ballLegAt(ball, const Offset(100, 90))!.t, closeTo(0.9, 1e-9));
    // Off the line, still the nearest leg, clamped to its ends.
    expect(ballLegAt(ball, const Offset(-30, 5))!.t, 0.0);
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
