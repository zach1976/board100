import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/toolbar.dart';

import 'overflow_test.dart' show kLocales;

/// 两条底部胶囊在每一档手机宽度上都放得下。
///
/// 原来的溢出扫描只跑 320 和 402，而且板子上没有动作，所以播放胶囊
/// 根本没被建出来——昨晚把按钮加大之后它在 375pt 的机器上溢出 8pt，
/// 什么也没拦住。这里给板子一个有跑动的球员，三档宽度各跑一遍。
///
/// 一个测试、一次 pumpWidget 加三次尺寸变更：一个文件里只有第一个
/// EasyLocalization 会初始化。
void main() {
  testWidgets('both capsules fit at 320, 375 and 402', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    final state = TacticsState(sportType: SportType.soccer)
      ..addPlayer(PlayerIcon(
          id: 'a', label: 'A', team: PlayerTeam.home,
          position: const Offset(100, 200)))
      ..addPlayerMove('a', const Offset(200, 300))
      // addPlayer leaves the new man selected, which opens the edit bar over
      // the capsules; that bar has an overflow of its own at 402pt (the
      // identity row, home_page.dart ~1765), older than this test and not
      // what it measures.
      ..selectPlayer(null);
    expect(state.hasMoves, isTrue, reason: '没有动作就没有播放胶囊可测');

    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = const FakeViewPadding(top: 47 * 3);
    addTearDown(tester.view.reset);

    for (final width in [402.0, 375.0, 320.0]) {
      tester.view.physicalSize = Size(width * 3, 874 * 3);
      if (width == 402.0) {
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
      }
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // 溢出会以异常形式抛出来；没有异常就是放得下。
      expect(tester.takeException(), isNull, reason: '$width pt');
      expect(find.byType(PlayControlsBar), findsOneWidget, reason: '$width pt');
      expect(find.byType(TacticsToolbar), findsOneWidget, reason: '$width pt');
    }
  });
}
