import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// Turning an element, and the promise that old boards do not move.
void main() {
  PlayerIcon icon({double rotation = 0}) => PlayerIcon(
        id: 'a',
        label: '7',
        team: PlayerTeam.home,
        position: const Offset(100, 200),
        rotation: rotation,
      );

  group('rotation', () {
    test('round-trips through JSON', () {
      final turned = icon(rotation: math.pi / 2);
      final back = PlayerIcon.fromJson(turned.toJson());
      expect(back.rotation, closeTo(math.pi / 2, 1e-9));
    });

    test('is left out of the file when it is zero', () {
      // One key per icon per save, for a number meaning "as drawn", on boards
      // where almost nothing is turned.
      expect(icon().toJson().containsKey('rotation'), isFalse);
    });

    test('a board saved before rotation existed reads back unturned', () {
      // The regression that matters: every tactic anyone has already saved,
      // and all 624 generated drill boards, have no such key.
      final old = icon().toJson()..remove('rotation');
      expect(PlayerIcon.fromJson(old).rotation, 0.0);
    });

    test('copyWith carries it', () {
      expect(icon(rotation: 1.2).copyWith(label: '9').rotation, 1.2);
    });
  });

  group('snapAngle', () {
    double deg(double d) => d * math.pi / 180;

    test('snaps to the nearest 15 degrees', () {
      expect(TacticsState.snapAngle(deg(22)), closeTo(deg(15), 1e-6));
      expect(TacticsState.snapAngle(deg(23)), closeTo(deg(30), 1e-6));
    });

    test('lands exactly square when it is nearly square', () {
      // A hurdle three degrees off does not read as three degrees off; it
      // reads as drawn carelessly.
      expect(TacticsState.snapAngle(deg(88)), closeTo(math.pi / 2, 1e-9));
      expect(TacticsState.snapAngle(deg(2)), 0.0);
      expect(TacticsState.snapAngle(deg(-91)), closeTo(-math.pi / 2, 1e-9));
    });

    test('keeps a deliberate diagonal', () {
      // 45 is a real answer — the snap must not swallow it into 90.
      expect(TacticsState.snapAngle(deg(45)), closeTo(deg(45), 1e-6));
    });
  });
}
