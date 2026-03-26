import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';

void main() {
  group('PlayerIcon.isBall', () {
    test('false for home team', () {
      final p = PlayerIcon(id: '1', label: '1', team: PlayerTeam.home, position: Offset.zero);
      expect(p.isBall, false);
    });

    test('false for neutral without sportType', () {
      final p = PlayerIcon(id: '1', label: '', team: PlayerTeam.neutral, position: Offset.zero);
      expect(p.isBall, false);
    });

    test('true for neutral with sportType', () {
      final p = PlayerIcon(id: '1', label: '', team: PlayerTeam.neutral, position: Offset.zero, sportType: SportType.badminton);
      expect(p.isBall, true);
    });
  });

  group('PlayerIcon.teamColor', () {
    test('home is blue', () => expect(PlayerIcon.teamColor(PlayerTeam.home), const Color(0xFF1565C0)));
    test('away is red', () => expect(PlayerIcon.teamColor(PlayerTeam.away), const Color(0xFFC62828)));
    test('neutral is gray', () => expect(PlayerIcon.teamColor(PlayerTeam.neutral), const Color(0xFF424242)));
  });

  group('PlayerIcon.color', () {
    test('returns teamColor for team', () {
      final p = PlayerIcon(id: '1', label: '1', team: PlayerTeam.away, position: Offset.zero);
      expect(p.color, PlayerIcon.teamColor(PlayerTeam.away));
    });
  });

  group('PlayerIcon.moveColorForIndex', () {
    test('wraps around at 8', () {
      expect(PlayerIcon.moveColorForIndex(0), PlayerIcon.moveColorForIndex(8));
    });

    test('all 8 colors are distinct', () {
      final colors = List.generate(8, PlayerIcon.moveColorForIndex);
      expect(colors.toSet().length, 8);
    });
  });

  group('PlayerIcon defaults', () {
    late PlayerIcon p;
    setUp(() => p = PlayerIcon(id: '1', label: '1', team: PlayerTeam.home, position: Offset.zero));

    test('scale defaults to 1.0', () => expect(p.scale, 1.0));
    test('isSelected defaults to false', () => expect(p.isSelected, false));
    test('moves defaults to empty', () => expect(p.moves, isEmpty));
  });

  group('PlayerIcon.copyWith', () {
    test('replaces only specified fields', () {
      final p = PlayerIcon(id: 'x', label: '1', team: PlayerTeam.home, position: const Offset(10, 20), scale: 1.5);
      final copy = p.copyWith(label: '2', position: const Offset(30, 40));
      expect(copy.id, 'x');
      expect(copy.label, '2');
      expect(copy.team, PlayerTeam.home);
      expect(copy.position, const Offset(30, 40));
      expect(copy.scale, 1.5);
    });

    test('moves list is a deep copy', () {
      final p = PlayerIcon(id: 'x', label: '1', team: PlayerTeam.home, position: Offset.zero, moves: [const Offset(1, 2)]);
      final copy = p.copyWith();
      copy.moves.add(const Offset(3, 4));
      expect(p.moves.length, 1);
    });
  });
}
