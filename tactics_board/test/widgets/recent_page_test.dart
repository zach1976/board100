import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/recent_page.dart';
import 'package:tactics_board/services/recent_boards_service.dart';

import 'overflow_test.dart' show kLocales;
import 'sport_selection_page_test.dart' show letItLoad;

/// The list behind the home page's recent row.
///
/// Its whole job is depth — a hundred entries, not the four the row shows —
/// and handing the tapped one back rather than opening it itself.
void main() {
  testWidgets('lists everything recent and returns what was tapped',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // EasyLocalization reads prefs on the way up; without a store to read
    // the test hangs rather than failing.
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final items = [
      for (var i = 0; i < 100; i++)
        RecentBoard(
          kind: i.isEven ? RecentBoardKind.drill : RecentBoardKind.tactic,
          id: 'id$i',
          label: 'Board $i',
          openedAt: now.subtract(Duration(days: i)),
        ),
    ];

    RecentBoard? picked;
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
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      picked = await RecentPage.push(ctx,
                          items: items,
                          sport: SportType.soccer,
                          byId: const {});
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // EasyLocalization reads the translations off the bundle before it
    // builds anything at all; tapping before that is tapping a blank frame.
    await letItLoad(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The newest leads, and today is today.
    expect(find.text('Board 0'), findsOneWidget);
    expect(find.text('today'), findsOneWidget);
    expect(find.text('yesterday'), findsOneWidget);
    // The whole hundred is in the list, not just the few the home row shows.
    // Asserted on the list rather than by scrolling to the end of it: the
    // rows below the fold are built lazily and dragging to row a hundred is
    // a minute of pumping for a number the list already knows.
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.semanticChildCount, 100);

    await tester.tap(find.text('Board 2'));
    await tester.pumpAndSettle();
    expect(picked?.id, 'id2', reason: 'the page hands the row back');
    expect(find.text('open'), findsOneWidget, reason: 'and closes itself');
  });
}
