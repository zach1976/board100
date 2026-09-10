// Shoots the app's own pages to PNGs, the way tool/render_boards.dart shoots
// the drill boards.
//
// A page cannot be judged from its source, and the simulator is a poor place
// to look at one: an app-open interstitial covers the first seconds of every
// launch, and reaching a page means tapping through the UI. Here the page is
// pumped directly at a real phone size, so a design change can be looked at
// in seconds and the same shot can be taken again after the next edit.
//
//   PAGE=home flutter test tool/shoot_pages.dart
//   PAGE=drill DRILL=passing_diamond flutter test tool/shoot_pages.dart
//
// Output: tools/page_png/<name>.png
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
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/drill_detail_page.dart';
import 'package:tactics_board/pages/drill_primer_page.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';
import 'package:tactics_board/pages/sport_home_page.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// Every locale the apps ship, so a shot can be taken in any of them.
const kLocales = [
  Locale('en', 'US'), Locale('en', 'GB'), Locale('zh', 'CN'),
  Locale('zh', 'TW'), Locale('ja', 'JP'), Locale('ko', 'KR'),
  Locale('fr', 'FR'), Locale('es', 'ES'), Locale('vi', 'VN'),
  Locale('th', 'TH'), Locale('id', 'ID'), Locale('ms', 'MY'),
];

/// A 402x874 phone — the one the drill boards were measured against.
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

/// A short corner with written notes on it — the thing the reviewer could
/// not build. Filled in once before the pump: a builder runs many times, and
/// adding the notes inside one puts four copies of every key on the board.
void _fillTextDemo(TacticsState state) {
  PlayerIcon note(String id, String label, double x, double y) => PlayerIcon(
        id: id,
        label: label,
        team: PlayerTeam.neutral,
        markerShape: MarkerShape.text,
        position: Offset(x, y),
      );
  state
    ..addPlayer(note('n1', 'injector waits for the call', 240, 250))
    ..addPlayer(note('n2', 'trap on the top of the D', 200, 620))
    ..addPlayer(note('n3', 'drag flick far post', 300, 430))
    ..addPlayer(note('n4', 'runner short', 90, 520));
}

void main() {
  testWidgets('shoot a page', (tester) async {
    final env = Platform.environment;
    final which = env['PAGE'] ?? 'home';
    final sport = SportType.values.firstWhere(
        (s) => s.name == (env['SPORT'] ?? 'soccer'),
        orElse: () => SportType.soccer);
    final locale = (env['LOCALE'] ?? 'zh-CN').split('-');

    SharedPreferences.setMockInitialValues({'remove_ads_pro': true});
    ConfigConstants.fixedSportType = sport;
    addTearDown(() => ConfigConstants.fixedSportType = null);
    await EasyLocalization.ensureInitialized();
    await _loadRoboto();
    tester.view.physicalSize = const Size(kW * 3, kH * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState(sportType: sport);
    // Asset reads are a real async round-trip; awaited in the fake-async zone
    // the test simply stops here.
    late final List<Drill> drills;
    await tester.runAsync(() async {
      drills = await DrillLibraryService.instance.forSport(sport);
    });
    final wanted = env['DRILL'];
    final drill = wanted == null
        ? drills.first
        : drills.firstWhere((d) => d.id == wanted, orElse: () => drills.first);

    if (which == 'text') {
      state.setCanvasSizeSilent(const Size(kW, kH));
      _fillTextDemo(state);
    }
    final key = GlobalKey();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        startLocale: Locale(locale.first, locale.length > 1 ? locale[1] : null),
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) => ChangeNotifierProvider<TacticsState>.value(
            value: state,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(fontFamily: 'Roboto'),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: RepaintBoundary(
                key: key,
                child: which == 'text'
                    // Inside a Scaffold: without a Material ancestor the
                    // canvas inherits DefaultTextStyle.fallback, whose font
                    // is null, and every glyph comes out as a tofu box.
                    ? Scaffold(
                        body: ChangeNotifierProvider<TacticsState>.value(
                            value: state,
                            child: const TacticsCanvas(preview: true)))
                    : which == 'primer'
                    ? DrillPrimerPage(sportType: sport)
                    : which == 'drill'
                    ? DrillDetailPage(
                        drill: drill,
                        sportType: sport,
                        locale: env['LOCALE'] ?? 'zh-CN',
                        onLoad: () {},
                      )
                    : const SportHomePage(),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // The ball and marker sprites decode outside the fake-async zone.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 600)));
    await tester.pump(const Duration(milliseconds: 100));

    final out = Directory('${Directory.current.parent.path}/tools/page_png')
      ..createSync(recursive: true);
    final name =
        which == 'drill' ? 'drill_${drill.id}' : '${which}_${sport.name}';
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${out.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    // ignore: avoid_print
    print('shot ${out.path}/$name.png');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
