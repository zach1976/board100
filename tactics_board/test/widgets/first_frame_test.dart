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

import 'overflow_test.dart' show kLocales;

/// 按下「下一步」的第一帧，画面和按之前那一帧必须一模一样。
///
/// isAnimating 会比驱动器摆放任何东西早一帧立起来；那一帧里板子还是
/// 静止帧的样子，但如果按「正在播的那一拍」去读持球人，球就会被判给
/// 下一拍的接球人——离得远，往脚边拉的力度几乎为零——于是球从传球人
/// 脚边跳回它的原始落点，然后才飞出去。每一次从第 0 步开始都会闪一下。
/// 这里量的是：传球人脚边那颗球，静止时画在哪，第一帧还画在哪。
void main() {
  testWidgets('the first frame of a step draws the ball where the rest frame did',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({'board_hint_seen': true, 'intro_seen': true});
    await EasyLocalization.ensureInitialized();

    // A passes to B, 200 units away: far enough that B's pull on the ball,
    // read a frame early, would be a different place from A's.
    final state = TacticsState(sportType: SportType.soccer)
      ..addPlayer(PlayerIcon(
          id: 'A', label: 'A', team: PlayerTeam.home,
          position: const Offset(120, 400)))
      ..addPlayer(PlayerIcon(
          id: 'B', label: 'B', team: PlayerTeam.home,
          position: const Offset(320, 400)))
      ..addPlayer(PlayerIcon(
          id: 'ball', label: '', team: PlayerTeam.neutral,
          sportType: SportType.soccer,
          position: const Offset(135, 405),
          moves: const [Offset(305, 405)], movePhases: const [0],
          moveHolders: const ['B'], holder: 'A'))
      ..selectPlayer(null);
    expect(state.hasMoves, isTrue);

    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(EasyLocalization(
      supportedLocales: kLocales, path: 'assets/translations', saveLocale: false,
      startLocale: const Locale('en', 'US'), fallbackLocale: const Locale('en', 'US'),
      child: Builder(builder: (context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales, locale: context.locale,
        home: ChangeNotifierProvider<TacticsState>.value(
            value: state, child: const TacticsBoardHomePage()),
      )),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The ball is on the board twice by design — the live token and the copy
    // that stands at the end of its leg as the waypoint handle — so every
    // glyph of it is measured, in a stable order.
    List<Offset> ballsOnScreen() {
      final f = find.byWidgetPredicate(
          (w) => w is PlayerIconWidget && w.player.isBall && w.player.id == 'ball');
      expect(f, findsWidgets);
      final c = f.evaluate().map((e) => tester.getCenter(find.byWidget(e.widget))).toList()
        ..sort((a, b) => a.dx.compareTo(b.dx));
      return c;
    }

    final atRest = ballsOnScreen();
    // The step starts: the flag is up, nothing has been placed yet. This is
    // the frame that used to flash.
    state.stepForward();
    await tester.pump();
    expect(state.isAnimating, isTrue);
    final firstFrame = ballsOnScreen();
    expect(firstFrame.length, atRest.length);
    for (var i = 0; i < atRest.length; i++) {
      final hop = (firstFrame[i] - atRest[i]).distance;
      expect(hop, lessThan(0.5),
          reason: 'ball glyph $i hopped ${hop.toStringAsFixed(1)}pt on the first frame');
    }
  });
}
