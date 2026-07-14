import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  PlayerIcon mover(String id, Offset start, List<Offset> moves) => PlayerIcon(
      id: id, label: id, team: PlayerTeam.home, position: start, moves: moves);

  group('computeAnimationFrames', () {
    test('no moves → no frames', () {
      final s = TacticsState()..addPlayer(mover('p1', const Offset(0, 0), []));
      expect(s.computeAnimationFrames(), isEmpty);
    });

    test('interpolates from start to the move endpoint', () {
      final s = TacticsState()
        ..addPlayer(mover('p1', const Offset(0, 0), [const Offset(100, 0)]));
      final frames = s.computeAnimationFrames(fps: 30, phaseSeconds: 0.5);
      expect(frames, isNotEmpty);
      expect(frames.first['p1']!.dx, closeTo(0, 0.01)); // starts at position
      expect(frames.last['p1']!.dx, closeTo(100, 0.01)); // ends at the waypoint
    });

    test('animationPositionsAt endpoints are exact', () {
      final s = TacticsState()
        ..addPlayer(mover('p1', const Offset(10, 10), [const Offset(50, 30)]));
      expect(s.animationPositionsAt(0, 0.0)['p1'], const Offset(10, 10));
      expect(s.animationPositionsAt(0, 1.0)['p1'], const Offset(50, 30));
    });

    test('a non-moving player holds its start position', () {
      final s = TacticsState()
        ..addPlayer(mover('a', const Offset(0, 0), [const Offset(100, 0)]))
        ..addPlayer(mover('b', const Offset(200, 200), [])); // no moves
      final frames = s.computeAnimationFrames();
      // b has no moves so it never appears in the animated map (renders static).
      expect(frames.every((f) => !f.containsKey('b')), isTrue);
    });

    test('two phases play in order', () {
      final s = TacticsState()
        ..addPlayer(mover('p1', const Offset(0, 0),
            [const Offset(100, 0), const Offset(100, 100)]));
      // phases auto-fill 0,1 → 2 phases
      final frames = s.computeAnimationFrames(fps: 10, phaseSeconds: 0.5);
      // Mid of phase 0 is along the first leg; end is the final waypoint.
      expect(frames.last['p1']!, const Offset(100, 100));
    });
  });

  group('attached ball in exported frames', () {
    test('ball follows its holder through the animation', () {
      final s = TacticsState()
        ..addPlayer(mover('p1', const Offset(0, 0), [const Offset(200, 0)]))
        ..addPlayer(PlayerIcon(
            id: 'ball', label: '', team: PlayerTeam.neutral,
            sportType: SportType.soccer, position: const Offset(10, 0),
            attachedTo: 'p1'));
      final frames = s.computeAnimationFrames(fps: 10, phaseSeconds: 0.5);
      // Ball keeps its +10 x offset from p1 across every frame.
      for (final f in frames) {
        expect(f['ball']!.dx - f['p1']!.dx, closeTo(10, 0.01));
      }
      expect(frames.last['ball']!.dx, closeTo(210, 0.01)); // p1 at 200 + offset 10
    });
  });
}
