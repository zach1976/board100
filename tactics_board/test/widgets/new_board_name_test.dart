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

/// A blank board is named before it is drawn on.
///
/// An unnamed board cannot be found again: it is not in "my boards", and the
/// next blank one takes its place on the home card. So the question comes
/// first, while cancelling still costs nothing — there is no half-made board
/// to throw away.
///
/// One test, one pumpWidget: only the first EasyLocalization in a file
/// initialises.
void main() {
  testWidgets('new blank board asks for a name, and cancelling makes nothing',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'intro_seen': true});
    ConfigConstants.fixedSportType = SportType.soccer;
    addTearDown(() => ConfigConstants.fixedSportType = null);
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState(sportType: SportType.soccer);
    // Whatever an earlier run left in the shared temp directory.
    await tester.runAsync(() async {
      for (final name in await state.listSavedTactics()) {
        await state.deleteTactics(name);
      }
    });

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
    expect(find.byType(IntroPage), findsNothing, reason: 'intro is marked seen');

    // ── the button asks, before anything is created ─────────────────────
    await tester.tap(find.text('New board'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Name this board'), findsOneWidget,
        reason: 'a blank board is named before it is drawn on');

    // ── cancelling leaves nothing behind and does not open the board ────
    await tester.tap(find.text('Cancel'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    late List<String> afterCancel;
    await tester.runAsync(() async {
      afterCancel = await state.listSavedTactics();
    });
    expect(afterCancel, isEmpty,
        reason: 'cancelling makes no board at all');
    expect(find.text('New board'), findsOneWidget,
        reason: 'and leaves the coach on the home page');

    // ── naming it closes the question and gets on with it ──────────────
    //
    // What happens after the name is given — saveTactics writing the file —
    // cannot be watched from here: the write is started inside the fake
    // clock, so it never completes no matter how long the real one is given.
    // That path is exercised for real in add_to_plan_test, which calls
    // saveTactics from inside runAsync. What this test is for is the
    // question being asked at all, and costing nothing to refuse.
    await tester.tap(find.text('New board'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.enterText(find.byType(TextField), 'Tuesday shape');
    await tester.pump();
    await tester.tap(find.text('Apply'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Name this board'), findsNothing,
        reason: 'a name accepted closes the question');
  });

  // And the other half, without a widget in sight: the name the dialog
  // returns is the name the board is findable under afterwards.
  test('a named board turns up in the coach\'s own boards', () async {
    SharedPreferences.setMockInitialValues({});
    final state = TacticsState(sportType: SportType.soccer);
    for (final n in await state.listSavedTactics()) {
      await state.deleteTactics(n);
    }
    await state.saveTactics('Tuesday shape');
    expect(state.currentTacticName, 'Tuesday shape');
    expect(await state.listSavedTactics(), contains('Tuesday shape'));
    for (final n in await state.listSavedTactics()) {
      await state.deleteTactics(n);
    }
  });
}
