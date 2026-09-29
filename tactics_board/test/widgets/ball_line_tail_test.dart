import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/painters/player_moves_painter.dart';

/// 传球和射门的线从起点就得是全强度的。
///
/// 跑位的虚线从起点 55% 渐变到终点全色，是给虚线一个方向感。球的实线本来就
/// 有箭头，而它的起点在传球者脚下、一路穿过他的球衣：淡蓝色 55% 压在蓝色
/// 球衣上什么也看不见，射门看上去像从他头顶开始，离球一个身位。
/// 2026-09-29 真机 QA 时报的。
void main() {
  test('球的线没有渐变尾巴，人的线有', () {
    final man = PlayerIcon(
      id: 'p', label: '1', team: PlayerTeam.home,
      position: const Offset(100, 500), moves: const [Offset(100, 300)], movePhases: const [0],
      // Its own colour, or the ball's paints cannot be told from his.
      moveColor: PlayerIcon.moveColorForIndex(1),
    );
    final ball = PlayerIcon(
      id: 'b', label: '', team: PlayerTeam.neutral, sportType: SportType.soccer,
      position: const Offset(300, 500), moves: const [Offset(300, 100)], movePhases: const [0],
    );
    final rec = _Paints();
    PlayerMovesPainter(players: [man, ball]).paint(rec, const Size(402, 730));
    // Each segment draws an outline then the line: the line is the paint
    // whose colour is the mover's own, and a fading tail is a shader.
    bool faded(PlayerIcon p) => rec.paints
        .where((q) => q.color.toARGB32() == p.moveColor.toARGB32())
        .any((q) => q.shader != null);
    expect(faded(man), isTrue, reason: '跑位的虚线保留渐变');
    expect(faded(ball), isFalse, reason: '球的实线从起点就是全色');
  });
}

class _Paints implements Canvas {
  final List<Paint> paints = [];
  @override
  void drawPath(Path path, Paint paint) => paints.add(paint);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}
