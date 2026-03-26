import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/sport_formation.dart';

void main() {
  group('SportFormation', () {
    const formation = SportFormation(
      nameKey: 'test',
      homePositions: [Offset(0.5, 0.75), Offset(0.3, 0.6)],
      awayPositions: [Offset(0.5, 0.25)],
    );

    test('homeCount returns number of home positions', () => expect(formation.homeCount, 2));
    test('awayCount returns number of away positions', () => expect(formation.awayCount, 1));
    test('addBall defaults to true', () => expect(formation.addBall, true));

    test('addBall can be false', () {
      const f = SportFormation(nameKey: 'no_ball', homePositions: [], awayPositions: [], addBall: false);
      expect(f.addBall, false);
    });

    test('homeCount is 0 for empty positions', () {
      const f = SportFormation(nameKey: 'empty', homePositions: [], awayPositions: []);
      expect(f.homeCount, 0);
    });
  });
}
