import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

import 'overflow_test.dart' show kLocales;

/// What a tap on a text element does, and where it counts.
///
/// Three things that each went wrong once:
///  - a chip turned off square answered only in the middle, because the
///    gesture detector sat outside the Transform and kept the unturned
///    rectangle — so the far end of the words is what this taps;
///  - the selection has to land on the first tap, at once, not after the
///    double-tap window; and the second tap opens the words;
///  - a request to edit that was left behind popped the dialog open on the
///    next selection, so moving the selection clears it.
///
/// One test, one pumpWidget: only the first EasyLocalization in a file
/// initialises.
void main() {
  testWidgets('tap selects at once, a second tap edits, any angle',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(
        {'board_hint_seen': true, 'intro_seen': true, 'remove_ads_pro': true});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 730 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState(sportType: SportType.volleyball);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: ChangeNotifierProvider<TacticsState>.value(
              value: state,
              child: const TacticsBoardHomePage(),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final card = tester.getRect(find.byType(TacticsCanvas).first);
    state.setCanvasSizeSilent(card.size);

    PlayerIcon text(String id, Offset at, double turn) => PlayerIcon(
          id: id,
          label: 'far post',
          team: PlayerTeam.neutral,
          markerShape: MarkerShape.text,
          position: at,
          rotation: turn,
        );
    const turned = Offset(200, 300);
    // Up the board, clear of the turned chip and of the edit bar that
    // opens across the foot of it.
    const square = Offset(200, 150);
    state.addPlayer(text('t45', turned, math.pi / 4));
    state.addPlayer(text('t0', square, 0));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // 50pt out along the turned chip's own width: well past the unturned
    // box's half-height of ~12, well inside the painted chip's half-width.
    final farEnd = card.topLeft +
        turned +
        Offset(math.cos(math.pi / 4), math.sin(math.pi / 4)) * 50;
    await tester.tapAt(farEnd);
    await tester.pump();
    expect(state.selectedPlayerId, 't45',
        reason: 'the words answer a tap at their far end, turned 45°');
    expect(state.labelEditRequest, isNull,
        reason: 'one tap selects and nothing more');

    // The second tap, inside the window.
    await tester.tapAt(farEnd);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('edit_marker'.tr()), findsOneWidget,
        reason: 'a second tap opens the words to be rewritten');
    await tester.tap(find.text('cancel'.tr()));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // A drag moves the words the way the finger went, however they are
    // turned: the detector is inside the turn, so the delta it reports is
    // in the chip's frame and has to be put back into the board's.
    final before = state.players.firstWhere((p) => p.id == 't45').position;
    // Several move events, not one jump: a scale recogniser has to see the
    // pointer travel, and one teleport past the slop is not a drag to it.
    await tester.timedDragFrom(card.topLeft + turned, const Offset(40, 0),
        const Duration(milliseconds: 300));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    final after = state.players.firstWhere((p) => p.id == 't45').position;
    // Direction, not distance: the recogniser only starts counting once the
    // pointer is past the touch slop, so a 40pt drag lands about 20pt of
    // movement. Before the delta was turned back, those 20pt went 14 right
    // and 14 UP — along the chip's tilt, not along the finger.
    expect(after.dx - before.dx, greaterThan(15),
        reason: 'a drag to the right goes right');
    expect((after.dy - before.dy).abs(), lessThan(3),
        reason: 'and not a step along the chip\'s own tilt');

    // Moving the selection to another element leaves no request behind.
    state.labelEditRequest = 't45';
    await tester.tapAt(card.topLeft + square);
    await tester.pump();
    expect(state.selectedPlayerId, 't0');
    expect(state.labelEditRequest, isNull,
        reason: 'a stale request would pop the dialog on the next select');
  });
}
