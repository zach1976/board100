import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/match_day.dart';
import 'package:tactics_board/models/sport_type.dart';

/// The match-day sheet's arithmetic: playing time out of the starters and
/// the log, and the swaps that even it out.
void main() {
  MatchDay match({int onPitch = 2, int players = 4}) => MatchDay(
        periods: 4,
        periodSeconds: 900,
        onPitch: onPitch,
        players: [
          for (var i = 1; i <= players; i++)
            MatchPlayer(id: 'p$i', name: 'Player $i', number: '$i'),
        ],
        starters: [for (var i = 1; i <= onPitch; i++) 'p$i'],
        startedAt: DateTime(2026, 10, 14, 10),
      );

  group('clock', () {
    test('runs on wall time while started and holds while paused', () {
      final m = match();
      final t0 = DateTime(2026, 10, 14, 10);
      expect(m.clock(t0), 0);
      m.start(t0);
      expect(m.isRunning, isTrue);
      expect(m.clock(t0.add(const Duration(seconds: 90))), 90);
      m.pause(t0.add(const Duration(seconds: 90)));
      expect(m.isRunning, isFalse);
      expect(m.clock(t0.add(const Duration(minutes: 30))), 90);
      m.start(t0.add(const Duration(minutes: 30)));
      expect(m.clock(t0.add(const Duration(minutes: 30, seconds: 10))), 100);
    });

    test('next period stops the clock and counts the period from there', () {
      final m = match();
      final t0 = DateTime(2026, 10, 14, 10);
      m.start(t0);
      m.nextPeriod(t0.add(const Duration(minutes: 15)));
      expect(m.period, 2);
      expect(m.isRunning, isFalse);
      expect(m.clock(), 900);
      expect(m.periodClock(), 0);
      m.start(t0.add(const Duration(minutes: 20)));
      expect(m.periodClock(t0.add(const Duration(minutes: 21))), 60);
      expect(m.clock(t0.add(const Duration(minutes: 21))), 960);
    });

    test('the last period ends the match', () {
      final m = match();
      final t0 = DateTime(2026, 10, 14, 10);
      for (var i = 0; i < 4; i++) {
        m.start(t0.add(Duration(minutes: 15 * i)));
        m.nextPeriod(t0.add(Duration(minutes: 15 * (i + 1))));
      }
      expect(m.isFinished, isTrue);
      expect(m.period, 4);
      expect(m.clock(), 3600);
      // Nothing moves after the whistle.
      m.start();
      expect(m.isRunning, isFalse);
      expect(m.substitute('p1', 'p3'), isFalse);
    });
  });

  group('playing time', () {
    test('starters have the clock, the bench has nothing', () {
      final m = match();
      final t = m.playingTime(600);
      expect(t, {'p1': 600, 'p2': 600, 'p3': 0, 'p4': 0});
    });

    test('a substitution splits the time at the clock it was made', () {
      final m = match();
      final t0 = DateTime(2026, 10, 14, 10);
      m.start(t0);
      expect(m.substitute('p1', 'p3', t0.add(const Duration(minutes: 5))),
          isTrue);
      expect(m.onPitchIds, ['p3', 'p2']);
      expect(m.benchIds, ['p1', 'p4']);
      final t = m.playingTime(900);
      expect(t['p1'], 300);
      expect(t['p3'], 600);
      expect(t['p2'], 900);
      expect(t['p4'], 0);
      expect(m.subs.single.clock, 300);
      expect(m.subs.single.period, 1);
    });

    test('a player can come back on and keeps both spells', () {
      final m = match();
      m.start(DateTime(2026, 10, 14, 10));
      m.substitute('p1', 'p3', DateTime(2026, 10, 14, 10, 5));
      m.substitute('p3', 'p1', DateTime(2026, 10, 14, 10, 10));
      final t = m.playingTime(900);
      expect(t['p1'], 300 + 300);
      expect(t['p3'], 300);
      expect(m.onPitchIds, ['p1', 'p2']);
    });

    test('refuses a swap that is not off for on', () {
      final m = match();
      m.start(DateTime(2026, 10, 14, 10));
      expect(m.substitute('p3', 'p4'), isFalse, reason: 'p3 is on the bench');
      expect(m.substitute('p1', 'p2'), isFalse, reason: 'p2 is on already');
      expect(m.substitute('p1', 'nobody'), isFalse);
      expect(m.subs, isEmpty);
      expect(m.onPitchIds, ['p1', 'p2']);
    });

    test('the sum of everyone\'s time is the clock times the pitch', () {
      final m = match(onPitch: 3, players: 6);
      m.start(DateTime(2026, 10, 14, 10));
      m.substitute('p1', 'p4', DateTime(2026, 10, 14, 10, 4));
      m.substitute('p2', 'p5', DateTime(2026, 10, 14, 10, 7));
      m.substitute('p4', 'p6', DateTime(2026, 10, 14, 10, 11));
      final t = m.playingTime(1200);
      expect(t.values.fold<int>(0, (a, b) => a + b), 1200 * 3);
    });
  });

  group('suggest', () {
    test('pairs the most-played on the pitch with the least-played bench', () {
      final times = {'a': 900, 'b': 600, 'c': 300, 'd': 0, 'e': 500};
      final swaps = MatchDay.suggestSwaps(times, ['a', 'b', 'c'], ['d', 'e']);
      expect(swaps.length, 2);
      expect(swaps[0].outId, 'a');
      expect(swaps[0].inId, 'd');
      expect(swaps[0].gapSeconds, 900);
      expect(swaps[1].outId, 'b');
      expect(swaps[1].inId, 'e');
      expect(swaps[1].gapSeconds, 100);
    });

    test('stops where the gap is too small to be worth a swap', () {
      final times = {'a': 900, 'b': 320, 'c': 0, 'd': 300};
      final swaps = MatchDay.suggestSwaps(times, ['a', 'b'], ['c', 'd'],
          minGapSeconds: 60);
      expect(swaps.length, 1);
      expect(swaps.single.outId, 'a');
      expect(swaps.single.inId, 'c');
    });

    test('nothing to suggest when time is even or the bench is empty', () {
      expect(MatchDay.suggestSwaps({'a': 100, 'b': 100}, ['a'], ['b']),
          isEmpty);
      expect(MatchDay.suggestSwaps({'a': 100}, ['a'], []), isEmpty);
    });

    test('applying the suggestion evens the sheet out', () {
      final m = match(onPitch: 2, players: 4);
      m.start(DateTime(2026, 10, 14, 10));
      final at = DateTime(2026, 10, 14, 10, 10);
      final swaps = m.suggest(at: 600);
      expect(swaps.length, 2);
      for (final s in swaps) {
        expect(m.substitute(s.outId, s.inId, at), isTrue);
      }
      expect(m.onPitchIds.toSet(), {'p3', 'p4'});
      final t = m.playingTime(1200);
      expect(t.values.toSet(), {600});
      expect(m.suggest(at: 1200), isEmpty);
    });
  });

  group('json', () {
    test('round-trips with the clock running', () {
      final m = match(onPitch: 3, players: 5)..name = 'vs Tigers';
      final t0 = DateTime(2026, 10, 14, 10);
      m.start(t0);
      m.substitute('p2', 'p4', t0.add(const Duration(minutes: 3)));
      m.nextPeriod(t0.add(const Duration(minutes: 15)));
      m.start(t0.add(const Duration(minutes: 17)));
      final back = MatchDay.fromJson(m.toJson());
      expect(back.name, 'vs Tigers');
      expect(back.periods, 4);
      expect(back.periodSeconds, 900);
      expect(back.onPitch, 3);
      expect(back.players.map((p) => p.label), m.players.map((p) => p.label));
      expect(back.starters, ['p1', 'p2', 'p3']);
      expect(back.subs.single.outId, 'p2');
      expect(back.subs.single.inId, 'p4');
      expect(back.subs.single.clock, 180);
      expect(back.period, 2);
      expect(back.periodStartClock, 900);
      expect(back.isRunning, isTrue);
      final later = t0.add(const Duration(minutes: 18));
      expect(back.clock(later), m.clock(later));
      expect(back.playingTime(m.clock(later)), m.playingTime(m.clock(later)));
    });

    test('a finished match stays finished', () {
      final m = match()..finish(DateTime(2026, 10, 14, 11));
      final back = MatchDay.fromJson(m.toJson());
      expect(back.isFinished, isTrue);
      expect(back.finishedAt, DateTime(2026, 10, 14, 11));
    });
  });

  group('sport defaults', () {
    test('field hockey is four quarters of fifteen, eleven a side', () {
      expect(SportType.fieldHockey.hasMatchDay, isTrue);
      expect(SportType.fieldHockey.matchDayDefaults,
          (periods: 4, minutes: 15, onPitch: 11));
    });

    test('only field hockey has the sheet for now', () {
      final on = SportType.values.where((s) => s.hasMatchDay).toList();
      expect(on, [SportType.fieldHockey]);
    });

    test('every sport answers with something playable', () {
      for (final s in SportType.values) {
        final d = s.matchDayDefaults;
        expect(d.periods, greaterThan(0), reason: s.name);
        expect(d.minutes, greaterThan(0), reason: s.name);
        expect(d.onPitch, greaterThan(0), reason: s.name);
      }
    });
  });
}
