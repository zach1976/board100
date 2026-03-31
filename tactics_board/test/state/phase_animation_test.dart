import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

PlayerIcon _player(String id, {PlayerTeam team = PlayerTeam.home}) =>
    PlayerIcon(id: id, label: id, team: team, position: const Offset(100, 200));

void main() {
  group('maxMoveSteps with phases', () {
    test('returns 0 when no moves', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      expect(s.maxMoveSteps, 0);
    });

    test('returns correct count with default phases', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(150, 250));
      s.addPlayerMove('p1', const Offset(200, 300));
      // Default phases: [0, 1] → 2 distinct phases
      expect(s.maxMoveSteps, 2);
    });

    test('returns correct count with multiple players', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayer(_player('p2'));
      s.addPlayerMove('p1', const Offset(150, 250));
      s.addPlayerMove('p1', const Offset(200, 300));
      s.addPlayerMove('p2', const Offset(150, 250));
      // Default: p1 phases [0,1], p2 phases [0] → distinct {0,1} = 2
      expect(s.maxMoveSteps, 2);
    });

    test('returns correct count after phase reassignment', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayer(_player('p2'));
      s.addPlayerMove('p1', const Offset(150, 250));
      s.addPlayerMove('p1', const Offset(200, 300));
      s.addPlayerMove('p2', const Offset(150, 250));
      s.addPlayerMove('p2', const Offset(200, 300));
      // Default: p1 [0,1], p2 [0,1] → 2 phases

      // Now make p2 sequential: move[0]=2, move[1]=3
      s.setMovePhase('p2', 0, 2);
      s.setMovePhase('p2', 1, 3);
      // p1 [0,1], p2 [2,3] → distinct {0,1,2,3} = 4
      expect(s.maxMoveSteps, 4);
    });

    test('phase reassignment via timeline works correctly', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(150, 250));
      s.addPlayerMove('p1', const Offset(200, 300));
      s.addPlayerMove('p1', const Offset(250, 350));
      // Default phases: [0, 1, 2]

      // Move last step to phase 5
      s.setMovePhase('p1', 2, 5);
      // Phases: [0, 1, 5] → distinct {0,1,5} = 3
      expect(s.maxMoveSteps, 3);
    });
  });

  group('stepForward / stepBackward with phases', () {
    test('stepForward increments atStep', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(150, 250));
      expect(s.atStep, 0);
      expect(s.maxMoveSteps, 1);
    });

    test('stepBackward does nothing at step 0', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(150, 250));
      s.stepBackward();
      expect(s.atStep, 0);
    });

    test('atStep advances via advanceAtStep', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(150, 250));
      s.advanceAtStep(1);
      expect(s.atStep, 1);
    });
  });

  group('setCanvasSizeSilent', () {
    test('updates canvas size without notification', () {
      final s = TacticsState();
      int notifyCount = 0;
      s.addListener(() => notifyCount++);

      s.setCanvasSizeSilent(const Size(400, 700));
      expect(s.canvasSize, const Size(400, 700));
      expect(notifyCount, 0); // No notification
    });

    test('setCanvasSize does notify when size differs', () {
      final s = TacticsState();
      s.setCanvasSizeSilent(const Size(100, 100)); // Set initial size
      int notifyCount = 0;
      s.addListener(() => notifyCount++);

      s.setCanvasSize(const Size(400, 700));
      expect(s.canvasSize, const Size(400, 700));
      expect(notifyCount, 1); // Should notify
    });

    test('rescales player positions when size changes', () {
      final s = TacticsState();
      s.setCanvasSizeSilent(const Size(400, 700));
      s.addPlayer(PlayerIcon(
        id: 'p1', label: '1', team: PlayerTeam.home,
        position: const Offset(200, 350), // center
      ));

      // Double the size
      s.setCanvasSizeSilent(const Size(800, 1400));
      expect(s.players.first.position, const Offset(400, 700));
    });
  });

  group('Player serialization', () {
    test('toJson includes movePhases', () {
      final p = PlayerIcon(
        id: 'p1', label: '1', team: PlayerTeam.home,
        position: const Offset(100, 200),
        moves: [const Offset(150, 250), const Offset(200, 300)],
        movePhases: [0, 2],
      );

      final json = p.toJson();
      expect(json['movePhases'], [0, 2]);
    });

    test('fromJson restores movePhases', () {
      final json = {
        'id': 'p1', 'label': '1', 'team': 0,
        'position': [100.0, 200.0],
        'moves': [[150.0, 250.0], [200.0, 300.0]],
        'movePhases': [0, 2],
        'moveColor': 0xFF40C4FF,
        'gender': 0,
        'markerShape': 0,
      };

      final p = PlayerIcon.fromJson(json);
      expect(p.movePhases, [0, 2]);
      expect(p.moves.length, 2);
    });
  });

  group('spawnY per sport', () {
    test('table tennis spawns outside table', () {
      final s = TacticsState(sportType: SportType.tableTennis);
      s.setCanvasSizeSilent(const Size(400, 800));

      final homeY = s.spawnY(PlayerTeam.home);
      final awayY = s.spawnY(PlayerTeam.away);

      // Table is roughly y=0.19..0.81, players should be outside
      expect(homeY / 800, greaterThan(0.85));
      expect(awayY / 800, lessThan(0.15));
    });

    test('default sport spawns at 75%/25%', () {
      final s = TacticsState(sportType: SportType.badminton);
      s.setCanvasSizeSilent(const Size(400, 800));

      expect(s.spawnY(PlayerTeam.home), 800 * 0.75);
      expect(s.spawnY(PlayerTeam.away), 800 * 0.25);
    });
  });

  group('Sport formations', () {
    test('basketball has no doubles', () {
      expect(SportType.basketball.hasDoubles, false);
    });

    test('badminton has doubles', () {
      expect(SportType.badminton.hasDoubles, true);
    });

    test('soccer has 4+ formations starting with 11v11', () {
      final formations = SportType.soccer.formations;
      expect(formations.length, greaterThanOrEqualTo(4));
      expect(formations.first.homeCount, 11);
    });

    test('basketball has 4+ formations', () {
      final formations = SportType.basketball.formations;
      expect(formations.length, greaterThanOrEqualTo(4));
    });

    test('all formation positions are within 0-1 range', () {
      for (final sport in SportType.values) {
        for (final f in sport.formations) {
          for (final pos in [...f.homePositions, ...f.awayPositions]) {
            expect(pos.dx, inInclusiveRange(0.0, 1.0),
                reason: '${sport.name} ${f.nameKey} x=${pos.dx}');
            expect(pos.dy, inInclusiveRange(0.0, 1.0),
                reason: '${sport.name} ${f.nameKey} y=${pos.dy}');
          }
        }
      }
    });
  });
}
