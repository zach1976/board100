import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// Copying a player, whole, and putting them on another page.
///
/// The point of the feature is the run: a coach building the next beat of a
/// move should not have to redraw the path they already drew.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TacticsState boardWith(List<PlayerIcon> ps) {
    final s = TacticsState();
    s.loadFromJson({
      'sportType': SportType.soccer.index,
      'players': [for (final p in ps) p.toJson()],
      'strokes': <dynamic>[],
    });
    s.setCanvasSizeSilent(const Size(400, 700));
    return s;
  }

  PlayerIcon winger() => PlayerIcon(
        id: 'a',
        label: '7',
        team: PlayerTeam.home,
        position: const Offset(100, 500),
        scale: 1.3,
        rotation: 0.7853981633974483,
        gender: PlayerGender.female,
        moves: const [Offset(100, 300), Offset(180, 200)],
        movePhases: const [0, 1],
      ).copyWith(facingLocked: true);

  test('the copy carries the kit, the turn and the whole run', () {
    final state = boardWith([winger()]);
    state.copyPlayer('a');
    final id = state.pastePlayer();
    expect(id, isNotNull);

    final pasted = state.players.firstWhere((p) => p.id == id);
    expect(pasted.label, '7');
    expect(pasted.team, PlayerTeam.home);
    expect(pasted.scale, 1.3);
    expect(pasted.gender, PlayerGender.female);
    expect(pasted.rotation, closeTo(0.7853981633974483, 1e-9));
    expect(pasted.facingLocked, isTrue);
    expect(pasted.moves.length, 2);
    expect(pasted.movePhases, [0, 1]);
  });

  test('on an empty page it lands exactly where it was taken from', () {
    final from = boardWith([winger()]);
    from.copyPlayer('a');
    // The same state, a page later: a fresh board, nothing on it.
    from.loadFromJson({
      'sportType': SportType.soccer.index,
      'players': <dynamic>[],
      'strokes': <dynamic>[],
    });
    from.setCanvasSizeSilent(const Size(400, 700));
    final id = from.pastePlayer();
    final pasted = from.players.firstWhere((p) => p.id == id);
    expect(pasted.position, const Offset(100, 500),
        reason: 'the next beat of a move starts where the last one left off');
    expect(pasted.moves.first, const Offset(100, 300));
  });

  test('pasting onto the one it came from steps aside, run and all', () {
    final state = boardWith([winger()]);
    state.copyPlayer('a');
    final id = state.pastePlayer();
    final pasted = state.players.firstWhere((p) => p.id == id);
    expect(pasted.position, isNot(const Offset(100, 500)),
        reason: 'two players on one spot read as one');
    // The run moves with them: a path left behind at the old coordinates
    // would start somewhere the player is not.
    final shift = pasted.position - const Offset(100, 500);
    expect(pasted.moves.first, const Offset(100, 300) + shift);
  });

  test('a copied ball arrives loose', () {
    final ball = PlayerIcon(
      id: 'b',
      label: '',
      team: PlayerTeam.neutral,
      sportType: SportType.soccer,
      position: const Offset(120, 480),
      attachedTo: 'a',
    );
    final state = boardWith([winger(), ball]);
    state.copyPlayer('b');
    state.loadFromJson({
      'sportType': SportType.soccer.index,
      'players': <dynamic>[],
      'strokes': <dynamic>[],
    });
    state.setCanvasSizeSilent(const Size(400, 700));
    final id = state.pastePlayer();
    final pasted = state.players.firstWhere((p) => p.id == id);
    expect(pasted.attachedTo, isNull,
        reason: 'the player carrying it is on the page it came from');
  });

  test('editing the original afterwards does not rewrite the copy', () {
    final state = boardWith([winger()]);
    state.copyPlayer('a');
    state.addPlayerMove('a', const Offset(300, 100));
    final id = state.pastePlayer();
    final pasted = state.players.firstWhere((p) => p.id == id);
    expect(pasted.moves.length, 2);
  });
}
