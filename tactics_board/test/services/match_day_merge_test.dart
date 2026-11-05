import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/match_day.dart';
import 'package:tactics_board/services/match_day_service.dart';

/// Match days from two phones as one list: the same match once, the copy
/// written last winning, newest match first.
void main() {
  MatchDay match(String id, DateTime started, {DateTime? updated, String name = ''}) =>
      MatchDay(
        id: id,
        name: name,
        periods: 4,
        periodSeconds: 900,
        onPitch: 2,
        players: const [
          MatchPlayer(id: 'a', name: 'Ana'),
          MatchPlayer(id: 'b', name: 'Bo'),
        ],
        starters: const ['a', 'b'],
        startedAt: started,
        finishedAt: started.add(const Duration(hours: 1)),
        updatedAt: updated ?? started.add(const Duration(hours: 1)),
      );

  test('the same id is kept once, the later-written copy winning', () {
    final d = DateTime(2026, 10, 10, 10);
    final local = [
      match('m1', d, name: 'mine'),
      match('m2', d.add(const Duration(days: 1)), name: 'old name',
          updated: d.add(const Duration(days: 1, hours: 1))),
    ];
    final remote = [
      match('m2', d.add(const Duration(days: 1)), name: 'renamed',
          updated: d.add(const Duration(days: 1, hours: 2))),
      match('m3', d.add(const Duration(days: 2)), name: 'theirs'),
    ];
    final merged = MatchDayService.merge(local, remote);
    expect(merged.map((m) => m.id).toList(), ['m3', 'm2', 'm1']);
    expect(merged[1].name, 'renamed');
    // And the other way round the older remote copy loses.
    final again = MatchDayService.merge(remote, local);
    expect(again.map((m) => m.id).toList(), ['m3', 'm2', 'm1']);
    expect(again[1].name, 'renamed');
  });

  test('keeps the hundred newest', () {
    final d = DateTime(2026, 1, 1);
    final local = [for (var i = 0; i < 80; i++) match('l$i', d.add(Duration(days: i)))];
    final remote = [for (var i = 0; i < 80; i++) match('r$i', d.add(Duration(days: 100 + i)))];
    final merged = MatchDayService.merge(local, remote);
    expect(merged.length, 100);
    expect(merged.first.id, 'r79');
    expect(merged.last.id, 'l60');
  });

  test('merging with nothing changes nothing', () {
    final d = DateTime(2026, 10, 10, 10);
    final local = [match('m1', d), match('m0', d.subtract(const Duration(days: 1)))];
    final merged = MatchDayService.merge(local, const []);
    expect(merged.map((m) => m.id).toList(), ['m1', 'm0']);
    expect(MatchDayService.merge(const [], const []), isEmpty);
  });
}
