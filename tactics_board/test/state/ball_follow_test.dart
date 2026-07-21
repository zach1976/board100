import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

PlayerIcon _player(String id, Offset pos, {PlayerTeam team = PlayerTeam.home}) =>
    PlayerIcon(id: id, label: id, team: team, position: pos);

PlayerIcon _ball(String id, Offset pos) =>
    PlayerIcon(id: id, label: '', team: PlayerTeam.neutral,
        sportType: SportType.soccer, position: pos);

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  PlayerIcon byId(TacticsState s, String id) =>
      s.players.firstWhere((p) => p.id == id);

  group('ball possession (attach on drop)', () {
    test('dropping a ball onto a player attaches it', () {
      final s = TacticsState()
        ..addPlayer(_player('p1', const Offset(100, 100)))
        ..addPlayer(_ball('ball', const Offset(400, 400)));
      // Drop the ball right on p1.
      s.movePlayerEnd('ball', const Offset(108, 104));
      expect(byId(s, 'ball').attachedTo, 'p1');
    });

    test('dropping a ball in open space leaves it loose', () {
      final s = TacticsState()
        ..addPlayer(_player('p1', const Offset(100, 100)))
        ..addPlayer(_ball('ball', const Offset(100, 100), ));
      s.players.firstWhere((p) => p.id == 'ball'); // sanity
      s.movePlayerEnd('ball', const Offset(600, 600)); // far from p1
      expect(byId(s, 'ball').attachedTo, isNull);
    });

    test('dropping onto a different player reassigns possession', () {
      final s = TacticsState()
        ..addPlayer(_player('p1', const Offset(100, 100)))
        ..addPlayer(_player('p2', const Offset(500, 500)))
        ..addPlayer(_ball('ball', const Offset(100, 100)));
      s.movePlayerEnd('ball', const Offset(102, 100)); // → p1
      expect(byId(s, 'ball').attachedTo, 'p1');
      s.movePlayerEnd('ball', const Offset(500, 502)); // → p2
      expect(byId(s, 'ball').attachedTo, 'p2');
    });

    test('a marker is not a valid ball holder', () {
      final s = TacticsState()
        ..addPlayer(PlayerIcon(
            id: 'cone', label: '', team: PlayerTeam.neutral,
            position: const Offset(100, 100), markerShape: MarkerShape.cone))
        ..addPlayer(_ball('ball', const Offset(400, 400)));
      s.movePlayerEnd('ball', const Offset(101, 100));
      expect(byId(s, 'ball').attachedTo, isNull);
    });
  });

  group('ball follows its holder', () {
    TacticsState attached() {
      final s = TacticsState()
        ..addPlayer(_player('p1', const Offset(100, 100)))
        ..addPlayer(_ball('ball', const Offset(120, 100)));
      s.movePlayerEnd('ball', const Offset(112, 104)); // attach to p1
      return s;
    }

    test('moving the holder moves the ball by the same delta', () {
      final s = attached();
      final ballBefore = byId(s, 'ball').position;
      s.movePlayer('p1', const Offset(300, 250)); // delta (200, 150)
      final ballAfter = byId(s, 'ball').position;
      expect(ballAfter - ballBefore, const Offset(200, 150));
    });

    test('moving the ball itself does not drag the holder', () {
      final s = attached();
      final p1Before = byId(s, 'p1').position;
      s.movePlayer('ball', const Offset(200, 200));
      expect(byId(s, 'p1').position, p1Before);
    });

    test('deleting the holder releases the ball', () {
      final s = attached();
      expect(byId(s, 'ball').attachedTo, 'p1');
      s.removePlayer('p1');
      expect(byId(s, 'ball').attachedTo, isNull);
    });
  });

  group('serialization', () {
    test('attachedTo round-trips through json', () {
      final ball = _ball('ball', const Offset(10, 10)).copyWith(attachedTo: 'p9');
      final back = PlayerIcon.fromJson(ball.toJson());
      expect(back.attachedTo, 'p9');
    });

    test('clearAttachedTo drops it', () {
      final ball = _ball('ball', const Offset(10, 10)).copyWith(attachedTo: 'p9');
      expect(ball.copyWith(clearAttachedTo: true).attachedTo, isNull);
    });
  });
}
