import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/practice_session.dart';

PracticeSession session({
  required DateTime at,
  List<String> present = const [],
  String? squad,
}) =>
    PracticeSession(
      planName: 'Tuesday',
      startedAt: at,
      completedAt: at.add(const Duration(minutes: 75)),
      itemsCompleted: 5,
      plannedItems: 5,
      totalSecondsSpent: 4500,
      completed: true,
      attendeeIds: present,
      squadId: squad,
    );

void main() {
  group('attendance on a session', () {
    test('survives a JSON round trip', () {
      final s = session(
        at: DateTime(2026, 9, 1, 18),
        present: ['m1', 'm3'],
        squad: 'g1',
      );

      final back = PracticeSession.fromJson(s.toJson());

      expect(back.attendeeIds, ['m1', 'm3']);
      expect(back.squadId, 'g1');
      expect(back.hasAttendance, isTrue);
    });

    test('a session recorded before attendance existed still loads', () {
      final legacy = {
        'planName': 'Old Tuesday',
        'startedAt': '2026-05-01T18:00:00.000',
        'completedAt': '2026-05-01T19:15:00.000',
        'itemsCompleted': 4,
        'plannedItems': 4,
        'totalSecondsSpent': 4500,
        'completed': true,
      };

      final back = PracticeSession.fromJson(legacy);

      expect(back.attendeeIds, isEmpty);
      expect(back.hasAttendance, isFalse,
          reason: 'no record is not the same as nobody came');
      expect(back.planName, 'Old Tuesday');
    });

    test('withAttendance keeps everything else about the session', () {
      final original = session(at: DateTime(2026, 9, 1, 18));

      final updated = original.withAttendance(['m2'], 'g1');

      expect(updated.attendeeIds, ['m2']);
      expect(updated.squadId, 'g1');
      expect(updated.startedAt, original.startedAt);
      expect(updated.planName, original.planName);
      expect(updated.totalSecondsSpent, original.totalSecondsSpent);
      expect(updated.completed, original.completed);
    });

    test('an empty tick-list means nobody came, and is recorded as such', () {
      // The sheet returns [] when the coach unticks everyone. That is a real
      // answer, but it reads as "not recorded" — worth knowing the difference.
      final s = session(at: DateTime(2026, 9, 1), present: const []);
      expect(s.hasAttendance, isFalse);
    });
  });

  group('season attendance maths', () {
    // The ranking the season view shows: least-present first, because those
    // are the players a coach needs to do something about.
    test('counts appearances across sessions and ranks the strugglers first', () {
      final sessions = [
        session(at: DateTime(2026, 9, 1), present: ['a', 'b', 'c']),
        session(at: DateTime(2026, 9, 8), present: ['a', 'b']),
        session(at: DateTime(2026, 9, 15), present: ['a']),
      ];

      final counts = <String, int>{};
      for (final s in sessions) {
        for (final id in s.attendeeIds) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
      final ranked = ['a', 'b', 'c']..sort((x, y) => counts[x]!.compareTo(counts[y]!));

      expect(counts, {'a': 3, 'b': 2, 'c': 1});
      expect(ranked.first, 'c', reason: 'the player to call is at the front');
      expect(ranked.last, 'a');
    });

    test('sessions with no attendance record are excluded from the maths', () {
      final all = [
        session(at: DateTime(2026, 9, 1), present: ['a']),
        session(at: DateTime(2026, 9, 8)),
      ];

      final counted = all.where((s) => s.hasAttendance).toList();

      expect(counted.length, 1,
          reason: 'an unrecorded session would make everyone look absent');
    });
  });
}
