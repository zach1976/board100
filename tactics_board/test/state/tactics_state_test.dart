import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/drawing_stroke.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_formation.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

PlayerIcon _player(String id, {PlayerTeam team = PlayerTeam.home}) =>
    PlayerIcon(id: id, label: id, team: team, position: const Offset(100, 200));

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('TacticsState initial state', () {
    test('defaults to basketball', () => expect(TacticsState().sportType, SportType.basketball));

    test('accepts sport type in constructor', () {
      expect(TacticsState(sportType: SportType.badminton).sportType, SportType.badminton);
    });

    test('players and strokes are empty', () {
      final s = TacticsState();
      expect(s.players, isEmpty);
      expect(s.strokes, isEmpty);
    });

    test('canUndo and canRedo are false', () {
      final s = TacticsState();
      expect(s.canUndo, false);
      expect(s.canRedo, false);
    });

    test('isDrawingMode is false', () => expect(TacticsState().isDrawingMode, false));
    test('isAnimating is false', () => expect(TacticsState().isAnimating, false));
    test('hasMoves is false', () => expect(TacticsState().hasMoves, false));
    test('maxMoveSteps is 0', () => expect(TacticsState().maxMoveSteps, 0));
    test('selectedPlayerId is null', () => expect(TacticsState().selectedPlayerId, isNull));
    test('targetStep is 0', () => expect(TacticsState().targetStep, 0));
    test('animatedPositions is empty', () => expect(TacticsState().animatedPositions, isEmpty));
  });

  group('TacticsState.addPlayer', () {
    test('adds player to list', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      expect(s.players.length, 1);
      expect(s.players.first.id, 'p1');
    });

    test('enables undo', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      expect(s.canUndo, true);
    });

    test('assigns moveColor by index', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayer(_player('p2'));
      expect(s.players[0].moveColor, PlayerIcon.moveColorForIndex(0));
      expect(s.players[1].moveColor, PlayerIcon.moveColorForIndex(1));
    });
  });

  group('TacticsState.movePlayer', () {
    test('updates position', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.movePlayer('p1', const Offset(300, 400));
      expect(s.players.first.position, const Offset(300, 400));
    });

    test('no-op for unknown id', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.movePlayer('unknown', const Offset(300, 400));
      expect(s.players.first.position, const Offset(100, 200));
    });
  });

  group('TacticsState.movePlayerEnd', () {
    test('saves final position and clears animatedPositions', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.updateAnimatedPositions({'p1': const Offset(50, 50)});
      s.movePlayerEnd('p1', const Offset(300, 400));
      expect(s.animatedPositions, isEmpty);
      expect(s.players.first.position, const Offset(300, 400));
    });

    test('no-op for unknown id', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.movePlayerEnd('unknown', const Offset(999, 999));
      expect(s.players.first.position, const Offset(100, 200));
    });
  });

  group('TacticsState.resizePlayer', () {
    test('changes scale', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.resizePlayer('p1', 2.0);
      expect(s.players.first.scale, 2.0);
    });

    test('clamps to minimum 0.5', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.resizePlayer('p1', 0.1);
      expect(s.players.first.scale, 0.5);
    });

    test('clamps to maximum 3.0', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.resizePlayer('p1', 5.0);
      expect(s.players.first.scale, 3.0);
    });

    test('no-op for unknown id', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.resizePlayer('unknown', 2.0);
      expect(s.players.first.scale, 1.0);
    });
  });

  group('TacticsState.removePlayer', () {
    test('removes by id', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayer(_player('p2'));
      s.removePlayer('p1');
      expect(s.players.length, 1);
      expect(s.players.first.id, 'p2');
    });

    test('clears selectedPlayerId when removed player was selected', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.selectPlayer('p1');
      s.removePlayer('p1');
      expect(s.selectedPlayerId, isNull);
    });

    test('does not clear selectedPlayerId when a different player is selected', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayer(_player('p2'));
      s.selectPlayer('p2');
      s.removePlayer('p1');
      expect(s.selectedPlayerId, 'p2');
    });
  });

  group('TacticsState.selectPlayer', () {
    test('sets selectedPlayerId', () {
      final s = TacticsState();
      s.selectPlayer('p1');
      expect(s.selectedPlayerId, 'p1');
    });

    test('can set to null', () {
      final s = TacticsState();
      s.selectPlayer('p1');
      s.selectPlayer(null);
      expect(s.selectedPlayerId, isNull);
    });
  });

  group('TacticsState.setDrawingMode', () {
    test('enables drawing mode', () {
      final s = TacticsState();
      s.setDrawingMode(true);
      expect(s.isDrawingMode, true);
    });

    test('clears selectedPlayerId', () {
      final s = TacticsState();
      s.selectPlayer('p1');
      s.setDrawingMode(true);
      expect(s.selectedPlayerId, isNull);
    });

    test('can be disabled', () {
      final s = TacticsState();
      s.setDrawingMode(true);
      s.setDrawingMode(false);
      expect(s.isDrawingMode, false);
    });
  });

  group('TacticsState drawing settings', () {
    test('setStrokeStyle', () {
      final s = TacticsState();
      s.setStrokeStyle(StrokeStyle.dashed);
      expect(s.strokeStyle, StrokeStyle.dashed);
    });

    test('setArrowStyle', () {
      final s = TacticsState();
      s.setArrowStyle(ArrowStyle.both);
      expect(s.arrowStyle, ArrowStyle.both);
    });

    test('setStrokeColor', () {
      final s = TacticsState();
      s.setStrokeColor(const Color(0xFF123456));
      expect(s.strokeColor, const Color(0xFF123456));
    });

    test('setStrokeWidth', () {
      final s = TacticsState();
      s.setStrokeWidth(6.0);
      expect(s.strokeWidth, 6.0);
    });
  });

  group('TacticsState waypoints', () {
    test('addPlayerMove appends waypoint', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(200, 300));
      expect(s.players.first.moves, [const Offset(200, 300)]);
    });

    test('addPlayerMove no-op for unknown id', () {
      final s = TacticsState();
      s.addPlayerMove('unknown', const Offset(1, 1));
      expect(s.players, isEmpty);
    });

    test('hasMoves is true after adding waypoint', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(1, 1));
      expect(s.hasMoves, true);
    });

    test('maxMoveSteps reflects longest move list', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayer(_player('p2'));
      s.addPlayerMove('p1', const Offset(1, 1));
      s.addPlayerMove('p1', const Offset(2, 2));
      s.addPlayerMove('p2', const Offset(3, 3));
      expect(s.maxMoveSteps, 2);
    });

    test('movePlayerWaypoint updates position', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(200, 300));
      s.movePlayerWaypoint('p1', 0, const Offset(250, 350));
      expect(s.players.first.moves[0], const Offset(250, 350));
    });

    test('movePlayerWaypoint no-op for out-of-bounds index', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(1, 1));
      s.movePlayerWaypoint('p1', 5, const Offset(999, 999));
      expect(s.players.first.moves.length, 1);
    });

    test('movePlayerWaypoint no-op for unknown id', () {
      final s = TacticsState();
      s.movePlayerWaypoint('unknown', 0, const Offset(1, 1));
      expect(s.players, isEmpty);
    });

    test('removePlayerWaypoint removes by index', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayerMove('p1', const Offset(1, 1));
      s.addPlayerMove('p1', const Offset(2, 2));
      s.removePlayerWaypoint('p1', 0);
      expect(s.players.first.moves.length, 1);
      expect(s.players.first.moves[0], const Offset(2, 2));
    });

    test('removePlayerWaypoint no-op for unknown id', () {
      final s = TacticsState();
      s.removePlayerWaypoint('unknown', 0);
      expect(s.players, isEmpty);
    });
  });

  group('TacticsState drawing strokes', () {
    test('startStroke sets currentStroke', () {
      final s = TacticsState();
      s.startStroke(const Offset(10, 20));
      expect(s.currentStroke, isNotNull);
      expect(s.currentStroke!.points, [const Offset(10, 20)]);
    });

    test('addPoint appends to currentStroke', () {
      final s = TacticsState();
      s.startStroke(const Offset(10, 20));
      s.addPoint(const Offset(30, 40));
      expect(s.currentStroke!.points.length, 2);
    });

    test('addPoint no-op without currentStroke', () {
      final s = TacticsState();
      s.addPoint(const Offset(10, 20));
      expect(s.currentStroke, isNull);
    });

    test('endStroke with 2+ points saves stroke and clears currentStroke', () {
      final s = TacticsState();
      s.startStroke(const Offset(10, 20));
      s.addPoint(const Offset(30, 40));
      s.endStroke();
      expect(s.strokes.length, 1);
      expect(s.currentStroke, isNull);
    });

    test('endStroke with 1 point does not save', () {
      final s = TacticsState();
      s.startStroke(const Offset(10, 20));
      s.endStroke();
      expect(s.strokes, isEmpty);
      expect(s.currentStroke, isNull);
    });

    test('endStroke no-op without currentStroke', () {
      final s = TacticsState();
      s.endStroke();
      expect(s.strokes, isEmpty);
    });

    test('clearStrokes removes all', () {
      final s = TacticsState();
      s.startStroke(const Offset(0, 0));
      s.addPoint(const Offset(1, 1));
      s.endStroke();
      s.clearStrokes();
      expect(s.strokes, isEmpty);
    });

    test('clearStrokes no-op when empty does not add to undo', () {
      final s = TacticsState();
      s.clearStrokes();
      expect(s.canUndo, false);
    });
  });

  group('TacticsState.clearAll', () {
    test('clears players and strokes', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.startStroke(const Offset(0, 0));
      s.addPoint(const Offset(1, 1));
      s.endStroke();
      s.clearAll();
      expect(s.players, isEmpty);
      expect(s.strokes, isEmpty);
    });

    test('no-op when already empty does not add to undo', () {
      final s = TacticsState();
      s.clearAll();
      expect(s.canUndo, false);
    });

    test('clears selectedPlayerId', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.selectPlayer('p1');
      s.clearAll();
      expect(s.selectedPlayerId, isNull);
    });

    test('stops animation', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.startAnimation();
      s.clearAll();
      expect(s.isAnimating, false);
    });
  });

  group('TacticsState undo/redo', () {
    test('undo after addPlayer restores empty state', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.undo();
      expect(s.players, isEmpty);
      expect(s.canUndo, false);
    });

    test('redo after undo restores player', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.undo();
      s.redo();
      expect(s.players.length, 1);
    });

    test('new action clears redo stack', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.undo();
      s.addPlayer(_player('p2'));
      expect(s.canRedo, false);
    });

    test('undo no-op when stack empty', () {
      final s = TacticsState();
      s.undo();
      expect(s.players, isEmpty);
    });

    test('redo no-op when stack empty', () {
      final s = TacticsState();
      s.redo();
      expect(s.canRedo, false);
    });

    test('undo stack capped at 50', () {
      final s = TacticsState();
      for (int i = 0; i < 55; i++) {
        s.addPlayer(_player('p$i'));
      }
      int count = 0;
      while (s.canUndo && count <= 60) {
        s.undo();
        count++;
      }
      expect(count, lessThanOrEqualTo(50));
    });
  });

  group('TacticsState.applyFormation', () {
    test('creates correct number of players', () {
      final s = TacticsState();
      s.setCanvasSize(const Size(400, 700));
      const f = SportFormation(
        nameKey: 'test',
        homePositions: [Offset(0.5, 0.75), Offset(0.3, 0.6)],
        awayPositions: [Offset(0.5, 0.25)],
        addBall: false,
      );
      s.applyFormation(f);
      expect(s.players.length, 3);
    });

    test('home/away team assignment', () {
      final s = TacticsState();
      s.setCanvasSize(const Size(400, 700));
      const f = SportFormation(
        nameKey: 'test',
        homePositions: [Offset(0.5, 0.75)],
        awayPositions: [Offset(0.5, 0.25)],
        addBall: false,
      );
      s.applyFormation(f);
      expect(s.players[0].team, PlayerTeam.home);
      expect(s.players[1].team, PlayerTeam.away);
    });

    test('positions scaled to canvas size', () {
      final s = TacticsState();
      s.setCanvasSize(const Size(400, 700));
      const f = SportFormation(
        nameKey: 'test',
        homePositions: [Offset(0.5, 0.75)],
        awayPositions: [],
        addBall: false,
      );
      s.applyFormation(f);
      expect(s.players[0].position.dx, closeTo(200.0, 0.01));
      expect(s.players[0].position.dy, closeTo(525.0, 0.01));
    });

    test('adds ball when addBall is true', () {
      final s = TacticsState(sportType: SportType.badminton);
      s.setCanvasSize(const Size(400, 700));
      const f = SportFormation(
        nameKey: 'test',
        homePositions: [Offset(0.5, 0.75)],
        awayPositions: [Offset(0.5, 0.25)],
        addBall: true,
      );
      s.applyFormation(f);
      final balls = s.players.where((p) => p.isBall).toList();
      expect(balls.length, 1);
      expect(balls.first.position, const Offset(200, 350));
    });

    test('clears existing players', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.addPlayer(_player('p2'));
      s.setCanvasSize(const Size(400, 700));
      const f = SportFormation(
        nameKey: 'test',
        homePositions: [Offset(0.5, 0.75)],
        awayPositions: [],
        addBall: false,
      );
      s.applyFormation(f);
      expect(s.players.length, 1);
    });

    test('labels home players 1, 2, ...', () {
      final s = TacticsState();
      s.setCanvasSize(const Size(400, 700));
      const f = SportFormation(
        nameKey: 'test',
        homePositions: [Offset(0.3, 0.6), Offset(0.7, 0.8)],
        awayPositions: [],
        addBall: false,
      );
      s.applyFormation(f);
      expect(s.players[0].label, '1');
      expect(s.players[1].label, '2');
    });

    test('enables undo', () {
      final s = TacticsState();
      s.setCanvasSize(const Size(400, 700));
      const f = SportFormation(nameKey: 'test', homePositions: [], awayPositions: [], addBall: false);
      s.applyFormation(f);
      expect(s.canUndo, true);
    });
  });

  group('TacticsState.setSportType', () {
    test('changes sport type', () {
      final s = TacticsState();
      s.setSportType(SportType.soccer);
      expect(s.sportType, SportType.soccer);
    });

    test('clears players, strokes, selection, stacks, animation', () {
      final s = TacticsState();
      s.addPlayer(_player('p1'));
      s.selectPlayer('p1');
      s.startAnimation();
      s.setSportType(SportType.tennis);
      expect(s.players, isEmpty);
      expect(s.selectedPlayerId, isNull);
      expect(s.isAnimating, false);
      expect(s.canUndo, false);
      expect(s.canRedo, false);
    });
  });

  group('TacticsState animation', () {
    test('startAnimation sets isAnimating true', () {
      final s = TacticsState();
      s.startAnimation();
      expect(s.isAnimating, true);
    });

    test('startAnimation is idempotent', () {
      final s = TacticsState();
      s.startAnimation();
      s.startAnimation();
      expect(s.isAnimating, true);
    });

    test('startAnimation clears animatedPositions', () {
      final s = TacticsState();
      s.updateAnimatedPositions({'p1': const Offset(10, 20)});
      s.startAnimation();
      expect(s.animatedPositions, isEmpty);
    });

    test('finishAnimation sets isAnimating false', () {
      final s = TacticsState();
      s.startAnimation();
      s.finishAnimation();
      expect(s.isAnimating, false);
    });

    test('stopAnimation sets isAnimating false', () {
      final s = TacticsState();
      s.startAnimation();
      s.stopAnimation();
      expect(s.isAnimating, false);
    });

    test('updateAnimatedPositions stores positions', () {
      final s = TacticsState();
      s.updateAnimatedPositions({'p1': const Offset(10, 20)});
      expect(s.animatedPositions['p1'], const Offset(10, 20));
    });

    test('clearAnimatedPositions empties the map', () {
      final s = TacticsState();
      s.updateAnimatedPositions({'p1': const Offset(10, 20)});
      s.clearAnimatedPositions();
      expect(s.animatedPositions, isEmpty);
    });
  });

  group('TacticsState.setTargetStep', () {
    test('sets targetStep', () {
      final s = TacticsState();
      s.setTargetStep(3);
      expect(s.targetStep, 3);
    });
  });

  group('TacticsState.setCanvasSize', () {
    test('affects applyFormation position scaling', () {
      final s = TacticsState();
      s.setCanvasSize(const Size(800, 1200));
      const f = SportFormation(
        nameKey: 'test',
        homePositions: [Offset(1.0, 1.0)],
        awayPositions: [],
        addBall: false,
      );
      s.applyFormation(f);
      expect(s.players[0].position.dx, closeTo(800, 0.01));
      expect(s.players[0].position.dy, closeTo(1200, 0.01));
    });
  });
}
