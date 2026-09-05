import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/main.dart';
import 'package:provider/provider.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

import 'overflow_test.dart' show kLocales, kNarrow;

/// The overflow sweep across the screens a coach actually opens.
///
/// overflow_test.dart builds the drill library sheet directly. This one
/// drives the real app — the board, the overflow menu, the sheets behind it —
/// because most of those widgets are private and the only honest way to
/// render them is to open them the way a user does.
///
/// No OverflowWatch here, deliberately. Swallowing a layout-phase overflow
/// leaves the test binding with no pending exception, and the next async
/// error from the app's services then trips an assertion blamed on this test.
/// Flutter's own handling is both more robust and more useful: an overflow
/// fails the test and names the widget and the line that caused it. The cost
/// is that a run stops at the first one, which is fine — they get fixed one
/// at a time anyway.
///
/// One test, one pumpWidget: only the first EasyLocalization widget in a file
/// renders anything, so every screen and every locale share one app.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('the board and its menus survive every locale on a small phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // See overflow_test.dart: the default test platform picks the Android
    // billing plugin, which opens a connection that fails asynchronously.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // A single-sport build opens straight onto the board; the hub would stop
    // at the sport grid and none of the toolbar would be reachable.
    ConfigConstants.fixedSportType = SportType.badminton;
    addTearDown(() => ConfigConstants.fixedSportType = null);

    await EasyLocalization.ensureInitialized();
    // tester.view, not binding.setSurfaceSize: the latter left MediaQuery
    // reporting the 800x600 test default while the render surface changed
    // underneath it, so every one of these sweeps was silently running at
    // tablet size — and the mismatch produced a 122-pixel "overflow" in the
    // player edit bar that does not exist at any real size.
    tester.view.physicalSize = Size(kNarrow.width * 3, kNarrow.height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    late BuildContext ctx;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(builder: (context) {
          ctx = context;
          return const TacticsBoardApp();
        }),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Every locale gets the board and the overflow menu, which is where the
    // long labels live — "Practice plan" and "Remove ads" ran 65 pixels past
    // the edge here before the menu item learned to wrap.
    final unopened = <String>[];
    // What the sweep actually managed to render, so a run that silently
    // checks nothing cannot pass.
    final opened = <String>[];

    /// Get back to the board. Some menu entries open a sheet, which a tap
    /// outside dismisses; others push a whole page, which it does not — and a
    /// page left on the stack is why the player edit bar was once measured
    /// 14 pixels wide and reported a 122 pixel overflow that was not real.
    Future<void> dismiss() async {
      for (var attempt = 0; attempt < 3; attempt++) {
        final back = find.byType(BackButton);
        final backIcon = find.byIcon(Icons.arrow_back);
        final chevron = find.byIcon(Icons.arrow_back_ios_new);
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first, warnIfMissed: false);
        } else if (backIcon.evaluate().isNotEmpty) {
          await tester.tap(backIcon.first, warnIfMissed: false);
        } else if (chevron.evaluate().isNotEmpty) {
          await tester.tap(chevron.first, warnIfMissed: false);
        } else {
          await tester.tapAt(const Offset(5, 5));
        }
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        if (find.byIcon(Icons.more_horiz).evaluate().isNotEmpty) return;
      }
    }
    for (final locale in kLocales) {
      await ctx.setLocale(locale);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final tag = '${locale.languageCode}-${locale.countryCode}';

      final menu = find.byIcon(Icons.more_horiz);
      if (menu.evaluate().isEmpty) {
        unopened.add('$tag: no overflow menu on the board');
        continue;
      }
      await tester.tap(menu.first, warnIfMissed: false);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      // Nothing to assert here: an overflow while the menu was up has already
      // failed the test by the time we reach this line.

      // Then the sheets behind it. Each is opened from the menu, looked at,
      // and dismissed. The list is the text-heavy ones a coach reaches for;
      // share and login are left out because they hand off to the platform.
      for (final entry in <(String, IconData)>[
        ('field settings', Icons.grass_outlined),
        ('court settings', Icons.dashboard_outlined),
        ('language', Icons.language),
        ('practice plan', Icons.event_note_outlined),
        ('contact', Icons.mail_outline),
      ]) {
        final item = find.byIcon(entry.$2);
        if (item.evaluate().isEmpty) continue;
        await tester.tap(item.first, warnIfMissed: false);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        opened.add('$tag ${entry.$1}');
        await dismiss();
        // Re-open the menu for the next entry.
        final again = find.byIcon(Icons.more_horiz);
        if (again.evaluate().isEmpty) break;
        await tester.tap(again.first, warnIfMissed: false);
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
      }
      await dismiss();

      // The add-element sheet lives on the board's own toolbar.
      final add = find.byIcon(Icons.add);
      if (add.evaluate().isNotEmpty) {
        await tester.tap(add.first, warnIfMissed: false);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        opened.add('$tag add element');
        await dismiss();
      }

      // The player edit bar only exists while a player is selected, and it is
      // the busiest row in the app — an identity chip, a role chip, a move
      // toggle and four buttons, all in one line. Put a player on the board
      // and select it rather than trying to hit one by touch.
      // Let every route transition finish first. Selecting a player while a
      // page is still popping measures the edit bar against a dying tree —
      // the widgets come back DEFUNCT and 14 pixels wide, and the "overflow"
      // that reports is an artefact of the teardown, not a layout bug.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Only meaningful on the board itself, so make sure we are on it.
      if (find.byIcon(Icons.more_horiz).evaluate().isEmpty) {
        unopened.add('$tag: never got back to the board for the edit bar');
        continue;
      }
      // A context *below* the provider: TacticsBoardApp creates it, so its
      // own element cannot see it.
      final state =
          tester.element(find.byType(Scaffold).first).read<TacticsState>();
      if (state.players.isEmpty) {
        state.addPlayer(PlayerIcon(
          id: 'sweep',
          label: 'Alexandrine',
          team: PlayerTeam.home,
          position: const Offset(160, 260),
        ));
      }
      state.selectPlayer('sweep');
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      opened.add('$tag player edit bar');
      state.selectPlayer(null);
      // Fully gone before the next locale rebuilds the tree: a bar still
      // mounted when its subtree is disposed gets measured DEFUNCT at 14
      // pixels wide, and reports an overflow nobody could ever see.
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    debugDefaultTargetPlatformOverride = null;
    expect(unopened, isEmpty, reason: '\n${unopened.join('\n')}');
    expect(opened.length, greaterThanOrEqualTo(kLocales.length * 3),
        reason: 'the sweep opened too little to mean anything:\n'
            '${opened.join('\n')}');
  });
}
