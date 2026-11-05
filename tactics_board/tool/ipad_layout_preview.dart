import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/painters/court_art.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

import '../test/widgets/overflow_test.dart' show kLocales;

/// One picture of the board screen, for looking at a change before
/// committing to a capture run.
///
///     flutter test tool/ipad_layout_preview.dart
///     flutter test tool/ipad_layout_preview.dart --dart-define=RAIL=true
///     flutter test tool/ipad_layout_preview.dart \
///         --dart-define=SPORT=basketball --dart-define=DRILL=bb_dho \
///         --dart-define=W=1206 --dart-define=H=2622 --dart-define=OUT=ball
///
/// RAIL=true draws the pre-2026-09-30 layout for comparison: the page reads
/// the tablet test off MediaQuery, so telling it a phone's size brings the
/// side rail back while the box it lays out in stays the iPad's.
const _rail = bool.fromEnvironment('RAIL');
const _sport = String.fromEnvironment('SPORT', defaultValue: 'fieldHockey');
const _drill = String.fromEnvironment('DRILL', defaultValue: 'fh_press_high');
const _w = int.fromEnvironment('W', defaultValue: 2732);
const _h = int.fromEnvironment('H', defaultValue: 2048);
const _out = String.fromEnvironment('OUT', defaultValue: 'ipad_layout');
const _step = int.fromEnvironment('STEP', defaultValue: 0);
/// A fake safe-area inset at the top, in points — 59 is an island phone.
/// The test view has none, and the chrome lays itself out by it.
const _topInset = int.fromEnvironment('TOP', defaultValue: 0);
/// Side insets, in points — 59 each is an island phone turned sideways.
const _sideInset = int.fromEnvironment('SIDE', defaultValue: 0);

void main() {
  testWidgets('ipad landscape board', (t) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'flutter.board_hint_seen': true,
      'flutter.intro_seen': true,
      'flutter.remove_ads_pro': true,
    });
    await EasyLocalization.ensureInitialized();
    t.view.physicalSize = Size(_w.toDouble(), _h.toDouble());
    t.view.devicePixelRatio = 2.0;
    if (_topInset > 0 || _sideInset > 0) {
      final pad = FakeViewPadding(
          top: _topInset * 2.0, left: _sideInset * 2.0, right: _sideInset * 2.0);
      t.view.padding = pad;
      t.view.viewPadding = pad;
    }
    addTearDown(t.view.reset);
    final key = GlobalKey();
    final sport = SportType.values.firstWhere((s) => s.name == _sport);
    final state = TacticsState(sportType: sport);
    await t.runAsync(PlayerArt.warm);
    await t.runAsync(CourtArt.warm);
    List drills = const [];
    await t.runAsync(() async {
      drills = await DrillLibraryService.instance.forSport(sport);
    });
    final drill = drills.firstWhere((d) => d.id == _drill);
    state.loadFromJson(Map<String, dynamic>.from(drill.board));
    state.setShowMoveLines(true);
    // The way a tool shoots a beat — render_boards.dart does the same.
    // stepForward() starts an animation the board has to play through, and
    // with nothing pumping frames every call after the first was ignored.
    if (_step > 0) state.setTargetStep(_step);

    await t.pumpWidget(EasyLocalization(
      supportedLocales: kLocales,
      path: 'assets/translations',
      saveLocale: false,
      startLocale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      child: Builder(builder: (ctx) => MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: ctx.localizationDelegates,
        supportedLocales: ctx.supportedLocales,
        theme: ThemeData(brightness: Brightness.dark),
        home: ChangeNotifierProvider<TacticsState>.value(
          value: state,
          child: RepaintBoundary(
            key: key,
            child: _rail
                ? Builder(builder: (c) => MediaQuery(
                    data: MediaQuery.of(c).copyWith(
                        size: const Size(1366, 599)),
                    child: const TacticsBoardHomePage()))
                : const TacticsBoardHomePage(),
          ),
        ),
      )),
    ));
    await t.pumpAndSettle();
    // The ball and the equipment are bitmaps decoded off the main thread;
    // shot straight after settle they came out as flat discs. Two seconds
    // is more than any of them takes.
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await t.pump();
    await t.runAsync(() async {
      final ro = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await ro.toImage(pixelRatio: 2.0);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('/private/tmp/claude-501/-Users-zhenyusong-projects-board100/f8f07df9-0abc-4cbc-a570-256f66abef17/scratchpad/$_out'
              '${_rail ? '_rail' : ''}.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('PREVIEW written');
  });
}
