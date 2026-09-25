import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';


/// One board, one token selected, shot the way the phone draws it.
///
/// render_boards.dart shoots every drill but selects nobody, and the look of
/// a selected player is exactly the thing that cannot be judged from the
/// code. A simulator round-trip per idea is slower than this.
///
///     DRILL=warmup_y_pattern PICK=d0 OUT=/tmp/sel.png \
///       flutter test tool/sel_shot.dart
///
/// PICK is a token's id in the drill file (d0, d1, … for people, b0 for the
/// ball), not its label.

/// The board area on the phone the walk photographs: a 402x874 screen with
/// the toolbar and the safe areas taken off leaves 402x730 of pitch. Measured
/// off SoccerBoard/screenshots/01-board.png rather than guessed — the first
/// version rendered 320x480, and since a token is a fixed 44pt while the pitch
/// scales to its box, that made every player a third too big for the pitch
/// they stood on. The review page has to be the same shape as the phone or it
/// is reviewing a different board.
const double kW = 402, kH = 730;

Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.path;
  for (final entry in [
    ['Roboto', 'Roboto-Regular.ttf'],
    ['Roboto', 'Roboto-Bold.ttf'],
  ]) {
    final f = File('$root/bin/cache/artifacts/material_fonts/${entry[1]}');
    if (!f.existsSync()) continue;
    final loader = FontLoader(entry[0])
      ..addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
}

void main() {
  testWidgets('shoot one board with a player selected', (tester) async {
    final out = Platform.environment['OUT'] ??
        '/private/tmp/sel.png';
    final want = Platform.environment['DRILL'] ?? 'warmup_y_pattern';
    final pick = Platform.environment['PICK'] ?? 'd0';
    await _loadRoboto();
    // A dev script, not a test — same reason as render_boards.dart.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'intro_seen': true});
    tester.view.physicalSize = const Size(kW * 3, kH * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await EasyLocalization.ensureInitialized();
    final state = TacticsState();
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        path: 'assets/translations',
        saveLocale: false,
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) => MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: ChangeNotifierProvider<TacticsState>.value(
              value: state,
              child: Scaffold(
                body: Center(
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: const SizedBox(
                      width: kW,
                      height: kH,
                      child: TacticsCanvas(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(PlayerArt.warm);
    await tester.pump(const Duration(milliseconds: 300));

    final f = File('${Directory.current.path}/assets/drills/soccer.json');
    final drills = jsonDecode(f.readAsStringSync())['drills'] as List;
    final drill = drills.firstWhere((d) => d['id'] == want);
    state.loadFromJson(Map<String, dynamic>.from(drill['board'] as Map));
    state.setCanvasSizeSilent(const Size(kW, kH));
    state.setTargetStep(int.parse(Platform.environment['STEP'] ?? '0'));
    state.selectPlayer(pick);
    // PLAY=1 catches the board mid-move: the animation is driven by the
    // canvas, so it only needs starting and then letting run for a beat.
    if (Platform.environment['PLAY'] == '1') {
      state.stepForward();
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
      }
    }
    // The ball and the equipment sprites decode on first paint, and a frame
    // shot before they land comes out with no ball and no cones on it — the
    // same trap render_boards.dart warms its way around.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)));
    }
    await tester.pump(const Duration(milliseconds: 120));
    await tester.runAsync(() async {
      final b = boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 3.0);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('wrote $out');
  });
}
