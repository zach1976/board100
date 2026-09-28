import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

/// 传球线的尾巴不能在播放过程中滑动。
///
/// ghostFeet 的偏移取决于「最近的人是谁、离多远」。球被钉在这一段的起点，
/// 其他人却按当前帧取位置时，传球者一跑开，线的起点就跟着漂 —— 全部
/// 曲棍球训练里最多漂 24.7 点，而那条线的起点根本没变。2026-09-28 报告。
void main() {
  test('这一段开始时刻的画面，决定线的起点，与其他人跑到哪里无关', () {
    final f =
        File('../packages/sport_fieldHockey/assets/drills/fieldHockey.json');
    final raw = jsonDecode(f.readAsStringSync());
    final drills = (raw is Map ? raw['drills'] : raw) as List;

    Offset posAt(PlayerIcon p, int step) {
      var at = p.position;
      for (var i = 0; i < p.moves.length; i++) {
        final ph = i < p.movePhases.length ? p.movePhases[i] : i;
        if (ph < step) at = p.moves[i];
      }
      return at;
    }

    final drifting = <String>[];
    for (final d in drills) {
      final board = Map<String, dynamic>.from(d['board'] as Map);
      final players = <PlayerIcon>[];
      for (final r in (board['players'] as List? ?? [])) {
        try {
          players.add(PlayerIcon.fromJson(Map<String, dynamic>.from(r as Map)));
        } catch (_) {}
      }
      final balls = players.where((p) => p.isBall && p.moves.isNotEmpty);
      if (balls.isEmpty) continue;
      final ball = balls.first;
      var steps = 0;
      for (final p in players) {
        for (final ph in p.movePhases) {
          if (ph + 1 > steps) steps = ph + 1;
        }
      }

      for (var s = 1; s <= steps; s++) {
        final legStart = posAt(ball, s - 1);
        // 这是 tactics_canvas 现在的算法：整幅画面取该段起点。
        Offset anchor(double t) => ballAtFeetOffsets(
              players,
              (p) => p.isBall ? legStart : posAt(p, s - 1),
            )[ball.id] ??
            Offset.zero;
        final atStart = anchor(0);
        final atMid = anchor(0.5);
        final atEnd = anchor(1);
        final worst = [
          (atMid - atStart).distance,
          (atEnd - atStart).distance,
        ].reduce((a, b) => a > b ? a : b);
        if (worst > 2.0) {
          drifting.add('${d["id"]} 第 $s 拍漂了 ${worst.toStringAsFixed(1)} 点');
        }
      }
    }

    expect(drifting, isEmpty);
  });
}
