import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

import 'overflow_test.dart' show kLocales;

/// On a net court the edit bar goes to the far side of the net.
///
/// Reported 2026-10-15: a back-row volleyball player given a run, and the
/// bar opened across the foot of the board — over his run and the back
/// row. Nobody crosses a volleyball net, so the other half is empty space.
void main() => netSideCase(landscape: false);

/// One orientation per test file: the board page keeps static state that a
/// second case in the same isolate inherits (its canvas never appeared).
void netSideCase({required bool landscape}) {
  {
    testWidgets(
        'the bar keeps off the player, his run and his half '
        '(${landscape ? 'sideways' : 'upright'})', (tester) async {
      SharedPreferences.setMockInitialValues(
          {'board_hint_seen': true, 'intro_seen': true, 'remove_ads_pro': true});
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = landscape
          ? const Size(874 * 3, 402 * 3)
          : const Size(402 * 3, 874 * 3);
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
      for (var i = 0;
          i < 10;
          i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final canvasBox = tester.renderObject<RenderBox>(
          find.byType(TacticsCanvas).first);
      final size = canvasBox.size;
      state.setCanvasSizeSilent(size);
      final court = SportType.volleyball.fieldRect(size);

      // Our half is the lower one on the board's own frame.
      Offset at(double fx, double fy) => Offset(
          court.left + court.width * fx, court.top + court.height * fy);
      state.addPlayer(PlayerIcon(
          id: 'runner', label: 'L', team: PlayerTeam.home,
          position: at(0.75, 0.94),
          moves: [at(0.5, 0.78), at(0.75, 0.62), at(0.75, 0.53)]));
      for (final (i, fx) in [0.2, 0.5, 0.8].indexed) {
        state.addPlayer(PlayerIcon(
            id: 'back$i', label: 'B', team: PlayerTeam.home,
            position: at(fx, 0.83)));
      }
      state.selectPlayer('runner');
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final bar = tester.getRect(find
          .ancestor(
            of: find.byIcon(Icons.delete_outline_rounded),
            matching: find.byWidgetPredicate(
                (w) => w is ConstrainedBox && w.constraints.maxWidth == 540),
          )
          .first);
      Rect screen(Rect r) {
        final pts = [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]
            .map(canvasBox.localToGlobal)
            .toList();
        var out = Rect.fromPoints(pts[0], pts[0]);
        for (final p in pts) {
          out = out.expandToInclude(Rect.fromPoints(p, p));
        }
        return out;
      }

      final ours = screen(Rect.fromLTRB(
          0, court.center.dy, size.width, size.height));
      final run = screen(Rect.fromPoints(at(0.5, 0.53), at(0.75, 0.94)));
      expect(bar.overlaps(run), isFalse, reason: 'bar $bar over run $run');
      final o = bar.intersect(ours);
      final share = o.width <= 0 || o.height <= 0
          ? 0.0
          : o.width * o.height / (bar.width * bar.height);
      expect(share, lessThan(0.5),
          reason: 'bar $bar mostly on our half $ours');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
