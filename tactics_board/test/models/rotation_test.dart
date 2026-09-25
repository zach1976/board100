import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// Turning an element, and the promise that old boards do not move.
void main() {
  // TacticsState talks to the external display over a method channel the
  // moment it is built.
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('turning a player by hand', () {
    /// The board's own facing rule recomputes a heading every beat, and it
    /// used to win over rotation for everyone — so the edit bar's turn
    /// buttons moved the number on the bar and nothing on the pitch.
    TacticsState boardWith(PlayerIcon p) {
      final s = TacticsState();
      s.loadFromJson({
        'sportType': SportType.soccer.index,
        'players': [p.toJson()],
        'strokes': <dynamic>[],
      });
      return s;
    }

    test('locks the facing, and the reset gives it back to the board', () {
      final state = boardWith(icon());
      final id = state.players.first.id;
      state.rotatePlayer(id, math.pi / 4);
      expect(state.players.first.facingLocked, isTrue);
      expect(state.players.first.rotation, closeTo(math.pi / 4, 1e-9));

      // What the bar's 复位 does: turn back to zero.
      state.rotatePlayer(id, 0);
      expect(state.players.first.facingLocked, isFalse,
          reason: 'back at zero the board decides again');
    });

    test('a marker is not locked by turning it', () {
      // Equipment is rotated as a picture; it has no facing rule to fight.
      final state = boardWith(PlayerIcon(
        id: 'm',
        label: '',
        team: PlayerTeam.neutral,
        position: const Offset(10, 10),
        markerShape: MarkerShape.cone,
      ));
      state.rotatePlayer('m', math.pi / 2);
      expect(state.players.first.facingLocked, isFalse);
    });

    test('survives a save and a reload', () {
      final turned = icon(rotation: math.pi / 2).copyWith(facingLocked: true);
      expect(PlayerIcon.fromJson(turned.toJson()).facingLocked, isTrue);
      // And costs nothing on the boards where nobody turned anybody.
      expect(icon().toJson().containsKey('faceLock'), isFalse);
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
