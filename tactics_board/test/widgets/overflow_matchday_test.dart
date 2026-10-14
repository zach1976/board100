import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/match_day.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/match_day_page.dart';
import 'package:tactics_board/services/match_day_service.dart';

import 'overflow_test.dart' show kLocales, kNarrow;

/// The overflow sweep for the match-day screens: setup, the running sheet
/// and the summary, in every locale on the narrowest phone.
///
/// Its own file rather than a second block in overflow_pages_test: run
/// after the practice sweep in one process it never finished — the
/// practice pages leave file reads pending under the fake clock, and the
/// runAsync this sweep needs then waits on them forever.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('the match-day screens survive every locale on a small phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = Size(kNarrow.width * 3, kNarrow.height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // The page reads the match in progress from disk, so each screen is
    // reached the way a coach reaches it: nothing saved is the setup, a
    // saved match is the running sheet, a finished one is the summary.
    const sport = SportType.fieldHockey;
    MatchDay match({required bool finished}) {
      final t0 = DateTime(2026, 10, 14, 10);
      final m = MatchDay(
        name: 'Saturday away at the Tigers, second eleven',
        periods: 4,
        periodSeconds: 900,
        onPitch: 3,
        players: [
          for (var i = 1; i <= 6; i++)
            MatchPlayer(
                id: 'p$i',
                name: i.isEven ? 'Alexandrine van der Westhuizen' : 'Bo',
                number: '$i'),
        ],
        starters: const ['p1', 'p2', 'p3'],
        startedAt: t0,
      );
      m.start(t0);
      m.substitute('p1', 'p4', t0.add(const Duration(minutes: 5)));
      m.substitute('p2', 'p5', t0.add(const Duration(minutes: 9)));
      m.pause(t0.add(const Duration(minutes: 12)));
      if (finished) m.finish(t0.add(const Duration(minutes: 12)));
      return m;
    }

    final screen = ValueNotifier<Widget>(const SizedBox.shrink());
    addTearDown(screen.dispose);

    late BuildContext ctx;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(builder: (context) {
          ctx = context;
          return MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: ValueListenableBuilder<Widget>(
              valueListenable: screen,
              builder: (context, w, _) => w,
            ),
          );
        }),
      ),
    );

    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();

    final shown = <String>[];
    for (final locale in kLocales) {
      await ctx.setLocale(locale);
      await settle();
      final tag = '${locale.languageCode}-${locale.countryCode}';

      for (final entry in <(String, MatchDay?)>[
        ('match day setup', null),
        ('match day running', match(finished: false)),
        ('match day summary', match(finished: true)),
      ]) {
        // The file is the page's input, so it is written before the page
        // is built — and the page is built inside runAsync too, because
        // file reads started under the test's fake clock never complete,
        // and the sweep would be looking at a spinner.
        await tester.runAsync(() async {
          final m = entry.$2;
          if (m == null) {
            await MatchDayService.clearCurrent(sport);
          } else {
            await MatchDayService.saveCurrent(sport, m);
          }
          screen.value = const MatchDayPage(sport: sport);
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await settle();
        shown.add('$tag ${entry.$1}');
        screen.value = const SizedBox.shrink();
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // Not in a tearDown: those run under the fake clock, where the delete
    // would never finish.
    await tester.runAsync(() => MatchDayService.clearCurrent(sport));
    debugDefaultTargetPlatformOverride = null;
    expect(shown.length, kLocales.length * 3,
        reason: 'the sweep rendered fewer screens than it should have:\n'
            '${shown.join('\n')}');
  });
}
