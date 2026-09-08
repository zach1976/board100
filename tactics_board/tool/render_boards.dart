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
import 'package:tactics_board/widgets/tactics_canvas.dart';

import '../test/widgets/overflow_test.dart' show kLocales;

/// Renders every drill board with the app's own painters, one PNG per phase.
///
/// The review page used to draw its own SVG approximation of a board, which is
/// a second implementation of the thing being reviewed — it cannot stay
/// truthful, and a reviewer correcting a board they are not actually looking at
/// is worse than no review page. This runs TacticsCanvas itself, so what the
/// page shows is what the phone shows.
///
///     FLUTTER_ROOT=<flutter> flutter test tool/render_boards.dart
///
/// Writes tools/board_png/<sport>/<id>-<step>.png. It lives in tool/ rather
/// than test/ because it is a build step, not a check — a @Tags annotation
/// does not exclude a file from a bare `flutter test`, and this one adds 79
/// seconds to every run of the suite.
const double kW = 320, kH = 480;

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
  testWidgets('render every drill board at every phase', (tester) async {
    final repo = Directory.current.parent;
    final drillDir = Directory('${Directory.current.path}/assets/drills');
    final outRoot = Directory('${repo.path}/tools/board_png');
    if (outRoot.existsSync()) outRoot.deleteSync(recursive: true);

    SharedPreferences.setMockInitialValues({'remove_ads_pro': true});
    await EasyLocalization.ensureInitialized();
    // Without a real font the test binding draws every glyph as a filled box,
    // so shirt numbers came out as white tofu — the one thing on a board a
    // coach reads first. Roboto ships with Flutter itself.
    await _loadRoboto();
    tester.view.physicalSize = const Size(kW * 3, kH * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState();
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
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
    await tester.pump(const Duration(milliseconds: 300));

    var boards = 0, shots = 0;
    final files = drillDir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      if (!f.path.endsWith('.json')) continue;
      final sport = f.uri.pathSegments.last.replaceAll('.json', '');
      final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final dir = Directory('${outRoot.path}/$sport')..createSync(recursive: true);

      for (final raw in data['drills'] as List) {
        final drill = raw as Map<String, dynamic>;
        state.loadFromJson(Map<String, dynamic>.from(drill['board'] as Map));
        state.setCanvasSizeSilent(const Size(kW, kH));
        await tester.pump(const Duration(milliseconds: 60));
        boards++;

        for (var step = 0; step <= state.maxMoveSteps; step++) {
          state.setTargetStep(step);
          await tester.pump(const Duration(milliseconds: 60));
          // runAsync: toImage is a real async GPU round-trip, and the images
          // the board loads (ball, marker sprites) only finish decoding
          // outside the fake-async zone the test runs in.
          await tester.runAsync(() async {
            final boundary = boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2.0);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            File('${dir.path}/${drill['id']}-$step.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
          shots++;
        }
      }
    }
    // ignore: avoid_print
    print('rendered $shots images for $boards boards -> ${outRoot.path}');
    expect(shots, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
