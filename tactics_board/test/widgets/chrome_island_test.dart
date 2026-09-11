import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';

import 'overflow_test.dart' show kLocales;

/// The board's top chrome and the Dynamic Island.
///
/// The corner buttons deliberately sit BESIDE the island rather than below
/// it — the status bar is hidden, so the inset exists only for the island,
/// which is centred, and using that band back reclaims ~40pt of pitch.
///
/// That holds only while the corners hold small buttons. A second page grows
/// the page control from one circle to three, and anchored to the right it
/// reaches back into the island: a coach reported the "previous page"
/// chevron simply missing, because it was underneath it.
///
/// One test, one pumpWidget: only the first EasyLocalization in a file
/// initialises.
void main() {
  testWidgets('a second page moves the top row clear of the island',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    // An iPhone with a Dynamic Island: 59pt of top inset with the status bar
    // hidden is the island and nothing else.
    const inset = 59.0;
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = const FakeViewPadding(top: inset * 3);
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
              child: const TacticsBoardHomePage(),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The island's own band, centred. 63pt each side of centre covers the
    // widest island Apple ships; anything overlapping this horizontally has
    // to clear it vertically.
    const islandHalf = 63.0;
    final centre = tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

    /// Whether a control overlaps the island's own band.
    ///
    /// Checked per control rather than by sweeping every GestureDetector:
    /// the board itself is a full-width gesture surface, and it is SUPPOSED
    /// to run under the island — it is the pitch.
    bool underIsland(Finder finder) {
      for (final element in finder.evaluate()) {
        final box = element.renderObject as RenderBox?;
        if (box == null || !box.hasSize) continue;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        if (rect.top < inset &&
            rect.right > centre - islandHalf &&
            rect.left < centre + islandHalf) {
          return true;
        }
      }
      return false;
    }

    // One page: the row sits beside the island, and the page control — a
    // single circle in the right corner — is clear of it.
    expect(state.pageCount, 1);
    expect(underIsland(find.text('1')), isFalse,
        reason: 'with one page the corner control is clear of a centred island');

    // A second page grows the control to three circles. None of them, and
    // nothing else in the row, may end up under the island.
    state.addPage(copyCurrent: true);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(state.pageCount, 2);
    // Adding a page lands on it, so the label reads "2/2" — taken from the
    // state rather than written out, so this does not fail the day adding a
    // page stops navigating to it.
    final label = '${state.pageIndex + 1}/${state.pageCount}';
    expect(find.text(label), findsOneWidget);
    for (final control in <(String, Finder)>[
      ('previous page', find.byIcon(Icons.chevron_left)),
      ('next page', find.byIcon(Icons.chevron_right)),
      ('page count', find.text(label)),
      ('back', find.byIcon(Icons.arrow_back_ios_new_rounded)),
    ]) {
      expect(underIsland(control.$2), isFalse,
          reason: '${control.$1} must not sit under the Dynamic Island');
    }
  });
}
