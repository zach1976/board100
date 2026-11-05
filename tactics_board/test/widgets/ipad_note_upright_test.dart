import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

import 'ipad_harness.dart';

/// Text reads level in landscape (iPad audit 2026-10-11 #3). The board is
/// drawn a quarter turn round sideways; a text element now counter-turns
/// with it the way the figures do, so the step note is placed at rotation
/// 0, and an unmoved note goes back under the court when the device turns.
void main() {
  testWidgets('the step note stays upright and under the court',
      (tester) async {
    final state = await pumpBoard(tester, const Size(1376, 1032));
    final note =
        state.players.firstWhere((p) => p.id == TacticsState.kDrillNoteId);
    expect(note.rotation, 0, reason: 'no -90° baked into the note');
    expect(state.notePlacedSideways, isTrue);
    // On screen the chip is wider than it is tall: it reads level.
    // Every copy on the screen (the board also lays out a copy to capture
    // for an external display).
    void level(String text) {
      var seen = 0;
      for (final e in find.text(text).evaluate()) {
        final r = tester.getRect(find.byWidget(e.widget));
        final screen = Offset.zero &
            (tester.view.physicalSize / tester.view.devicePixelRatio);
        if (!screen.contains(r.center)) continue;
        seen++;
        expect(r.width, greaterThan(r.height), reason: '"$text" at $r');
      }
      expect(seen, greaterThanOrEqualTo(1), reason: '"$text" on the screen');
    }

    level(note.label);

    // Turned upright: placed again, at the foot of the portrait board.
    tester.view.physicalSize = kPro * 2;
    await settle(tester);
    expect(state.notePlacedSideways, isFalse);
    final placed =
        state.players.firstWhere((p) => p.id == TacticsState.kDrillNoteId);
    final court = state.sportType.fieldRect(state.canvasSize);
    expect(placed.position.dy, greaterThan(court.center.dy));
    level(placed.label);

    // Moved by the coach, it stays where it was put through a turn.
    state.movePlayerEnd(placed.id, placed.position - const Offset(0, 40));
    expect(state.notePlacedSideways, isNull);
    tester.view.physicalSize = const Size(1376, 1032) * 2;
    await settle(tester);
    expect(state.notePlacedSideways, isNull);

    // A user's own text element reads level sideways too.
    final at = Offset(state.canvasSize.width / 2, state.canvasSize.height / 2);
    state.addPlayer(state.players
        .firstWhere((p) => p.id == TacticsState.kDrillNoteId)
        .copyWith(id: 't1', label: 'Press high', position: at));
    await settle(tester);
    level('Press high');
  });
}
