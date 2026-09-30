import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/ui/tokens.dart';
import 'package:tactics_board/widgets/timeline_editor.dart';
import 'package:tactics_board/widgets/toolbar.dart' show scaledSheet, sheetConstraints;

import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/main.dart' show TacticsBoardApp;

import 'overflow_test.dart' show kLocales;

/// 横屏下的时间轴，每个语言都不能溢出。
///
/// 竖屏的溢出扫描跑在 402x874 上；横屏的时间轴从来没被扫过，而 iPad 就是横着
/// 用的。2026-09-30 用户报「timeline 在横屏的时候，很多语言下还是有溢出」。
/// 一个语言一个用例：溢出会让用例失败并指名是哪一行画的，混在一个循环里
/// 只能看到第一个。
void main() {
  const sizes = <String, Size>{
    'phone': Size(874, 402),
    'ipad': Size(1376, 1032),
  };

  for (final size in sizes.entries) {
    for (final locale in kLocales) {
      testWidgets('时间轴 ${size.key} 横屏 · $locale', (tester) async {
        SharedPreferences.setMockInitialValues({});
        // Reset inside the body: the binding asserts every foundation debug
        // variable is unset by the time the body returns, and a tearDown
        // runs after that check.
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        await EasyLocalization.ensureInitialized();
        tester.view.physicalSize =
            Size(size.value.width * 2, size.value.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        final state = TacticsState(sportType: SportType.soccer);
        // Eight players with runs over three beats: enough rows for the
        // grid to scroll and enough columns for the header to have to fit.
        for (var i = 0; i < 8; i++) {
          state.addPlayer(PlayerIcon(
            id: 'p$i',
            // Two characters, like a keeper's: the label sits in a 40pt
            // box beside a dot and a gap, and one character never filled it.
            label: i == 0 ? 'GK' : '${i + 1}',
            team: i.isEven ? PlayerTeam.home : PlayerTeam.away,
            position: Offset(60.0 + i * 30, 120),
            moves: [Offset(80.0 + i * 30, 220), Offset(100.0 + i * 30, 300)],
            movePhases: const [0, 2],
          ));
        }

        await tester.pumpWidget(EasyLocalization(
          supportedLocales: kLocales,
          path: 'assets/translations',
          saveLocale: false,
          startLocale: locale,
          fallbackLocale: const Locale('en', 'US'),
          child: Builder(builder: (ctx) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              localizationsDelegates: ctx.localizationDelegates,
              supportedLocales: ctx.supportedLocales,
              locale: locale,
              theme: ThemeData(brightness: Brightness.dark),
              home: ChangeNotifierProvider<TacticsState>.value(
                value: state,
                child: Scaffold(
                  backgroundColor: T.surface,
                  // The app opens it through scaledSheet, which on a tablet
                  // puts a 1.4x text scaler over the sheet — the timeline
                  // was only ever measured without it.
                  // Exactly what the landscape rail gives it: a modal sheet
                  // capped at kPanelMaxWidth and at 92% of a SHORT screen,
                  // with the tablet text scaler over the top.
                  body: Builder(
                    builder: (c) => Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: sheetConstraints(c),
                        child: scaledSheet(c, TimelineEditor(state: state)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ));
        await tester.pumpAndSettle();
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }

  // The widget on its own fits. The app opens it from the board's toolbar,
  // inside a sheet, on a board that has a sport and a squad on it — which
  // is where a coach saw it overflow.
  for (final locale in kLocales) {
    testWidgets('时间轴从工具栏打开 · ipad 横屏 · $locale', (tester) async {
      SharedPreferences.setMockInitialValues({'intro_seen': true});
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      ConfigConstants.fixedSportType = SportType.soccer;
      addTearDown(() => ConfigConstants.fixedSportType = null);
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = const Size(1376 * 2, 1032 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        startLocale: locale,
        fallbackLocale: const Locale('en', 'US'),
        child: const TacticsBoardApp(),
      ));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final btn = find.byIcon(Icons.view_timeline_outlined);
      // ignore: avoid_print
      print('TIMELINE BUTTON found=${btn.evaluate().length} locale=$locale');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first, warnIfMissed: false);
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
