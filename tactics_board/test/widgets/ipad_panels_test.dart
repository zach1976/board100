import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/ui/primitives.dart';

import 'ipad_harness.dart';

/// Board panels on a tablet open as popovers by their buttons; a phone
/// keeps its bottom sheets. The Add popover shows every object tile whole.
/// A right-click on a player opens its menu. The tools keep their words on
/// an iPad mini and in Split View (iPad audit 2026-10-11 #5, #8, #13).
void main() {
  testWidgets('popovers, context menu, toolbar labels', (tester) async {
    final state = await pumpBoard(tester, kPro);

    // Add: a popover anchored over its button, every tile inside it. By
    // its icon: on an upright tablet the tool capsule shares its row with
    // the playback capsule, and in the test font (every glyph an em wide)
    // the four tools' words do not fit beside it.
    final addBtn = tester.getRect(find.byIcon(Icons.add_rounded).first);
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await settle(tester);
    expect(find.byType(PopoverScope), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    final pop = tester.getRect(find.byType(PopoverScope));
    expect(pop.bottom, lessThanOrEqualTo(addBtn.top),
        reason: 'opens above the Add button');
    final tri = tester.getRect(find.text('Triangle'));
    expect(pop.contains(tri.topLeft) && pop.contains(tri.bottomRight), isTrue,
        reason: 'Triangle $tri is cut by the popover $pop');
    // A tap outside closes it.
    await tester.tapAt(const Offset(20, 300));
    await settle(tester);
    expect(find.byType(PopoverScope), findsNothing);

    // Right-click a player: Edit / Duplicate / Add Run / Remove.
    final p = state.players
        .firstWhere((x) => x.id != TacticsState.kDrillNoteId && !x.isBall);
    final before = state.players.length;
    await tester.tapAt(onScreen(tester, p.position),
        buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
    await settle(tester);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Add Run'), findsOneWidget);
    await tester.tap(find.text('Duplicate'));
    await settle(tester);
    expect(state.players.length, before + 1);
    state.selectPlayer(null);
    await settle(tester);

    // An iPad mini keeps the four tools' words. (Half Split View, 678pt,
    // is measured against the real words: ~354pt of English in a 369pt
    // bar. The test font sets every glyph a full em wide, so it cannot be
    // asked here.)
    for (final size in const [Size(744, 1133)]) {
      tester.view.physicalSize = size * 2;
      await settle(tester);
      expect(find.text('Move'), findsOneWidget, reason: 'at $size');
      expect(find.text('Draw'), findsOneWidget, reason: 'at $size');
    }

    // A phone keeps the bottom sheet.
    tester.view.physicalSize = kPhone * 2;
    await settle(tester);
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await settle(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(PopoverScope), findsNothing);
  });
}
