import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

import 'overflow_test.dart' show kLocales;

/// The edit bar keeps clear of the words on the board, not only of the
/// element it is editing.
///
/// The case that was reported (2026-10-10): one chip selected in the upper
/// half, another chip at the foot. At the foot the bar covered the second
/// chip; at the head it would cover the selected one. The bar now finds the
/// gap between them.
void main() {
  testWidgets('the edit bar sits between the selected chip and another',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(
        {'board_hint_seen': true, 'intro_seen': true, 'remove_ads_pro': true});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState(sportType: SportType.volleyball);
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
    final card = tester.getRect(find.byType(TacticsCanvas).first);
    state.setCanvasSizeSilent(card.size);

    PlayerIcon text(String id, String words, Offset at) => PlayerIcon(
          id: id,
          label: words,
          team: PlayerTeam.neutral,
          markerShape: MarkerShape.text,
          position: at,
          scale: 1.8,
        );
    final w = card.width, h = card.height;
    state.addPlayer(text('top', 'Selected', Offset(w / 2, h * 0.36)));
    state.addPlayer(text('foot', 'At the foot', Offset(w / 2, h * 0.95)));
    state.selectPlayer('top');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    Rect barRect() => tester.getRect(find
        .ancestor(
          of: find.byIcon(Icons.delete_outline_rounded),
          matching: find.byWidgetPredicate(
              (w) => w is ConstrainedBox && w.constraints.maxWidth == 540),
        )
        .first);

    // Collapsed first, then with the tune rows open: the taller bar has to
    // find its place again.
    await tester.tap(find.byIcon(Icons.tune).last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final bar = barRect();
    expect(bar.height, greaterThan(120), reason: 'tune rows did not open');
    // On the board only: the bar draws the chip it edits as well.
    final chips = find
        .descendant(
            of: find.byType(TacticsCanvas).first,
            matching: find.byType(TextElementChip))
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget)))
        // The board also lays chips out far off screen to measure them.
        .where(card.overlaps)
        .toList();
    expect(chips, hasLength(2), reason: '$chips');
    for (final chip in chips) {
      final o = bar.intersect(chip);
      expect(o.isEmpty || o.width <= 0 || o.height <= 0, isTrue,
          reason: 'bar $bar covers chip $chip');
    }
  });
}
