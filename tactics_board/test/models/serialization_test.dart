import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/drawing_stroke.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

void main() {
  group('PlayerIcon serialization', () {
    test('round-trip preserves all fields', () {
      final original = PlayerIcon(
        id: 'test1',
        label: 'GK',
        team: PlayerTeam.home,
        position: const Offset(200, 400),
        scale: 1.5,
        gender: PlayerGender.female,
        markerShape: MarkerShape.none,
        moves: [const Offset(250, 450), const Offset(300, 500)],
        movePhases: [0, 3],
        customColor: const Color(0xFF00FF00),
      );

      final json = original.toJson();
      final restored = PlayerIcon.fromJson(json);

      expect(restored.id, 'test1');
      expect(restored.label, 'GK');
      expect(restored.team, PlayerTeam.home);
      expect(restored.position, const Offset(200, 400));
      expect(restored.gender, PlayerGender.female);
      expect(restored.moves.length, 2);
      expect(restored.movePhases, [0, 3]);
      expect(restored.customColor?.value, 0xFF00FF00);
    });

    test('marker shape round-trip', () {
      final p = PlayerIcon(
        id: 'm1', label: 'X', team: PlayerTeam.neutral,
        position: const Offset(100, 100),
        markerShape: MarkerShape.triangle,
        customColor: const Color(0xFFFF0000),
      );

      final json = p.toJson();
      final restored = PlayerIcon.fromJson(json);
      expect(restored.markerShape, MarkerShape.triangle);
      expect(restored.isMarker, true);
      expect(restored.isBall, false);
    });

    test('ball icon round-trip', () {
      final p = PlayerIcon(
        id: 'b1', label: '', team: PlayerTeam.neutral,
        position: const Offset(100, 100),
        sportType: SportType.badminton,
      );

      final json = p.toJson();
      final restored = PlayerIcon.fromJson(json);
      expect(restored.isBall, true);
      expect(restored.sportType, SportType.badminton);
    });
  });

  group('DrawingStroke serialization', () {
    test('round-trip preserves all fields', () {
      final original = DrawingStroke(
        id: 's1',
        points: [const Offset(10, 20), const Offset(30, 40), const Offset(50, 60)],
        color: const Color(0xFFFF0000),
        width: 5.0,
        style: StrokeStyle.dashed,
        arrow: ArrowStyle.both,
      );

      final json = original.toJson();
      final restored = DrawingStroke.fromJson(json);

      expect(restored.id, 's1');
      expect(restored.points.length, 3);
      expect(restored.color.value, 0xFFFF0000);
      expect(restored.width, 5.0);
      expect(restored.style, StrokeStyle.dashed);
      expect(restored.arrow, ArrowStyle.both);
    });
  });

  group('TacticsState toJson / loadFromJson', () {
    test('round-trip preserves state', () {
      final s = TacticsState(sportType: SportType.badminton);
      s.setCanvasSizeSilent(const Size(400, 700));
      s.addPlayer(PlayerIcon(
        id: 'p1', label: '1', team: PlayerTeam.home,
        position: const Offset(200, 500),
      ));
      s.addPlayerMove('p1', const Offset(250, 400));

      final json = s.toJson();
      expect(json['sportType'], SportType.badminton.index);
      expect((json['players'] as List).length, 1);

      // Load into new state
      final s2 = TacticsState();
      s2.setCanvasSizeSilent(const Size(400, 700));
      s2.loadFromJson(json);

      expect(s2.sportType, SportType.badminton);
      expect(s2.players.length, 1);
      expect(s2.players.first.label, '1');
      expect(s2.players.first.moves.length, 1);
    });

    test('rescales positions on different canvas size', () {
      final s = TacticsState(sportType: SportType.badminton);
      s.setCanvasSizeSilent(const Size(400, 700));
      s.addPlayer(PlayerIcon(
        id: 'p1', label: '1', team: PlayerTeam.home,
        position: const Offset(200, 350),
      ));

      final json = s.toJson();

      // Load on a device with different size
      final s2 = TacticsState();
      s2.setCanvasSizeSilent(const Size(800, 1400));
      s2.loadFromJson(json);

      // Positions should be scaled
      expect(s2.players.first.position.dx, closeTo(400, 1));
      expect(s2.players.first.position.dy, closeTo(700, 1));
    });

    test('toJson can be encoded to JSON string', () {
      final s = TacticsState(sportType: SportType.soccer);
      s.addPlayer(PlayerIcon(
        id: 'p1', label: 'GK', team: PlayerTeam.home,
        position: const Offset(200, 600),
      ));

      final jsonStr = jsonEncode(s.toJson());
      expect(jsonStr, isNotEmpty);

      // Can be decoded back
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['sportType'], SportType.soccer.index);
    });
  });
}
