import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/sport_type.dart';

/// 9v9 is the youth format (U11-U12) coaches asked for: the Add sheet builds
/// its count chips from the formations, so three 9-a-side shapes give it a
/// "9v9" chip between 11v11 and 7v7.
void main() {
  final nine = SportType.soccer.formations
      .where((f) => f.homeCount == 9 && f.awayCount == 9)
      .toList();

  test('soccer offers 9v9 shapes alongside 11v11 and 7v7', () {
    expect(nine.map((f) => f.nameKey).toSet(),
        {'formation_9v9_332', 'formation_9v9_323', 'formation_9v9_233'});
    final counts = SportType.soccer.formations.map((f) => f.homeCount).toSet();
    expect(counts, containsAll([11, 9, 7]));
  });

  test('each 9v9 shape is a keeper and eight outfielders in its own half', () {
    for (final f in nine) {
      // Keeper deepest; everyone else between him and halfway.
      expect(f.homePositions.first.dy, greaterThan(0.75), reason: f.nameKey);
      expect(f.awayPositions.first.dy, lessThan(0.25), reason: f.nameKey);
      for (final p in f.homePositions) {
        expect(p.dy, inInclusiveRange(0.5, 0.87), reason: f.nameKey);
        expect(p.dx, inInclusiveRange(0.0, 1.0), reason: f.nameKey);
      }
      for (final p in f.awayPositions) {
        expect(p.dy, inInclusiveRange(0.13, 0.5), reason: f.nameKey);
      }
      // The name is the outfield shape: 3-3-2 has eight outfielders.
      final shape = f.nameKey.split('_').last.split('').map(int.parse);
      expect(shape.reduce((a, b) => a + b), 8, reason: f.nameKey);
    }
  });
}
