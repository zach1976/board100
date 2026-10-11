import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/practice.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/drill_detail_page.dart';
import 'package:tactics_board/pages/drill_library_page.dart';
import 'package:tactics_board/pages/intro_page.dart';
import 'package:tactics_board/pages/main_shell.dart';
import 'package:tactics_board/pages/practice_plan_page.dart';
import 'package:tactics_board/pages/practice_run_page.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/services/practice_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/ui/tokens.dart';

/// The iPad layout of the pages around the board, against a phone.
///
/// Every rule in lib/ui/adaptive.dart is gated on a tablet window, so each
/// check here is made twice: on an iPad (13", either way up) the page takes
/// its tablet form — a side rail, a list beside its detail, a capped column
/// — and on an iPhone the same page is exactly the phone page it was.
///
/// One test, not several: EasyLocalization keeps process-wide state and a
/// second instance in the same file renders nothing (see
/// drill_library_page_test.dart), so the pages share one widget lifetime
/// and are swapped in through a notifier.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  const ipadPortrait = Size(1032, 1376);
  const ipadLandscape = Size(1376, 1032);
  const phone = Size(402, 874);

  testWidgets('tablet layouts apply on an iPad and only there',
      (tester) async {
    // The intro is seen, so the shell opens on its tabs.
    SharedPreferences.setMockInitialValues({'intro_seen': true});
    // StoreKit, not the Android billing plugin, which opens a connection
    // that fails asynchronously — see overflow_test.dart.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await EasyLocalization.ensureInitialized();

    Future<void> setSize(Size s) async {
      tester.view.physicalSize = s * 2;
      tester.view.devicePixelRatio = 2;
      await tester.pump();
    }

    addTearDown(tester.view.reset);

    // A sport no other test writes plans for: PracticeService falls back to
    // the shared system temp directory under `flutter test`.
    const sport = SportType.sepakTakraw;
    final state = TacticsState(sportType: sport);
    await tester.runAsync(() async {
      await DrillLibraryService.instance.forSport(sport);
      for (final n in await PracticeService.listNames(sport)) {
        await PracticeService.delete(sport, n);
      }
      await PracticeService.save(
          sport,
          Practice(name: 'Tuesday', items: [
            PracticeItem(tacticName: 'Rotation', durationMinutes: 10),
          ]));
    });
    addTearDown(() => tester.runAsync(() async {
          for (final n in await PracticeService.listNames(sport)) {
            await PracticeService.delete(sport, n);
          }
        }));

    final screen = ValueNotifier<Widget>(const SizedBox.shrink());
    addTearDown(screen.dispose);
    await setSize(ipadPortrait);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        path: 'assets/translations',
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(builder: (context) {
          return ChangeNotifierProvider<TacticsState>.value(
            value: state,
            child: MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: ValueListenableBuilder<Widget>(
                valueListenable: screen,
                builder: (_, w, _) => w,
              ),
            ),
          );
        }),
      ),
    );

    Future<void> show(Widget w) async {
      screen.value = const SizedBox.shrink();
      await tester.pump();
      screen.value = w;
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> settleIo() async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // ── the shell: a side rail on an iPad, the bottom bar on a phone ────
    final rail = find.byKey(const ValueKey('shell-side-rail'));
    await show(const MainShell());
    await settleIo();
    expect(rail, findsOneWidget, reason: 'iPad sections live in a side rail');
    await setSize(ipadLandscape);
    expect(rail, findsOneWidget);
    await setSize(phone);
    expect(rail, findsNothing, reason: 'a phone keeps its bottom tab bar');
    expect(find.text('tab_drills'.tr()), findsWidgets);

    // ── Me: a centred column on an iPad, the value at the row's end ─────
    Future<void> openMe({required bool tablet}) async {
      await tester.tap(tablet
          ? find.descendant(of: rail, matching: find.text('tab_mine'.tr()))
          : find.text('tab_mine'.tr()).last);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await openMe(tablet: false);
    final title = find.text('tab_mine'.tr()).first;
    final language = find.text('menu_language'.tr());
    // On a phone the page keeps its 16pt margin.
    expect(tester.getRect(title).left, lessThan(40));
    await setSize(ipadLandscape);
    await openMe(tablet: true);
    // 1376 - 92pt rail = 1284; a 760pt column leaves 262 a side.
    // The page's own title; the rail's label comes first in the tree.
    expect(tester.getRect(find.text('tab_mine'.tr()).last).left,
        greaterThan(92 + 200),
        reason: 'Me is a centred column on an iPad, not 1300pt wide');
    // The language name sits at the row's far end, by the chevron — not in
    // the middle of the row.
    // Where the glyphs start, not the Text's box: both sit in Expanded
    // slots, so the boxes always meet. The value's first letter must sit at
    // the row's end, by the chevron.
    final value = find.text('English (US)').first;
    final para = tester.renderObject<RenderParagraph>(value);
    final valueStart = tester.getRect(value).left +
        para.getOffsetForCaret(const TextPosition(offset: 0), Rect.zero).dx;
    final rowStart = tester.getRect(language).left;
    expect(valueStart - rowStart, greaterThan(760 * 0.6),
        reason: 'the value belongs at the end of the row, not mid-row');

    // ── the drill library: list beside detail on an iPad only ──────────
    await show(Scaffold(body: DrillLibraryPage(state: state)));
    await settleIo();
    expect(find.byType(DrillDetailPage), findsOneWidget,
        reason: 'a wide iPad shows the first drill beside the list');
    await setSize(ipadPortrait);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(DrillDetailPage), findsOneWidget,
        reason: 'portrait 13" is still wide enough to split');
    await setSize(phone);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(DrillDetailPage), findsNothing,
        reason: 'a phone pushes the drill page instead');

    // ── practice plans: the editor beside the list on an iPad only ──────
    await setSize(ipadLandscape);
    await show(PracticePlanPage(state: state));
    await settleIo();
    // The first plan is opened once the list is read: a second read.
    await settleIo();
    expect(find.text('Tuesday'), findsWidgets);
    expect(find.byType(PracticeEditPage), findsOneWidget,
        reason: 'the first plan opens beside the list');
    await setSize(phone);
    await show(PracticePlanPage(state: state));
    await settleIo();
    expect(find.byType(PracticeEditPage), findsNothing);
    expect(find.text('Tuesday'), findsOneWidget);

    // ── the run page: a capped column on an iPad, the phone page as was ─
    final practice = Practice(name: 'Tuesday', items: [
      PracticeItem(tacticName: 'Rotation', durationMinutes: 10),
      PracticeItem(tacticName: 'Serve receive', durationMinutes: 10),
    ]);
    final openBoard = find.text('practice_open_board'.tr());
    await setSize(ipadPortrait);
    await show(PracticeRunPage(state: state, practice: practice));
    final tabletButtons =
        tester.getRect(find.byType(OutlinedButton)).left;
    final tabletRight = tester.getRect(openBoard).right;
    expect(tabletButtons, greaterThan((1032 - 640) / 2 - 1),
        reason: 'the controls are a 640pt column, not 1000pt wide');
    expect(tabletRight, lessThan(1032 - (1032 - 640) / 2 + 1));
    await setSize(ipadLandscape);
    await tester.pump(const Duration(milliseconds: 50));
    // On its side the controls stand down the right in a 420pt column.
    expect(tester.getRect(find.byType(OutlinedButton)).left,
        greaterThan(1376 / 2));
    await setSize(phone);
    await tester.pump(const Duration(milliseconds: 50));
    // The phone keeps its 20pt margins.
    expect(tester.getRect(find.byType(OutlinedButton)).left, 20);

    // ── the intro: a button, not a 1336pt bar; the art beside the words ─
    final cta = find.ancestor(
        of: find.text('intro_next'.tr()), matching: find.byType(InkWell));
    await setSize(ipadLandscape);
    await show(IntroPage(sportType: sport, onDone: () {}));
    expect(tester.getSize(cta.first).width, lessThanOrEqualTo(480));
    await setSize(phone);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getSize(cta.first).width, 402 - 2 * T.screenX,
        reason: 'a phone keeps its full-width button');

    screen.value = const SizedBox.shrink();
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}
