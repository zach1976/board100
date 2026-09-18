// Photographs this app's home page with its own artwork.
//
// The hero and the nine drill covers live in THIS package, not in the core,
// so a render run from tactics_board/ can only ever show the flat fallback —
// the one thing worth looking at is the one thing it cannot draw. This runs
// the real SportHomePage inside the real shell bundle and writes what it drew.
//
//   cd SoccerBoard
//   FLUTTER_ROOT=<flutter> flutter test tool/shoot_home.dart
//
// Output: build/home.png. It lives in tool/ rather than test/ because it is a
// look, not a check: it asserts nothing about the pixels.
//
// Chinese comes out as tofu — Roboto has no CJK and every CJK face macOS
// ships is a .ttc, which FontLoader cannot read. The boxes are still the
// right size, because a CJK glyph is a square em: what this shot answers is
// whether the layout holds, not whether the type looks good.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/sport_home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// A 402x874 phone, the same one the board renders are measured against.
const double kW = 402, kH = 874;

Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.path;
  for (final file in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
    final f = File('$root/bin/cache/artifacts/material_fonts/$file');
    if (!f.existsSync()) continue;
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
}

void main() {
  testWidgets('shoot the home page', (tester) async {
    // Seen the intro, bought Pro: neither the walkthrough nor an ad is the
    // thing being looked at.
    SharedPreferences.setMockInitialValues({
      'intro_seen': true,
      'remove_ads_pro': true,
    });
    await EasyLocalization.ensureInitialized();
    await _loadRoboto();

    ConfigConstants.fixedSportType = SportType.soccer;
    ConfigConstants.hasPackagePath = true;

    tester.view.physicalSize = const Size(kW * 3, kH * 3);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);

    // The shell fixes the sport in main(); the state does not read that
    // on its own, so the harness has to say it too or the board card
    // draws a basketball court in a football app.
    final state = TacticsState()..setSportType(SportType.soccer);
    final key = GlobalKey();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        path: 'packages/tactics_board/assets/translations',
        assetLoader: const RootBundleAssetLoader(),
        startLocale: const Locale('zh', 'CN'),
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Roboto'),
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: ChangeNotifierProvider<TacticsState>.value(
              value: state,
              child: RepaintBoundary(key: key, child: const SportHomePage()),
            ),
          ),
        ),
      ),
    );

    // The drill library, the saved boards and the artwork probe are all
    // futures; give them real time rather than fake-async pumps.
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump(const Duration(milliseconds: 60));
    }

    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('build/home.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
      // ignore: avoid_print
      print('wrote ${out.path}');
      image.dispose();
    });
  }, timeout: const Timeout(Duration(minutes: 3)));
}
