import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

import 'overflow_test.dart' show kLocales;

/// A text element has to show the words that were typed into it.
///
/// It shipped as a circle with a hard-coded "T" and no way to type anything,
/// and a coach wrote a review saying that was where he gave up. The drawing
/// half of the fix is locked here; the input half (the tool asks before it
/// adds anything) lives in the toolbar.
///
/// One test, one pumpWidget: only the first EasyLocalization in a file
/// initialises, so a second one renders an empty tree and every finder comes
/// back with nothing — which reads as a failing assertion rather than as the
/// harness fault it is.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // TacticsState reads prefs as it is built; with no mock store
    // getInstance never completes and the test hangs rather than fails.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('text elements draw their words', (tester) async {
    const phrase = 'runner goes short, second man to the top of the D';
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 730 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    PlayerIcon text(String id, String label) => PlayerIcon(
          id: id,
          label: label,
          team: PlayerTeam.neutral,
          markerShape: MarkerShape.text,
          position: const Offset(200, 300),
        );

    final state = TacticsState(sportType: SportType.fieldHockey, preview: true)
      ..setCanvasSizeSilent(const Size(402, 730));
    final short = text('t1', 'drag flick far post');
    final long = text('t2', phrase);
    final blank = text('t3', '');

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: ChangeNotifierProvider<TacticsState>.value(
              value: state,
              child: Scaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    PlayerIconWidget(player: short),
                    PlayerIconWidget(player: long),
                    PlayerIconWidget(player: blank),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    // ── it shows what was typed, not a placeholder ──────────────────────
    expect(find.text('drag flick far post'), findsOneWidget);

    // ── a phrase is not cut to two characters ───────────────────────────
    // Every other element caps its label at two — a shirt number. A text
    // element IS the sentence, so that cap must not reach it.
    expect(find.text(phrase), findsOneWidget);
    final body = tester.widget<Text>(find.text(phrase));
    expect(body.maxLines, 3, reason: 'three lines, then it ellipsises');

    // Sized to the words: wider than the 44pt box every token lives in, and
    // capped so three notes on one pitch do not bury each other.
    final box = tester.getSize(
        find.ancestor(of: find.text(phrase), matching: find.byType(TextElementChip)));
    expect(box.width, greaterThan(kPlayerIconSize));
    expect(box.width, lessThanOrEqualTo(kTextElementMaxWidth + 1));

    // ── an empty one keeps the tool glyph so it can still be tapped ─────
    // An invisible element is one you cannot select in order to type into.
    expect(find.text('T'), findsOneWidget);
  });
}
