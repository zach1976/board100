import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/drill_note.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/drill_detail_page.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

import 'overflow_test.dart' show kLocales;

/// The drill page's own idea: the board and the words are one thing.
///
/// A beat you can tap is only worth having if it moves the board, and the
/// board is only worth pinning if it is still on screen once you have
/// scrolled to the beat. One test, one pumpWidget — only the first
/// EasyLocalization in a file initialises.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('tapping a beat walks the board to it', (tester) async {
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    late final List<Drill> drills;
    await tester.runAsync(() async {
      drills = await DrillLibraryService.instance.forSport(SportType.soccer);
    });
    // A drill with several beats, so there is somewhere to jump TO.
    final drill = drills.firstWhere((d) => d.id == 'passing_diamond');

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
            home: DrillDetailPage(
              drill: drill,
              sportType: SportType.soccer,
              locale: 'en',
              onLoad: () {},
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The board is on the page, and it is the real canvas.
    expect(find.byType(TacticsCanvas), findsOneWidget);
    final state = tester
        .state<State<TacticsCanvas>>(find.byType(TacticsCanvas))
        .context
        .read<TacticsState>();
    expect(state.atStep, 0, reason: 'it opens on the setup');

    // Found by its own words, not by its number: the ball path above the
    // sequence is a row of numbered chips, so find.text('3') lands on a chip
    // that does nothing and the test passes or fails for the wrong reason.
    final note = DrillNote.parse(drill.localizedNote('en'));
    final seq = note.sections
        .firstWhere((s) => s.kind == DrillSectionKind.sequence);
    expect(seq.beats.length, greaterThanOrEqualTo(3));
    // A ListView builds lazily, so a beat below the fold is not in the tree
    // to be found until it has been scrolled to.
    final beat3 = find.text(seq.beats[2]);
    await tester.scrollUntilVisible(beat3, 120,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await tester.tap(beat3);
    // The board walks the beats one at a time, ~700ms each, so three of them
    // take a while; pump well past that rather than guessing.
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(state.atStep, 3,
        reason: 'tapping beat 3 should walk the board to step 3');
  });
}
