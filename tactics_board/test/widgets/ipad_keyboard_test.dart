import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/ui/primitives.dart';

import 'ipad_harness.dart';

/// A hardware keyboard drives the board (iPad audit 2026-10-11 #9):
/// Space play/stop, ←/→ step, ⌘Z / ⇧⌘Z, Delete/⌫, Esc, ⌘S — and none of
/// them fires while a text field has the focus.
void main() {
  testWidgets('board keyboard shortcuts', (tester) async {
    final state = await pumpBoard(tester, kPro);

    Future<void> chord(LogicalKeyboardKey key,
        {bool meta = false, bool shift = false}) async {
      if (meta) await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(key);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      if (meta) await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
    }

    Future<void> untilStill() async {
      for (var i = 0; i < 60 && state.isAnimating; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await settle(tester);
    }

    // Space plays, Space again stops.
    expect(state.isAnimating, isFalse);
    await chord(LogicalKeyboardKey.space);
    expect(state.isAnimating, isTrue, reason: 'Space should play');
    await chord(LogicalKeyboardKey.space);
    expect(state.isAnimating, isFalse, reason: 'Space again should stop');
    state.clearAnimatedPositions();
    await settle(tester);

    // → and ← step one beat.
    expect(state.atStep, 0);
    await chord(LogicalKeyboardKey.arrowRight);
    await untilStill();
    expect(state.atStep, 1, reason: '→ steps forward one beat');
    await chord(LogicalKeyboardKey.arrowLeft);
    await untilStill();
    expect(state.atStep, 0, reason: '← steps back one beat');

    // Esc deselects; ⌫ deletes; ⌘Z undoes; ⇧⌘Z redoes.
    final victim = state.players
        .firstWhere((p) => p.id != TacticsState.kDrillNoteId && !p.isBall);
    final before = state.players.length;
    state.selectPlayer(victim.id);
    await tester.pump();
    await chord(LogicalKeyboardKey.escape);
    expect(state.selectedPlayerId, isNull, reason: 'Esc deselects');

    state.selectPlayer(victim.id);
    await tester.pump();
    await chord(LogicalKeyboardKey.backspace);
    expect(state.players.length, before - 1, reason: 'Backspace deletes');
    await chord(LogicalKeyboardKey.keyZ, meta: true);
    expect(state.players.length, before, reason: 'Cmd+Z undoes');
    await chord(LogicalKeyboardKey.keyZ, meta: true, shift: true);
    expect(state.players.length, before - 1, reason: 'Shift+Cmd+Z redoes');
    state.selectPlayer(state.players
        .firstWhere((p) => p.id != TacticsState.kDrillNoteId)
        .id);
    await tester.pump();
    await chord(LogicalKeyboardKey.delete);
    expect(state.players.length, before - 2, reason: 'Delete deletes');

    // Esc leaves Draw.
    state.setDrawingMode(true);
    await tester.pump();
    await chord(LogicalKeyboardKey.escape);
    expect(state.isDrawingMode, isFalse, reason: 'Esc leaves Draw');
    await settle(tester);

    // Nothing fires while a text field is being typed in.
    final page = tester.element(find.byType(TacticsBoardHomePage));
    final dialog = showDialog<void>(
      context: page,
      builder: (_) => const Dialog(child: TextField(autofocus: true)),
    );
    await settle(tester);
    final count = state.players.length;
    state.selectPlayer(state.players.first.id);
    await tester.pump();
    await chord(LogicalKeyboardKey.space);
    await chord(LogicalKeyboardKey.backspace);
    await chord(LogicalKeyboardKey.arrowRight);
    expect(state.isAnimating, isFalse, reason: 'Space typed, not played');
    expect(state.players.length, count, reason: 'Backspace typed');
    expect(state.atStep, 0);
    Navigator.of(page).pop();
    await dialog;
    await settle(tester);
    state.selectPlayer(null);
    await tester.pump();

    // Back on the board the keys work again, and ⌘S on an unnamed board
    // opens the Save panel (a popover on a tablet).
    expect(state.currentTacticName, isNull);
    await chord(LogicalKeyboardKey.keyS, meta: true);
    await settle(tester);
    expect(find.byType(PopoverScope), findsOneWidget,
        reason: 'Cmd+S opens Save');
    // Esc closes the popover.
    await chord(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.byType(PopoverScope), findsNothing, reason: 'Esc closes it');
  });
}
