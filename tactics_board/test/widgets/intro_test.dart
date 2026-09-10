import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/intro_page.dart';
import 'package:tactics_board/pages/sport_home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';

import 'overflow_test.dart' show kLocales;

/// The intro is shown once and never again.
///
/// A first impression is exactly the thing nobody notices is broken: whoever
/// is testing has already seen it, so an intro that started appearing on
/// every launch — or stopped appearing at all — would ship.
///
/// One test, one pumpWidget: only the first EasyLocalization in a file
/// initialises.
void main() {
  testWidgets('shown on a first run, skipped for good', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    ConfigConstants.fixedSportType = SportType.soccer;
    addTearDown(() => ConfigConstants.fixedSportType = null);
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState(sportType: SportType.soccer);
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
              child: const SportHomePage(),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // ── a first run lands on the intro, not on the home page ────────────
    expect(find.byType(IntroPage), findsOneWidget);
    expect(find.text('Open the board'), findsNothing,
        reason: 'the home page is behind the intro, not in front of it');

    // ── skip is on the first panel: knowing what a tactics board is must
    //    not cost three taps ─────────────────────────────────────────────
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(IntroPage), findsNothing);
    expect(find.text('Open the board'), findsOneWidget,
        reason: 'skipping lands on the home page, not on a blank screen');

    // ── and it is remembered, so the next launch goes straight through ──
    expect(await IntroPage.shouldShow(), isFalse);
  });
}
