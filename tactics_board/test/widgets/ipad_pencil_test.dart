import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

import 'ipad_harness.dart';

/// Apple Pencil on the board (iPad audit 2026-10-11 #10), with synthetic
/// stylus pointer events — the simulator cannot make them. The Pencil draws
/// in Move mode as well as Draw; a finger moves players; a palm resting
/// while the Pencil draws neither draws nor drags; a phone is unchanged.
void main() {
  testWidgets('Pencil draws, finger moves, palm is ignored', (tester) async {
    final state = await pumpBoard(tester, kPro);

    Future<void> stroke(Offset from, Offset step,
        {PointerDeviceKind kind = PointerDeviceKind.stylus}) async {
      final g = await tester.startGesture(from, kind: kind);
      for (var i = 0; i < 8; i++) {
        await g.moveBy(step);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pump();
    }

    // Move mode: the Pencil draws, a finger on empty board does not.
    expect(state.isDrawingMode, isFalse);
    var strokes = state.strokes.length;
    final empty = onScreen(tester, emptySpot(state));
    await stroke(empty, const Offset(12, 6));
    expect(state.strokes.length, strokes + 1,
        reason: 'a Pencil line on a Move-mode board');
    await stroke(empty + const Offset(0, 60), const Offset(12, 6),
        kind: PointerDeviceKind.touch);
    expect(state.strokes.length, strokes + 1,
        reason: 'a finger on empty board in Move mode draws nothing');

    // A finger moves a player; the Pencil over him draws and leaves him.
    final p = state.players
        .firstWhere((x) => x.id != TacticsState.kDrillNoteId && !x.isBall);
    final start = p.position;
    await tester.timedDragFrom(onScreen(tester, start), const Offset(80, 0),
        const Duration(milliseconds: 400));
    await settle(tester);
    final moved = state.players.firstWhere((x) => x.id == p.id).position;
    expect((moved - start).distance, greaterThan(20),
        reason: 'finger drag moves the player');
    strokes = state.strokes.length;
    await stroke(onScreen(tester, moved), const Offset(10, 10));
    expect(
        (state.players.firstWhere((x) => x.id == p.id).position - moved)
            .distance,
        lessThan(1),
        reason: 'the Pencil does not drag a player');
    expect(state.strokes.length, strokes + 1);

    // Draw mode, palm rejection: a touch while the Pencil is down makes
    // nothing; the Pencil's line is the only one.
    state.setDrawingMode(true);
    await tester.pump();
    strokes = state.strokes.length;
    final from = onScreen(tester, emptySpot(state));
    final pen = await tester.startGesture(from, kind: PointerDeviceKind.stylus);
    await pen.moveBy(const Offset(10, 4));
    await tester.pump(const Duration(milliseconds: 16));
    final palm = await tester.startGesture(from + const Offset(-200, 150),
        kind: PointerDeviceKind.touch);
    for (var i = 0; i < 8; i++) {
      await pen.moveBy(const Offset(10, 4));
      await palm.moveBy(const Offset(-6, 9));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await palm.up();
    await pen.up();
    await tester.pump();
    expect(state.strokes.length, strokes + 1,
        reason: "one line, the Pencil's; nothing from the palm");
    expect(pencilPointer, isNull);

    // A palm that lands first and starts a line is dropped when the
    // Pencil comes down.
    strokes = state.strokes.length;
    final palm2 = await tester.startGesture(from + const Offset(-150, 120),
        kind: PointerDeviceKind.touch);
    for (var i = 0; i < 4; i++) {
      await palm2.moveBy(const Offset(-8, 8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final pen2 =
        await tester.startGesture(from, kind: PointerDeviceKind.stylus);
    for (var i = 0; i < 8; i++) {
      await pen2.moveBy(const Offset(10, -4));
      await palm2.moveBy(const Offset(-4, 6));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await pen2.up();
    await palm2.up();
    await tester.pump();
    expect(state.strokes.length, strokes + 1,
        reason: 'the palm\'s early line is cancelled, the Pencil\'s kept');

    // A finger still draws in Draw mode when no Pencil is on the glass.
    strokes = state.strokes.length;
    await stroke(from + const Offset(0, 80), const Offset(10, 0),
        kind: PointerDeviceKind.touch);
    expect(state.strokes.length, strokes + 1);
    state.setDrawingMode(false);
    await settle(tester);

    // A phone is unchanged: a stylus in Move mode draws nothing.
    tester.view.physicalSize = kPhone * 2;
    await settle(tester);
    strokes = state.strokes.length;
    await stroke(onScreen(tester, emptySpot(state)), const Offset(6, 3));
    expect(state.strokes.length, strokes);
  });
}
