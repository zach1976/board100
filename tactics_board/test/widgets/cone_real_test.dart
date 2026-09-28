import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

/// 用真实训练数据，按真实节拍序列，量每个锥桶的绘制位移。
void main() {
  test('全部运动的真实训练，播放时器材都不动', () {
    final dir = Directory('../packages');
    final drills = <Map<String, dynamic>>[];
    for (final pkg in dir.listSync().whereType<Directory>()) {
      final dd = Directory('${pkg.path}/assets/drills');
      if (!dd.existsSync()) continue;
      for (final f in dd.listSync().whereType<File>()) {
        if (!f.path.endsWith('.json')) continue;
        final raw = jsonDecode(f.readAsStringSync());
        for (final d in (raw is Map ? raw['drills'] : raw) as List) {
          drills.add(Map<String, dynamic>.from(d as Map));
        }
      }
    }
    print('扫描 ${drills.length} 个训练（全部运动）');

    final report = <String>[];
    for (final d in drills) {
      final board = Map<String, dynamic>.from(d['board'] as Map);
      final players = <PlayerIcon>[];
      for (final r in (board['players'] as List? ?? [])) {
        try {
          players.add(PlayerIcon.fromJson(Map<String, dynamic>.from(r as Map)));
        } catch (_) {}
      }
      final cones = players.where((p) => p.isMarker).toList();
      if (cones.isEmpty) continue;
      var steps = 0;
      for (final p in players) {
        for (final ph in p.movePhases) {
          if (ph + 1 > steps) steps = ph + 1;
        }
      }
      if (steps == 0) continue;

      // 逐拍：每个人站在该拍应在的位置
      Offset posAt(PlayerIcon p, int step) {
        var at = p.position;
        for (var i = 0; i < p.moves.length; i++) {
          final ph = i < p.movePhases.length ? p.movePhases[i] : i;
          if (ph < step) at = p.moves[i];
        }
        return at;
      }

      final seen = <String, Offset>{};
      var worst = 0.0;
      String? which;
      for (var s = 0; s <= steps; s++) {
        final off = markerClearOffsets(players, (p) => posAt(p, s));
        for (final c in cones) {
          final now = (off[c.id] ?? Offset.zero) + posAt(c, s);
          final was = seen[c.id];
          if (was != null) {
            final moved = (now - was).distance;
            if (moved > worst) { worst = moved; which = c.id; }
          }
          seen[c.id] = now;
        }
      }
      if (worst > 2.0) report.add('${d['id']}  锥桶 $which 跨拍位移 ${worst.toStringAsFixed(1)} 点');
    }
    for (final r in report.take(12)) print(r);
    print('共 ${report.length} 个训练里锥桶会动');
    expect(report, isEmpty);
  });
}
