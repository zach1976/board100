import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/player_photo.dart';
import 'package:tactics_board/models/sport_formation.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// A squad member: a face plus the identity that belongs to the person.
PlayerPhoto member(String id, {String? name, String? number, String? role, bool photo = true}) =>
    PlayerPhoto(
      id: id,
      filename: photo ? '$id.jpg' : '',
      createdAtMs: 0,
      groupId: 'squad',
      playerName: name,
      jerseyNumber: number,
      role: role,
    );

/// A 4-4-2 shaped test formation: 11 slots per side, goalkeeper first.
SportFormation formation442() {
  const home = [
    Offset(0.5, 0.95),
    Offset(0.2, 0.78), Offset(0.4, 0.80), Offset(0.6, 0.80), Offset(0.8, 0.78),
    Offset(0.2, 0.55), Offset(0.4, 0.57), Offset(0.6, 0.57), Offset(0.8, 0.55),
    Offset(0.4, 0.33), Offset(0.6, 0.33),
  ];
  final away = [for (final p in home) Offset(1 - p.dx, 1 - p.dy)];
  return SportFormation(
    nameKey: 'formation_442',
    homePositions: home,
    awayPositions: away,
  );
}

void main() {
  // TacticsState registers an external-display method channel on construction.
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  late TacticsState state;

  setUp(() {
    state = TacticsState(sportType: SportType.soccer);
    state.setCanvasSizeSilent(const Size(400, 800));
  });

  group('addSquadFromFormation', () {
    test('fills every slot and reports how many members were placed', () {
      final squad = [for (int i = 1; i <= 11; i++) member('p$i', number: '$i')];

      final placed = state.addSquadFromFormation(formation442(), PlayerTeam.home, squad);

      expect(placed, 11);
      expect(state.players.length, 11);
      expect(state.players.every((p) => p.team == PlayerTeam.home), isTrue);
    });

    test('a member with a position code takes that slot, not the next free one', () {
      // The keeper is last in the list; role matching must still put them in goal.
      final squad = [
        member('out1', number: '9', role: 'ST'),
        member('out2', number: '4', role: 'CB'),
        member('keeper', number: '1', role: 'GK'),
      ];

      state.addSquadFromFormation(formation442(), PlayerTeam.home, squad);

      final keeper = state.players.firstWhere((p) => p.label == '1');
      expect(keeper.role, 'GK');
      // Slot 0 of the home side is the goalkeeper slot — deepest on the pitch.
      final deepest = state.players.reduce((a, b) => a.position.dy > b.position.dy ? a : b);
      expect(deepest.label, '1', reason: 'the keeper belongs at the back');
    });

    test('shirt number becomes the board label, name is the fallback', () {
      final squad = [
        member('a', name: 'Rodriguez', number: '10'),
        member('b', name: 'Wang'),
      ];

      state.addSquadFromFormation(formation442(), PlayerTeam.home, squad);

      expect(state.players.any((p) => p.label == '10'), isTrue);
      expect(state.players.any((p) => p.label == 'Wang'), isTrue);
    });

    test('members carry their photo onto the board; a photoless member does not', () {
      final squad = [
        member('withPhoto', number: '7'),
        member('noPhoto', number: '8', photo: false),
      ];

      state.addSquadFromFormation(formation442(), PlayerTeam.home, squad);

      expect(state.players.firstWhere((p) => p.label == '7').photoId, 'withPhoto');
      expect(state.players.firstWhere((p) => p.label == '8').photoId, isNull);
    });

    test('a short squad still fills the shape, the extras are plain numbers', () {
      final squad = [member('a', number: '5'), member('b', number: '6')];

      final placed = state.addSquadFromFormation(formation442(), PlayerTeam.home, squad);

      expect(placed, 2);
      expect(state.players.length, 11, reason: 'the formation shape is kept');
      expect(state.players.where((p) => p.photoId != null).length, 2);
    });

    test('members beyond the shape are the bench and are left off', () {
      final squad = [for (int i = 1; i <= 14; i++) member('p$i', number: '$i')];

      final placed = state.addSquadFromFormation(formation442(), PlayerTeam.home, squad);

      expect(placed, 11);
      expect(state.players.length, 11);
    });

    test('applying a squad replaces that team, and leaves the other alone', () {
      state.addSquadFromFormation(formation442(), PlayerTeam.away,
          [for (int i = 1; i <= 11; i++) member('a$i', number: '$i')]);
      state.addSquadFromFormation(formation442(), PlayerTeam.home,
          [for (int i = 1; i <= 11; i++) member('h$i', number: '$i')]);
      // Same squad again: this is "my XI", not "add eleven more".
      state.addSquadFromFormation(formation442(), PlayerTeam.home,
          [for (int i = 1; i <= 11; i++) member('h$i', number: '$i')]);

      expect(state.players.where((p) => p.team == PlayerTeam.home).length, 11);
      expect(state.players.where((p) => p.team == PlayerTeam.away).length, 11);
    });

    test('an unassigned member inherits its slot role, so it sticks next time', () {
      final squad = [member('a', number: '3')];

      state.addSquadFromFormation(formation442(), PlayerTeam.home, squad);

      expect(state.players.first.role, isNotNull);
    });
  });

  group('PlayerPhoto as a squad member', () {
    test('board label prefers the shirt number', () {
      expect(member('x', name: 'Wang', number: '7').boardLabel, '7');
      expect(member('x', name: 'Wang').boardLabel, 'Wang');
      expect(member('x').boardLabel, '');
    });

    test('identity survives a JSON round trip', () {
      final m = member('x', name: 'Wang', number: '07', role: 'CM');
      final back = PlayerPhoto.fromJson(m.toJson());
      expect(back.playerName, 'Wang');
      expect(back.jerseyNumber, '07', reason: '07 and 7 are different shirts');
      expect(back.role, 'CM');
    });

    test('a member read from an older index has no identity and still loads', () {
      final legacy = {
        'id': 'x',
        'filename': 'x.jpg',
        'createdAtMs': 1,
        'groupId': 'g',
        'kind': 'face',
      };
      final back = PlayerPhoto.fromJson(legacy);
      expect(back.hasIdentity, isFalse);
      expect(back.boardLabel, '');
    });
  });
}
