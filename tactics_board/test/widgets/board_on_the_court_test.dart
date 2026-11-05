import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

import '../models/drill_test.dart' show loadShipped, shippedSports;
import 'overflow_test.dart' show kLocales;

/// 每一颗球、每一个人，在**宽**窗口里也必须画在场地线以内。
///
/// 场地是按自己的长宽比居中放进画布的，画布一瘦长就从「按高度撑满」翻成
/// 「按宽度撑满」，底线的位置跟着变。手机竖屏和训练素材用的画布都是前者，
/// 所以这个错位只在横过来的平板、Mac 窗口上露出来：上篮的球落在端线外、
/// 投篮的人站在篮筐上。这里就按 Mac 窗口的形状，把整座训练库摆一遍。
///
/// 十六个运动都在同一个 testWidgets 里走完：EasyLocalization 的初始化是
/// 全局的，一个文件里反复 testWidgets 时第二个起就建不出板子了。
void main() {
  testWidgets('every board stays on the court in a wide window', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'board_hint_seen': true,
      'intro_seen': true,
      'remove_ads_pro': true,
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await EasyLocalization.ensureInitialized();

    // A 1440x900 Mac window: wide enough that the court is fitted by width,
    // which is the case a phone never produces.
    tester.view.physicalSize = const Size(1440 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final offCourt = <String>[];

    for (final sportName in shippedSports()) {
      final sport = SportType.values.firstWhere((s) => s.name == sportName);
      // Two sports whose rect is not the playing area, both on purpose:
      // a baseball diamond's outfield is a fan reaching well past the square
      // fieldRect returns, and a table tennis table is drawn small because
      // the players stand a long way back from it (see COURT in
      // tools/drills/engine.py). A rectangle is the wrong question for them.
      if (sport == SportType.baseball || sport == SportType.tableTennis) {
        continue;
      }
      final state = TacticsState(sportType: sport);
      // Tear the tree down between sports. Pumping the same shape again
      // reuses the elements: the board keeps the element it had, its layout
      // never changes, and the drills of the second sport onwards were
      // measured against a board that was still the first sport's. Thirteen
      // sports "passed" that way.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
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
      for (
        var i = 0;
        i < 40 && find.byType(TacticsCanvas).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(TacticsCanvas), findsWidgets, reason: sportName);

      /// The court as it is painted, in screen coordinates.
      ///
      /// The canvas is laid out portrait inside a RotatedBox, so its own
      /// width is the card's height. The court is centred in the canvas both
      /// ways, so on screen it is centred in the card with its length across.
      Rect courtOnScreen() {
        final card = tester.getRect(find.byType(TacticsCanvas).first);
        final field = sport.fieldRect(Size(card.height, card.width));
        return Rect.fromCenter(
          center: card.center,
          width: field.height,
          height: field.width,
        );
      }

      // Loaded onto a board that is ALREADY the window's shape, which is what
      // the app does — the canvas is sized by the first layout and a drill is
      // opened onto it afterwards. Loading into a state that has not been
      // laid out yet goes through a different rescale and hides the bug.
      // The canvas the board is laid out at. The widget tells the state its
      // size through a post-frame callback that this harness does not run,
      // so it is set here — the same size, the same way round (the canvas
      // lives inside a RotatedBox, so its width is the card's height).
      final card = tester.getRect(find.byType(TacticsCanvas).first);
      state.setCanvasSizeSilent(Size(card.height, card.width));
      expect(state.canvasSize.height, greaterThan(1000), reason: sportName);

      for (final drill in loadShipped(sportName)) {
        // A throw-in taker stands behind the line by the rules.
        if (drill.offSurface) continue;
        // A lineout at Law 18's spacing opens on its own close-up
        // (viewWindow): the screen is not the court courtOnScreen finds,
        // and the thrower stands outside touch. test/state/view_window_test.
        if (drill.board['viewWindow'] != null) continue;
        state.loadFromJson(Map<String, dynamic>.from(drill.board));
        await tester.pump(const Duration(milliseconds: 60));
        final court = courtOnScreen();
        // Behind a tennis baseline is still the playing surface: the apron is
        // metres deep and a groundstroke is taken from back there.
        final apron =
            sport == SportType.tennis || sport == SportType.beachTennis
            ? court.height * 0.06
            : 0.0;
        // Half a figure may hang over a line — a man standing ON the baseline
        // is standing on the court. A whole figure past it is not. A ball is
        // small and a ball past the line is out of play, so it gets a tenth
        // of that.
        final forPeople = Rect.fromLTRB(
          court.left - kPlayerIconSize * 0.5 - apron,
          court.top - kPlayerIconSize * 0.5,
          court.right + kPlayerIconSize * 0.5 + apron,
          court.bottom + kPlayerIconSize * 0.5,
        );
        // A shot that goes in is past the goal line by the depth of the net.
        // Only the ball, only along the length, and only where there is a
        // goal to go in.
        const goalSports = {
          SportType.soccer,
          SportType.fieldHockey,
          SportType.handball,
          SportType.rugby,
          SportType.waterPolo,
        };
        final net = goalSports.contains(sport) ? court.width * 0.02 : 0.0;
        // A ball gets the same half-figure as a man, because a ball at his
        // feet sits that far from his point — a server standing behind the
        // baseline has his ball behind him. Half a figure is 26pt; the
        // misplacement this test is here for was three times that.
        final ballSlack = kPlayerIconSize * 0.5;
        final forBalls = Rect.fromLTRB(
          court.left - ballSlack - net - apron,
          court.top - ballSlack,
          court.right + ballSlack + net + apron,
          court.bottom + ballSlack,
        );

        for (var step = 0; step <= state.maxMoveSteps; step++) {
          state.setTargetStep(step);
          state.setShowMoveLines(step > 0);
          await tester.pump(const Duration(milliseconds: 60));
          for (final e
              in find
                  .byWidgetPredicate(
                    (w) => w is PlayerIconWidget && !w.player.isMarker,
                  )
                  .evaluate()) {
            final w = e.widget as PlayerIconWidget;
            final at = tester.getCenter(find.byWidget(w));
            // The off-screen copy the share PNG is rendered from lives
            // thousands of points to the left; nobody is looking at it.
            if (at.dx < 0 || at.dy < 0) continue;
            final allowed = w.player.isBall ? forBalls : forPeople;
            if (allowed.contains(at)) continue;
            final out = at.dx < allowed.left
                ? allowed.left - at.dx
                : at.dx > allowed.right
                ? at.dx - allowed.right
                : at.dy < allowed.top
                ? allowed.top - at.dy
                : at.dy - allowed.bottom;
            offCourt.add(
              '$sportName/${drill.id} step $step: '
              '${w.player.isBall ? "ball" : w.player.label} '
              '${out.toStringAsFixed(1)}pt outside',
            );
          }
        }
      }
    }

    debugDefaultTargetPlatformOverride = null;
    expect(
      offCourt,
      isEmpty,
      reason:
          '${offCourt.length} tokens drawn off the court:\n'
          '${offCourt.take(25).join("\n")}',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
