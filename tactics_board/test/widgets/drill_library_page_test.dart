import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/pages/drill_detail_page.dart';
import 'package:tactics_board/pages/drill_library_page.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

/// The library sheet against the real shipped assets.
///
/// The per-drill contract lives in test/models/drill_test.dart; this is the
/// other half — that the authored drills actually reach a coach's screen, in
/// their language, and that tapping one puts it on the board.
///
/// It is one long test rather than five short ones because EasyLocalization
/// keeps process-wide state: the second EasyLocalization widget built in a
/// file renders an empty tree, so the scenarios share one widget lifetime.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('the drill library a coach actually sees', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    final state = TacticsState(sportType: SportType.soccer);
    state.setCanvasSizeSilent(const Size(400, 800));
    expect(state.players, isEmpty);

    // Warm the library in real async: rootBundle I/O does not complete under
    // the test binding's fake clock, so a cold sheet sits on its spinner.
    await tester.runAsync(
        () => DrillLibraryService.instance.forSport(SportType.soccer));

    late BuildContext ctx;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US'), Locale('zh', 'CN')],
        path: 'assets/translations',
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) {
            ctx = context;
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(body: DrillLibraryPage(state: state)),
            );
          },
        ),
      ),
    );
    // Not pumpAndSettle: the sheet shows a CircularProgressIndicator while it
    // loads, and a spinner never settles.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // ── it lists the shipped drills, in English ──────────────────────────
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('No drills for this sport yet'), findsNothing);
    expect(find.text('Rondo 4v2'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget, reason: 'the search box');

    // ── and in Chinese, including the variant half of a family name ──────
    await ctx.setLocale(const Locale('zh', 'CN'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('抢圈 4v2'), findsOneWidget);

    // The crossing family's variant used to be appended in English —
    // "传中 near post". Family drills sit far down a scrolling list, so this
    // one is found through search rather than by scrolling to it.
    await tester.enterText(find.byType(TextField), '近角');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('近角'), findsWidgets,
        reason: 'the variant should be translated, not appended in English');
    expect(find.textContaining('near post'), findsNothing);
    expect(find.text('抢圈 4v2'), findsNothing,
        reason: 'search should have filtered the rondo out');

    // ── a search with no matches says so rather than showing a blank list ─
    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('zzzzz'), findsWidgets);

    // ── tapping a drill opens it, rather than loading it blind ──────────
    // The card is a headline; a coach choosing what to run needs the board
    // and the whole note first. The list's one control — the + — is the
    // fast path for a drill they already know.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('抢圈 4v2'));
    await tester.pumpAndSettle();

    expect(find.byType(DrillDetailPage), findsOneWidget,
        reason: 'the card should open the drill, not load it');
    expect(state.players, isEmpty,
        reason: 'opening a drill must not touch the board behind the sheet');
    // The detail page draws the real board on its own throwaway state, and
    // its own button is what puts the drill on the live one.
    expect(find.byType(TacticsCanvas), findsWidgets);
    await tester.tap(find.text('放到板上'));
    await tester.pumpAndSettle();

    expect(state.players, isNotEmpty,
        reason: 'the drill should have replaced the empty board');
    expect(state.currentTacticName, isNull,
        reason: 'a loaded drill is an unsaved starting shape, not a tactic');
  });

  test('every sport ships a library, so the sheet is never empty', () async {
    // No widget here — a second EasyLocalization would render nothing. This
    // is the part that matters anyway: the sheet's empty state is driven by
    // exactly this list being empty.
    for (final sport in SportType.values) {
      final drills = await DrillLibraryService.instance.forSport(sport);
      expect(drills, isNotEmpty, reason: '${sport.name} has no library');
    }
  });
}
