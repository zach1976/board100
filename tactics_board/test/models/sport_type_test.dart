import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/sport_type.dart';

void main() {
  group('SportType.translationKey', () {
    test('each sport has a unique key', () {
      final keys = SportType.values.map((s) => s.translationKey).toList();
      expect(keys.toSet().length, SportType.values.length);
    });

    test('badminton', () => expect(SportType.badminton.translationKey, 'sport_badminton'));
    test('tableTennis', () => expect(SportType.tableTennis.translationKey, 'sport_table_tennis'));
    test('tennis', () => expect(SportType.tennis.translationKey, 'sport_tennis'));
    test('basketball', () => expect(SportType.basketball.translationKey, 'sport_basketball'));
    test('volleyball', () => expect(SportType.volleyball.translationKey, 'sport_volleyball'));
    test('pickleball', () => expect(SportType.pickleball.translationKey, 'sport_pickleball'));
    test('soccer', () => expect(SportType.soccer.translationKey, 'sport_soccer'));
  });

  group('SportType.emoji', () {
    test('each sport has a non-empty emoji', () {
      for (final s in SportType.values) {
        expect(s.emoji, isNotEmpty, reason: '${s.name} missing emoji');
      }
    });

    test('badminton', () => expect(SportType.badminton.emoji, '🏸'));
    test('tableTennis', () => expect(SportType.tableTennis.emoji, '🏓'));
    test('tennis', () => expect(SportType.tennis.emoji, '🎾'));
    test('basketball', () => expect(SportType.basketball.emoji, '🏀'));
    test('volleyball', () => expect(SportType.volleyball.emoji, '🏐'));
    test('pickleball', () => expect(SportType.pickleball.emoji, '🥒'));
    test('soccer', () => expect(SportType.soccer.emoji, '⚽'));
  });

  group('SportType.isLandscapeCourt', () {
    test('only basketball is landscape', () {
      expect(SportType.basketball.isLandscapeCourt, true);
    });

    test('all other sports are portrait', () {
      for (final s in SportType.values.where((s) => s != SportType.basketball)) {
        expect(s.isLandscapeCourt, false, reason: '${s.name} should be portrait');
      }
    });
  });

  group('SportType.formations', () {
    test('all sports have at least 1 formation', () {
      for (final s in SportType.values) {
        expect(s.formations, isNotEmpty, reason: '${s.name} has no formations');
      }
    });

    test('badminton has 2 formations', () => expect(SportType.badminton.formations.length, 2));
    test('tableTennis has 2 formations', () => expect(SportType.tableTennis.formations.length, 2));
    test('tennis has 2 formations', () => expect(SportType.tennis.formations.length, 2));
    test('basketball has 2 formations', () => expect(SportType.basketball.formations.length, 2));
    test('volleyball has 1 formation', () => expect(SportType.volleyball.formations.length, 1));
    test('pickleball has 2 formations', () => expect(SportType.pickleball.formations.length, 2));
    test('soccer has 3 formations', () => expect(SportType.soccer.formations.length, 3));

    test('badminton singles is 1v1', () {
      final f = SportType.badminton.formations[0];
      expect(f.homeCount, 1);
      expect(f.awayCount, 1);
    });

    test('badminton doubles is 2v2', () {
      final f = SportType.badminton.formations[1];
      expect(f.homeCount, 2);
      expect(f.awayCount, 2);
    });

    test('volleyball 6v6 is 6 per side', () {
      final f = SportType.volleyball.formations[0];
      expect(f.homeCount, 6);
      expect(f.awayCount, 6);
    });

    test('soccer 11v11 is 11 per side', () {
      final f = SportType.soccer.formations[2];
      expect(f.homeCount, 11);
      expect(f.awayCount, 11);
    });

    test('all formation positions are within 0.0–1.0', () {
      for (final sport in SportType.values) {
        for (final formation in sport.formations) {
          for (final pos in [...formation.homePositions, ...formation.awayPositions]) {
            expect(pos.dx, inInclusiveRange(0.0, 1.0), reason: '${sport.name} dx=${pos.dx} out of range');
            expect(pos.dy, inInclusiveRange(0.0, 1.0), reason: '${sport.name} dy=${pos.dy} out of range');
          }
        }
      }
    });
  });
}
