import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/models/volleyball_rotation.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// A rotation board: placing a side, rotating it, the libero, the overlap
/// check on the board, and what the page file keeps.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canvas = Size(402, 700);

  TacticsState board() {
    final s = TacticsState(sportType: SportType.volleyball);
    s.setCanvasSizeSilent(canvas);
    return s;
  }

  PlayerIcon byRole(TacticsState s, String role) =>
      s.players.firstWhere((p) => p.role == role);

  test('places six legal players and a libero; the middle waits outside', () {
    final s = board();
    s.applyRotation(const RotationSetup());
    expect(s.players, hasLength(7));
    expect(s.players.every((p) => p.team == PlayerTeam.home), isTrue);
    expect(s.rotationFaults(), isEmpty);
    // The libero is in for MB2 (zone 6 in rotation 1) ...
    final court = SportType.volleyball.fieldRect(canvas);
    final l = byRole(s, VolleyballRotation.liberoRole);
    expect(court.contains(l.position), isTrue);
    expect(l.customColor, TacticsState.kLiberoColor);
    // ... and MB2 stands beside the court, off it.
    expect(byRole(s, 'MB2').position.dx, greaterThan(court.right));
    // Everyone on the near half.
    for (final role in ['S', 'OH1', 'MB1', 'OPP', 'OH2', 'L']) {
      expect(byRole(s, role).position.dy, greaterThan(court.center.dy),
          reason: role);
    }
  });

  test('serving: the server has his feet behind the end line', () {
    final s = board();
    s.applyRotation(const RotationSetup(phase: RotationPhase.serve));
    final court = SportType.volleyball.fieldRect(canvas);
    final server = byRole(s, 'S'); // zone 1 in rotation 1
    expect(server.position.dy + 26, greaterThan(court.bottom));
    expect(server.position.dy + 26, lessThanOrEqualTo(canvas.height));
    expect(s.rotationFaults(), isEmpty);
  });

  test('a player dragged into an overlap is a fault; the check can be off', () {
    final s = board();
    s.applyRotation(const RotationSetup(libero: false));
    final oh2 = byRole(s, 'OH2'); // zone 5
    final opp = byRole(s, 'OPP'); // zone 4, in front of him
    s.movePlayer(oh2.id, Offset(oh2.position.dx, opp.position.dy - 20));
    final faults = s.rotationFaults();
    expect(faults, hasLength(1));
    expect(faults.single.a, opp.id);
    expect(faults.single.b, oh2.id);
    expect(faults.single.fault, const OverlapFault(4, 5, depth: true));

    s.setRotationCheck(false);
    expect(s.rotationFaults(), isEmpty, reason: 'the check is off');
    s.setRotationCheck(true);
    expect(s.rotationFaults(), hasLength(1));
  });

  test('fix positions mends the overlap in one undoable step', () {
    final s = board();
    s.applyRotation(const RotationSetup(libero: false));
    final oh2 = byRole(s, 'OH2'); // zone 5
    final opp = byRole(s, 'OPP'); // zone 4
    final others = {
      for (final p in s.players)
        if (p.id != oh2.id) p.id: p.position,
    };
    s.movePlayer(oh2.id, Offset(oh2.position.dx, opp.position.dy - 20));
    s.movePlayerEnd(oh2.id, Offset(oh2.position.dx, opp.position.dy - 20));
    expect(s.rotationFaults(), hasLength(1));

    expect(s.legalizeRotation(), isTrue);
    expect(s.rotationFaults(), isEmpty);
    expect(s.rotation, isNotNull, reason: 'still a rotation board');
    // Only the two at fault moved; and the one at the net stayed at it.
    final moved = s.players
        .where((p) => others.containsKey(p.id) && others[p.id] != p.position)
        .map((p) => p.role)
        .toList();
    expect(moved, ['OPP']);
    expect(byRole(s, 'OPP').position.dy, lessThan(byRole(s, 'OH2').position.dy));

    s.undo();
    expect(s.rotationFaults(), hasLength(1), reason: 'one step back');
    expect(s.legalizeRotation(), isTrue);
    expect(s.rotationFaults(), isEmpty);
  });

  test('fix positions leaves a legal side, and the server, alone', () {
    final s = board();
    s.applyRotation(const RotationSetup(phase: RotationPhase.serve));
    final server = byRole(s, 'S');
    final oh1 = byRole(s, 'OH1'); // zone 2
    s.movePlayer(server.id, oh1.position - const Offset(60, 30));
    s.movePlayerEnd(server.id, oh1.position - const Offset(60, 30));
    final before = {for (final p in s.players) p.id: p.position};
    expect(s.rotationFaults(), isEmpty);
    expect(s.legalizeRotation(), isFalse);
    expect({for (final p in s.players) p.id: p.position}, before);
  });

  test('the rule set is kept with the board', () {
    final s = board();
    s.applyRotation(const RotationSetup(rules: RotationRules.usav));
    final json = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
    final t = board()..loadFromJson(json);
    expect(t.rotation!.rules, RotationRules.usav);
    // USAV, rotation 3, serving: the libero is the server, behind the line.
    t.applyRotation(t.rotation!
        .copyWith(rotation: 3, phase: RotationPhase.serve));
    final court = SportType.volleyball.fieldRect(canvas);
    final l = byRole(t, VolleyballRotation.liberoRole);
    expect(l.position.dy + 26, greaterThan(court.bottom));
    expect(byRole(t, 'MB1').position.dx, greaterThan(court.right),
        reason: 'the middle he serves for waits beside the court');
    expect(t.rotationFaults(), isEmpty);
  });

  test('the server may stand anywhere; a receiver may not', () {
    final s = board();
    s.applyRotation(const RotationSetup(phase: RotationPhase.serve));
    final server = byRole(s, 'S');
    final oh1 = byRole(s, 'OH1'); // zone 2
    s.movePlayer(server.id, oh1.position - const Offset(60, 30));
    expect(s.rotationFaults(), isEmpty);
    s.applyRotation(s.rotation!.copyWith(phase: RotationPhase.receive));
    s.movePlayer(byRole(s, 'S').id, oh1.position - const Offset(60, 30));
    expect(s.rotationFaults(), isNotEmpty);
  });

  test('rotating on keeps the people and moves them a zone', () {
    final s = board();
    s.applyRotation(const RotationSetup());
    final ids = {for (final p in s.players) p.role: p.id};
    s.rotateBy(1);
    expect(s.rotation!.rotation, 2);
    expect({for (final p in s.players) p.role: p.id}, ids);
    expect(s.rotationFaults(), isEmpty);
    // MB2 went 6 → 5, still in the back row: the libero stays in for him.
    expect(s.rotation!.liberoReplaces, 'MB2');
    s.rotateBy(-2);
    expect(s.rotation!.rotation, 6);
  });

  test('libero off takes the libero away and brings the middle back', () {
    final s = board();
    s.applyRotation(const RotationSetup());
    s.applyRotation(s.rotation!.copyWith(libero: false));
    expect(s.players, hasLength(6));
    expect(s.players.any((p) => p.role == VolleyballRotation.liberoRole),
        isFalse);
    final court = SportType.volleyball.fieldRect(canvas);
    expect(court.contains(byRole(s, 'MB2').position), isTrue);
  });

  test('a 5-1 switched to a 6-2 keeps its setter and opposite', () {
    final s = board();
    s.applyRotation(const RotationSetup(libero: false));
    final setter = byRole(s, 'S').id, opp = byRole(s, 'OPP').id;
    s.applyRotation(s.rotation!.copyWith(system: RotationSystem.sixTwo));
    expect(s.players, hasLength(6));
    expect(byRole(s, 'S1').id, setter);
    expect(byRole(s, 'S2').id, opp);
  });

  test('six drawn freehand are read into zones where they stand', () {
    final s = board();
    s.addTeamFromFormation(
        SportType.volleyball.formations.first, PlayerTeam.home);
    final before = {for (final p in s.players) p.id: p.position};
    s.setRotationCheck(true);
    expect(s.rotation, isNotNull);
    expect({for (final p in s.players) p.id: p.position}, before,
        reason: 'turning the check on moves no one');
    expect(s.rotationFaults(), isEmpty);
  });

  test('the page keeps its rotation; undo brings back the last one', () {
    final s = board();
    s.applyRotation(const RotationSetup(rotation: 3, libero: false));
    final json = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
    expect(json['rotation'], isA<Map>());

    final t = board()..loadFromJson(json);
    expect(t.rotation, const RotationSetup(rotation: 3, libero: false));
    expect(t.rotationFaults(), isEmpty);

    s.rotateBy(1);
    expect(s.rotation!.rotation, 4);
    s.undo();
    expect(s.rotation!.rotation, 3);
  });

  test('a board without the key is no rotation board, and still loads', () {
    final s = board();
    s.applyFormation(SportType.volleyball.formations.first);
    final json = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
    expect(json.containsKey('rotation'), isFalse);
    final t = board()..loadFromJson(json);
    expect(t.rotation, isNull);
    expect(t.players, hasLength(12));
    expect(t.rotationFaults(), isEmpty);
  });

  test('clearing the board ends the rotation', () {
    final s = board();
    s.applyRotation(const RotationSetup());
    s.clearAll();
    expect(s.rotation, isNull);
  });
}
