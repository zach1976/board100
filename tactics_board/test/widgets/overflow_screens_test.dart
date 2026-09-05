import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/main.dart';
import 'package:tactics_board/models/sport_type.dart';

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
    await tester.binding.setSurfaceSize(kNarrow);
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
      ]) {
        final item = find.byIcon(entry.$2);
        if (item.evaluate().isEmpty) continue;
        await tester.tap(item.first, warnIfMissed: false);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        opened.add('$tag ${entry.$1}');
        await tester.tapAt(const Offset(5, 5));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        // Re-open the menu for the next entry.
        final again = find.byIcon(Icons.more_horiz);
        if (again.evaluate().isEmpty) break;
        await tester.tap(again.first, warnIfMissed: false);
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
      }
      await tester.tapAt(const Offset(5, 5));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }

      // The add-element sheet lives on the board's own toolbar.
      final add = find.byIcon(Icons.add);
      if (add.evaluate().isNotEmpty) {
        await tester.tap(add.first, warnIfMissed: false);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        opened.add('$tag add element');
        await tester.tapAt(const Offset(5, 5));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
      }
    }

    debugDefaultTargetPlatformOverride = null;
    expect(unopened, isEmpty, reason: '\n${unopened.join('\n')}');
    expect(opened.length, greaterThanOrEqualTo(kLocales.length * 3),
        reason: 'the sweep opened too little to mean anything:\n'
            '${opened.join('\n')}');
  });
}
