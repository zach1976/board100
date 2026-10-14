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

    test('the team sports with a bench have the sheet', () {
      final on = SportType.values.where((s) => s.hasMatchDay).toSet();
      expect(on, {
        SportType.fieldHockey,
        SportType.volleyball,
        SportType.soccer,
        SportType.basketball,
        SportType.handball,
        SportType.waterPolo,
        SportType.rugby,
      });
      expect(SportType.volleyball.matchDayCountsSets, isTrue);
      expect(SportType.fieldHockey.matchDayCountsSets, isFalse);
    });

    test('hockey shows green, yellow and red; the shoot-out is hockey\'s and soccer\'s', () {
      final cards = SportType.fieldHockey.matchDayCards;
      expect(cards.map((c) => c.kind).toList(), [
        MatchCardKind.green,
        MatchCardKind.yellow,
        MatchCardKind.yellow,
        MatchCardKind.red,
      ]);
      expect(cards.map((c) => c.seconds).toList(), [120, 300, 600, null]);
      expect(SportType.handball.matchDayCards.map((c) => c.seconds),
          contains(120));
      expect(SportType.volleyball.matchDayCards, isEmpty);
      expect(SportType.values.where((s) => s.hasShootOut).toSet(),
          {SportType.fieldHockey, SportType.soccer});
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

  group('period over', () {
    test('the clock stops by itself at the period\'s length', () {
      final m = match();
      final t0 = DateTime(2026, 10, 14, 10);
      m.start(t0);
      expect(m.isPeriodOver(t0.add(const Duration(minutes: 14))), isFalse);
      expect(m.clock(t0.add(const Duration(minutes: 16))), 900);
      expect(m.periodClock(t0.add(const Duration(minutes: 16))), 900);
      expect(m.isPeriodOver(t0.add(const Duration(minutes: 16))), isTrue);
      // A swap made after the whistle is logged at the boundary.
      m.substitute('p1', 'p3', t0.add(const Duration(minutes: 17)));
      expect(m.subs.single.clock, 900);
      // Pausing there holds exactly the period length.
      m.pause(t0.add(const Duration(minutes: 20)));
      expect(m.clock(), 900);
      expect(m.isPeriodOver(), isTrue);
      // Start does nothing until the coach adds time or moves on.
      m.start(t0.add(const Duration(minutes: 21)));
      expect(m.isRunning, isFalse);
    });

    test('added time lets the clock run on, and stops it again', () {
      final m = match();
      final t0 = DateTime(2026, 10, 14, 10);
      m.start(t0);
      m.pause(t0.add(const Duration(minutes: 16)));
      m.addTime(60, t0.add(const Duration(minutes: 16)));
      expect(m.isRunning, isTrue);
      expect(m.isPeriodOver(t0.add(const Duration(minutes: 16, seconds: 30))),
          isFalse);
      expect(m.clock(t0.add(const Duration(minutes: 16, seconds: 30))), 930);
      expect(m.clock(t0.add(const Duration(minutes: 18))), 960);
      expect(m.isPeriodOver(t0.add(const Duration(minutes: 18))), isTrue);
      // Added time while the clock runs keeps what it has.
      m.addTime(60, t0.add(const Duration(minutes: 18)));
      expect(m.clock(t0.add(const Duration(minutes: 18, seconds: 10))), 970);
      m.nextPeriod(t0.add(const Duration(minutes: 19)));
      expect(m.period, 2);
      expect(m.periodStartClock, 1020);
      expect(m.extraSeconds, 0);
      expect(m.periodEndClock, 1920);
    });

    test('the next period continues from the boundary', () {
      final m = match();
      final t0 = DateTime(2026, 10, 14, 10);
      m.start(t0);
      m.nextPeriod(t0.add(const Duration(minutes: 40)));
      expect(m.clock(), 900);
      expect(m.period, 2);
      expect(m.periodClock(), 0);
      expect(m.isPeriodOver(), isFalse);
      m.start(t0.add(const Duration(minutes: 41)));
      expect(m.isRunning, isTrue);
      expect(m.clock(t0.add(const Duration(minutes: 42))), 960);
    });

    test('a killed app comes back stopped at the whistle', () {
      final m = match();
      final t0 = DateTime(2026, 10, 14, 10);
      m.start(t0);
      final back = MatchDay.fromJson(m.toJson());
      final later = t0.add(const Duration(hours: 1));
      expect(back.clock(later), 900);
      expect(back.isPeriodOver(later), isTrue);
      expect(back.playingTime(back.clock(later)), {
        'p1': 900,
        'p2': 900,
        'p3': 0,
        'p4': 0,
      });
      back.addTime(120, later);
      final again = MatchDay.fromJson(back.toJson());
      expect(again.extraSeconds, 120);
      expect(again.clock(later.add(const Duration(seconds: 30))), 930);
    });
  });

  group('keeper', () {
    MatchDay withKeeper() => MatchDay(
          periods: 2,
          periodSeconds: 1800,
          onPitch: 3,
          players: const [
            MatchPlayer(id: 'gk', name: 'Keeper', isKeeper: true),
            MatchPlayer(id: 'a', name: 'A'),
            MatchPlayer(id: 'b', name: 'B'),
            MatchPlayer(id: 'c', name: 'C'),
            MatchPlayer(id: 'gk2', name: 'Keeper 2', isKeeper: true),
          ],
          starters: const ['gk', 'a', 'b'],
          startedAt: DateTime(2026, 10, 14, 10),
        );

    test('is never taken off or sent on by a suggestion', () {
      final m = withKeeper();
      final swaps = m.suggest(at: 900);
      // The keeper has the most time of anyone but is left alone; the
      // reserve keeper is never proposed for an outfield player.
      expect(swaps.map((s) => s.outId), isNot(contains('gk')));
      expect(swaps.map((s) => s.inId), isNot(contains('gk2')));
      expect(swaps.length, 1);
      expect(swaps.single.inId, 'c');
    });

    test('can still be swapped by hand', () {
      final m = withKeeper();
      expect(m.substitute('gk', 'gk2', DateTime(2026, 10, 14, 10)), isTrue);
      expect(m.onPitchIds, ['gk2', 'a', 'b']);
    });

    test('survives the file', () {
      final m = withKeeper();
      final back = MatchDay.fromJson(m.toJson());
      expect(back.player('gk')!.isKeeper, isTrue);
      expect(back.player('a')!.isKeeper, isFalse);
      expect(MatchPlayer.fromJson(const {'id': 'x', 'name': 'X'}).isKeeper,
          isFalse);
    });
  });

  group('cards', () {
    test('a green card sits the player out two minutes and brings them back', () {
      final m = match(onPitch: 2, players: 3);
      final t0 = DateTime(2026, 10, 14, 10);
      m.start(t0);
      expect(
          m.giveCard('p1', MatchCardKind.green,
              seconds: 120, now: t0.add(const Duration(minutes: 5))),
          isTrue);
      expect(m.cards.single.clock, 300);
      expect(m.cards.single.period, 1);
      expect(m.cards.single.endClock, 420);
      // Off the pitch, place kept, bench unchanged.
      expect(m.suspendedIds(360), {'p1'});
      expect(m.lineupIds, ['p1', 'p2']);
      expect(m.benchIds, ['p3']);
      expect(m.suspension('p1', 360)!.endClock, 420);
      // Nobody comes on for a suspended player.
      expect(m.substitute('p1', 'p3', t0.add(const Duration(minutes: 6))),
          isFalse);
      // Back by themselves when the time is served.
      expect(m.suspendedIds(420), isEmpty);
      expect(m.suspension('p1', 420), isNull);
      // Time sat out is not playing time.
      final t = m.playingTime(600);
      expect(t['p1'], 600 - 120);
      expect(t['p2'], 600);
      expect(t['p3'], 0);
      // Half-way through the suspension only the half served is excluded.
      expect(m.playingTime(360)['p1'], 300);
    });

    test('a red card is out for the match', () {
      final m = match(onPitch: 2, players: 3);
      m.start(DateTime(2026, 10, 14, 10));
      m.giveCard('p2', MatchCardKind.red, now: DateTime(2026, 10, 14, 10, 10));
      expect(m.cards.single.seconds, isNull);
      expect(m.cards.single.endClock, isNull);
      expect(m.suspendedIds(3600), {'p2'});
      expect(m.playingTime(3600)['p2'], 600);
      // Nothing more can be shown to them, and they cannot come back on.
      expect(m.giveCard('p2', MatchCardKind.yellow, seconds: 300), isFalse);
      expect(m.substitute('p2', 'p3'), isFalse);
      // A player sent off from the bench cannot come on.
      m.giveCard('p3', MatchCardKind.red);
      expect(m.substitute('p1', 'p3'), isFalse);
    });

    test('a booking without time changes nothing but the log', () {
      final m = match(onPitch: 2, players: 3);
      m.start(DateTime(2026, 10, 14, 10));
      m.giveCard('p1', MatchCardKind.yellow,
          now: DateTime(2026, 10, 14, 10, 3));
      expect(m.suspendedIds(200), isEmpty);
      expect(m.playingTime(600)['p1'], 600);
    });

    test('a suspension across a substitution counts only time on the pitch', () {
      final m = match(onPitch: 2, players: 3);
      final t0 = DateTime(2026, 10, 14, 10);
      m.start(t0);
      // p1 off at 5:00 on a yellow for five minutes, so until 10:00 — and
      // substituted at 10:00, once the suspension has been served.
      m.giveCard('p1', MatchCardKind.yellow,
          seconds: 300, now: t0.add(const Duration(minutes: 5)));
      expect(m.substitute('p1', 'p3', t0.add(const Duration(minutes: 10))),
          isTrue);
      final t = m.playingTime(900);
      expect(t['p1'], 600 - 300);
      expect(t['p3'], 300);
      expect(t['p2'], 900);
      // Two overlapping cards are not counted twice: green 7:00–9:00 and
      // yellow 8:00–13:00 sit p2 out from 7:00 to 13:00, six minutes.
      m.giveCard('p2', MatchCardKind.green,
          seconds: 120, now: t0.add(const Duration(minutes: 7)));
      m.giveCard('p2', MatchCardKind.yellow,
          seconds: 300, now: t0.add(const Duration(minutes: 8)));
      expect(m.playingTime(900)['p2'], 900 - 360);
    });

    test('suggestions ignore a player sitting out a card', () {
      final m = match(onPitch: 2, players: 4);
      m.start(DateTime(2026, 10, 14, 10));
      m.giveCard('p1', MatchCardKind.yellow,
          seconds: 600, now: DateTime(2026, 10, 14, 10, 5));
      final swaps = m.suggest(at: 600);
      expect(swaps.map((s) => s.outId), isNot(contains('p1')));
      expect(swaps.length, 1);
      expect(swaps.single.outId, 'p2');
    });

    test('round-trips, and an old file without cards still opens', () {
      final m = match(onPitch: 2, players: 3);
      m.start(DateTime(2026, 10, 14, 10));
      m.giveCard('p1', MatchCardKind.green,
          seconds: 120, now: DateTime(2026, 10, 14, 10, 2));
      final back = MatchDay.fromJson(m.toJson());
      expect(back.cards.single.kind, MatchCardKind.green);
      expect(back.cards.single.seconds, 120);
      expect(back.cards.single.clock, 120);
      final json = m.toJson()..remove('cards');
      expect(MatchDay.fromJson(json).cards, isEmpty);
    });
  });

  group('shoot-out', () {
    test('keeps the tally and the order, sudden death without end', () {
      final m = match();
      for (var i = 0; i < 7; i++) {
        m.addShootOutAttempt(ShootOutAttempt(
            us: true, playerId: 'p${i % 4 + 1}', scored: i.isEven));
        m.addShootOutAttempt(
            ShootOutAttempt(us: false, taker: '#${i + 1}', scored: i < 3));
      }
      expect(m.shootOut.length, 14);
      expect(m.shootOutScore, (us: 4, them: 3));
      m.removeLastShootOutAttempt();
      expect(m.shootOut.length, 13);
      final back = MatchDay.fromJson(m.toJson());
      expect(back.shootOut.length, 13);
      expect(back.shootOut.first.playerId, 'p1');
      expect(back.shootOut[1].taker, '#1');
      expect(back.shootOut[1].us, isFalse);
      expect(back.shootOutScore, (us: 4, them: 3));
      expect(MatchDay.fromJson(match().toJson()).shootOut, isEmpty);
    });
  });

  group('sets', () {
    MatchDay sets({String rules = 'fivb', int bestOf = 5}) => MatchDay(
          periods: bestOf,
          periodSeconds: 0,
          onPitch: 6,
          players: [
            for (var i = 1; i <= 10; i++)
              MatchPlayer(id: 'p$i', name: 'Player $i', number: '$i'),
          ],
          starters: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
          startedAt: DateTime(2026, 10, 14, 10),
          countsSets: true,
          rules: rules,
          liberos: const ['p10'],
        );

    test('substitutions stop at the rule set\'s limit for the set', () {
      final m = sets();
      expect(m.subLimit, 6);
      expect(m.subsLeft, 6);
      m.point(us: true);
      final pairs = [
        ('p1', 'p7'), ('p2', 'p8'), ('p3', 'p9'), ('p7', 'p1'),
        ('p8', 'p2'), ('p9', 'p3'),
      ];
      for (final (out, inn) in pairs) {
        expect(m.substitute(out, inn), isTrue, reason: '$out → $inn');
      }
      expect(m.subsLeft, 0);
      expect(m.substitute('p1', 'p7'), isFalse);
      expect(sets(rules: 'usav').subLimit, 12);
      expect(sets(rules: 'nfhs').subLimit, 18);
      expect(sets(rules: 'ncaa').subLimit, 15);
    });

    test('a libero replacement is not counted', () {
      final m = sets();
      m.point(us: false);
      expect(m.substitute('p5', 'p10', null, SubstitutionKind.libero), isTrue);
      expect(m.onPitchIds, contains('p10'));
      expect(m.subsLeft, 6);
      expect(m.substitute('p10', 'p5', null, SubstitutionKind.libero), isTrue);
      expect(m.subsLeft, 6);
      // A libero swap needs a libero in it.
      expect(m.substitute('p1', 'p7', null, SubstitutionKind.libero), isFalse);
      expect(m.subCounts()['p10'], (inn: 0, out: 0));
    });

    test('the starting six can change before the first point, free', () {
      final m = sets();
      expect(m.substitute('p1', 'p7', null, SubstitutionKind.lineup), isTrue);
      expect(m.subsLeft, 6);
      m.point(us: true);
      expect(m.substitute('p2', 'p8', null, SubstitutionKind.lineup), isFalse);
      expect(m.substitute('p2', 'p8'), isTrue);
      expect(m.subsLeft, 5);
      final played = m.setsPlayed();
      expect(played['p1'], 0, reason: 'taken off before the first point');
      expect(played['p7'], 1);
      expect(played['p2'], 1, reason: 'played until substituted');
      expect(played['p8'], 1);
      expect(played['p9'], 0);
      expect(m.subCounts()['p8'], (inn: 1, out: 0));
      expect(m.subCounts()['p2'], (inn: 0, out: 1));
    });

    test('the end of a set files the score and starts the counts again', () {
      final m = sets(bestOf: 3);
      for (var i = 0; i < 25; i++) {
        m.point(us: true);
      }
      for (var i = 0; i < 21; i++) {
        m.point(us: false);
      }
      expect(m.timeout(us: true), isTrue);
      expect(m.timeout(us: true), isTrue);
      expect(m.timeout(us: true), isFalse);
      m.substitute('p1', 'p7');
      m.endSet();
      expect(m.setScores.single.us, 25);
      expect(m.setScores.single.them, 21);
      expect(m.setScores.single.subs, 1);
      expect(m.setScores.single.timeoutsUs, 2);
      expect(m.period, 2);
      expect(m.scoreUs, 0);
      expect(m.timeoutsUs, 0);
      expect(m.subsLeft, 6);
      expect(m.subsInSet(1), 1);
      expect(m.isFinished, isFalse);
      // The lineup carries over; p7 is still on.
      expect(m.onPitchIds, contains('p7'));
      // A second set won is the match in a best of three.
      m.point(us: true, delta: 25);
      m.endSet();
      expect(m.setsWonUs, 2);
      expect(m.isFinished, isTrue);
      expect(m.setsPlayed()['p7'], 2);
      expect(m.setsPlayed()['p1'], 1);
    });

    test('the clock never runs, and the file keeps the sets', () {
      final m = sets();
      m.start();
      expect(m.isRunning, isFalse);
      expect(m.isPeriodOver(), isFalse);
      m.point(us: true, delta: 3);
      m.point(us: true, delta: -1);
      m.substitute('p6', 'p10', null, SubstitutionKind.libero);
      final back = MatchDay.fromJson(m.toJson());
      expect(back.countsSets, isTrue);
      expect(back.rules, 'fivb');
      expect(back.liberos, ['p10']);
      expect(back.scoreUs, 2);
      expect(back.subs.single.kind, SubstitutionKind.libero);
      expect(back.subsLeft, 6);
      // A clock match written before set mode existed reads as one.
      final old = match().toJson()..remove('countsSets');
      expect(MatchDay.fromJson(old).countsSets, isFalse);
    });
  });

  group('identity', () {
    test('has an id and a last-written time that survive the file', () {
      final m = match();
      expect(m.id, isNotEmpty);
      final back = MatchDay.fromJson(m.toJson());
      expect(back.id, m.id);
      expect(back.updatedAt, m.updatedAt);
      // A file from before ids were written gets one from its start time.
      final json = m.toJson()
        ..remove('id')
        ..remove('updatedAt');
      final old = MatchDay.fromJson(json);
      expect(old.id, 'm${m.startedAt.microsecondsSinceEpoch}');
      expect(old.id, MatchDay.fromJson(json).id);
      expect(old.updatedAt, m.startedAt);
    });
  });
}
