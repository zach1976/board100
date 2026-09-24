import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/sport_selection_page.dart';
import 'package:tactics_board/state/tactics_state.dart';

import 'overflow_test.dart' show kLocales, kNarrow;

/// The hub's front door, in every language, on the narrowest phone.
///
/// One pumpWidget for the whole sweep: only the first EasyLocalization in a
/// file renders anything. Layout overflows are left to Flutter's own
/// handling, which fails the test and names the widget.
/// The page loads its counts through real I/O — the asset index and the
/// documents directory — which a fake-async test never runs until it yields
/// to the real event loop. Yield, then settle.
/// The page's cards are private types; match them by name so a sport's
/// text can be told apart on the Continue card and on its shelf.
Finder inCard(String type, String text) => find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == type));

/// Bring a lazily built sliver child on screen. scrollUntilVisible needs its
/// target to exist in the tree, and a card three shelves down does not
/// exist until the grid has been scrolled far enough to build it.
Future<void> scrollTo(WidgetTester tester, Finder f) async {
  // From the top every time: a target above the viewport is not in the
  // tree either, and scrolling down would never meet it.
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 6000));
  await tester.pumpAndSettle();
  for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -240));
    await tester.pumpAndSettle();
  }
  expect(f, findsWidgets);
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
}

Future<void> letItLoad(WidgetTester tester) async {
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('shelves every sport, remembers the last one, in every locale',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      SportSelectionPage.recentPrefsKey: ['tennis', 'soccer'],
    });
    await EasyLocalization.ensureInitialized();
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
          // Above the navigator, as in the app: picking a sport replaces the
          // route, and the home page behind it reads the same state.
          return ChangeNotifierProvider(
            create: (_) => TacticsState(),
            child: MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const SportSelectionPage(),
            ),
          );
        }),
      ),
    );
    await letItLoad(tester);

    for (final locale in kLocales) {
      await ctx.setLocale(locale);
      await tester.pumpAndSettle();

      // The sport run last leads the page, with its counts, and only that
      // one: a second recent sport is not a second card.
      expect(find.text('hub_continue'.tr().toUpperCase()), findsOneWidget,
          reason: '$locale: no Continue card');
      expect(inCard('_ContinueCard', SportType.tennis.displayName),
          findsOneWidget,
          reason: '$locale: the Continue card should be tennis');
      expect(find.textContaining('hub_drills_n'.tr(args: ['38'])),
          findsWidgets,
          reason: '$locale: the tennis count comes from the index');

      // Three shelves, and every sport on exactly one of them.
      for (final key in ['hub_group_pitch', 'hub_group_net', 'hub_group_other']) {
        final shelf = find.text(key.tr().toUpperCase());
        await scrollTo(tester, shelf);
        expect(shelf, findsOneWidget, reason: '$locale: shelf $key');
      }
      for (final s in SportType.values) {
        // Cards below the fold are built lazily; scroll each into view.
        final card = inCard('_SportCard', s.displayName);
        await scrollTo(tester, card);
        expect(card, findsOneWidget,
            reason: '$locale: ${s.name} missing or on two shelves');
      }
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await tester.pumpAndSettle();
    }

    // Picking a sport puts it at the front of the recent list; the one
    // already there moves down rather than being forgotten.
    await ctx.setLocale(const Locale('en', 'US'));
    await tester.pumpAndSettle();
    final badminton = inCard('_SportCard', SportType.badminton.displayName);
    await scrollTo(tester, badminton);
    await tester.tap(badminton);
    await letItLoad(tester);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(SportSelectionPage.recentPrefsKey),
        ['badminton', 'tennis', 'soccer']);
  });
}
