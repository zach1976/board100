import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/painters/player_moves_painter.dart';

/// 带球、跑位、传球，画在板上要看得出是三件事。
///
/// 从前只有「球的整条线都跟着人走」才不画球的线；大多数球路都是带一段、
/// 传一段、再带一段，于是每一段带球都画成两条几乎平行、颜色又差不多的
/// 虚线箭头 —— 2026-09-28 用户报「这一步出现两条线」。现在逐段判断：
/// 带球那一段只画人的线、画成波浪，球自己走的那一段画成实线。
///
/// 同一天还报了「空悬的移动箭头」：球的某一段只有几个画布单位，画出来
/// 是一段固定长度的存根箭头，还要从终点退开一个球的半径，于是整根箭头
/// 都飘在没动过的球旁边。生成器本来就有这条规矩，只是从没作用到球上。
void main() {
  List<dynamic> drillsOf(String sport) {
    final f = File('../packages/sport_$sport/assets/drills/$sport.json');
    final raw = jsonDecode(f.readAsStringSync());
    return (raw is Map ? raw['drills'] : raw) as List;
  }

  PlayerIcon icon(Map<String, dynamic> j) => PlayerIcon.fromJson(j);

  test('带球的那一段只画一条线，球自己走的那一段还是球的', () {
    final man = PlayerIcon(
      id: 'p',
      label: '1',
      team: PlayerTeam.home,
      position: const Offset(100, 500),
      moves: const [Offset(100, 300)],
      movePhases: const [0],
    );
    // 第一段跟着人跑（带球），第二段自己飞出去（传球）。
    final ball = PlayerIcon(
      id: 'b',
      label: '',
      team: PlayerTeam.neutral,
      sportType: SportType.fieldHockey,
      position: const Offset(110, 510),
      moves: const [Offset(110, 310), Offset(600, 200)],
      movePhases: const [0, 1],
    );
    final escorts = ballEscorts(ball, [man, ball]);
    expect(escorts.keys.toList(), [0], reason: '只有第一段是带球');
    expect(escorts[0], 'p#0');
    expect(ballTravelsWithPlayers(ball, [man, ball]), isFalse,
        reason: '有一段球是自己走的，整条线不能算跟着人');
  });

  test('球的每一段都跟着人时，整条线仍然判为带球', () {
    final man = PlayerIcon(
      id: 'p',
      label: '1',
      team: PlayerTeam.home,
      position: const Offset(100, 500),
      moves: const [Offset(100, 300), Offset(300, 200)],
      movePhases: const [0, 1],
    );
    final ball = PlayerIcon(
      id: 'b',
      label: '',
      team: PlayerTeam.neutral,
      sportType: SportType.fieldHockey,
      position: const Offset(110, 510),
      moves: const [Offset(110, 310), Offset(310, 210)],
      movePhases: const [0, 1],
    );
    expect(ballTravelsWithPlayers(ball, [man, ball]), isTrue);
  });

  test('出厂的训练素材里，没有一段球路短到画出来是根空悬的箭头', () {
    const sports = [
      'soccer', 'basketball', 'volleyball', 'badminton', 'tennis',
      'pickleball', 'tableTennis', 'handball', 'rugby', 'fieldHockey',
      'waterPolo', 'baseball', 'sepakTakraw', 'beachTennis', 'footvolley',
    ];
    final dead = <String>[];
    for (final sport in sports) {
      for (final d in drillsOf(sport)) {
        final board = d['board'] as Map<String, dynamic>?;
        if (board == null) continue;
        for (final raw in (board['players'] as List)) {
          final p = icon(raw as Map<String, dynamic>);
          if (!p.isBall) continue;
          var prev = p.position;
          var held = p.holder;
          for (var k = 0; k < p.moves.length; k++) {
            final m = p.moves[k];
            final step = (m - prev).distance;
            final now = k < p.moveHolders.length ? p.moveHolders[k] : null;
            // 生成器对人用的就是这条线：画布单位 8，约 3 个屏幕点。
            // 唯一的例外是断球：球没动，但换了人拿——那一拍是真的，
            // 画笔对这么短的球路本来就不画线，所以也不会有空悬的箭头。
            if (step < 8 && (now == null || now == held)) {
              dead.add('$sport/${d["id"]} ${step.toStringAsFixed(1)}');
            }
            if (now != null) held = now;
            prev = m;
          }
        }
      }
    }
    expect(dead, isEmpty);
  });

  test('曲棍球每一脚射门都落在门柱之间', () {
    // 球门宽 3.66 米，场地宽 55 米，门柱在场地宽度的 0.467 和 0.533 处
    // ——field_hockey_court_painter.dart 就是这么画的。
    // 场地在画布里的位置，跟 tools/drills/engine.py 的 court_rect 一样：
    // 手机上的板是 402x730，曲棍球场占宽度的 0.90，居中放置。
    const aspect = 55.0 / 91.4, displayW = 402.0, displayH = 730.0;
    const cw = displayW * 0.90;
    const ch = cw / aspect;
    const w = cw / displayW * 1000.0, h = ch / displayH * 1500.0;
    const left = (displayW - cw) / 2 / displayW * 1000.0;
    const top = (displayH - ch) / 2 / displayH * 1500.0;
    const postL = left + 0.467 * w, postR = left + 0.533 * w;
    final wide = <String>[];
    var shots = 0;
    for (final d in drillsOf('fieldHockey')) {
      final board = d['board'] as Map<String, dynamic>?;
      if (board == null) continue;
      final note = (d['note'] as Map)['en'] as String;
      final sequence = note.split('Sequence: ').last.split('\n').first;
      if (!sequence.contains('shoots')) continue;
      for (final raw in (board['players'] as List)) {
        final p = icon(raw as Map<String, dynamic>);
        if (!p.isBall || p.moves.isEmpty) continue;
        final end = p.moves.last;
        // 只看落在底线附近的那一脚：中途的传球不是射门。
        if (end.dy > top + h * 0.085) continue;
        shots++;
        if (end.dx < postL || end.dx > postR) {
          wide.add('${d["id"]} x=${end.dx.toStringAsFixed(0)}');
        }
      }
    }
    expect(wide, isEmpty);
    // 免得哪天球路的写法一变，这条检查就悄悄变成什么也没查。
    expect(shots, greaterThan(8), reason: '曲棍球本来就有十几脚射门');
  });
}
