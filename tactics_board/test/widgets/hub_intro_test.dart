import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/intro_page.dart';
import 'package:tactics_board/pages/sport_home_page.dart';
import 'package:tactics_board/pages/sport_selection_page.dart';
import 'package:tactics_board/state/tactics_state.dart';

import 'overflow_test.dart' show kLocales;
import 'sport_selection_page_test.dart' show inCard, letItLoad, scrollTo;

/// The hub has one intro, its own, and picking a sport does not add another.
///
/// Before this the hub opened straight on the picker and the intro came up
/// on whichever sport was picked — a page about Tennis Board inside an app
/// that is not Tennis Board, and one more screen between the coach and the
/// pitch they had just chosen.
void main() {
  testWidgets('the hub intro runs once, before the picker, and never after',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => TacticsState(),
            child: MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const SportSelectionPage(),
            ),
          ),
        ),
      ),
    );
    await letItLoad(tester);

    // ── a first run lands on the hub's intro: no sport, all the drills ──
    expect(find.byType(IntroPage), findsOneWidget);
    final intro = tester.widget<IntroPage>(find.byType(IntroPage));
    expect(intro.sportType, isNull, reason: 'the hub is no one sport');
    expect(intro.drillCount, greaterThan(600),
        reason: 'the hub ships every library, and says so');
    // The title is painted by _StrokeTitle's own TextPainter, so it is not
    // a Text widget to find; the picker's header is, and it must not be up.
    expect(find.text('Choose a sport'), findsNothing,
        reason: 'the picker is behind the intro');

    // ── skip lands on the picker ────────────────────────────────────────
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(IntroPage), findsNothing);
    expect(find.byType(SportSelectionPage), findsOneWidget);

    // ── and a sport opens on its home page, with no second intro ────────
    final soccer = inCard('_SportCard', SportType.soccer.displayName);
    await scrollTo(tester, soccer);
    await tester.tap(soccer);
    await letItLoad(tester);
    expect(find.byType(SportHomePage), findsOneWidget);
    expect(find.byType(IntroPage), findsNothing,
        reason: 'the coach was just told what the app is');
    expect(await IntroPage.shouldShow(), isFalse);
  });
}
