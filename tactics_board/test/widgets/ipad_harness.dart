import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/drill_note.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';

import 'overflow_test.dart' show kLocales;


/// Shared harness for the iPad board tests (audit 2026-10-11).
///
/// One pumpWidget per test file: only the first EasyLocalization in a file
/// loads (see text_element_taps_test.dart), so each file is one test that
/// walks its scenarios in order, resizing the view where it needs a phone.
const kPro = Size(1032, 1376);
const kPhone = Size(402, 874);

Future<TacticsState> pumpBoard(WidgetTester tester, Size size,
    {SportType sport = SportType.soccer, String drillId = 'rondo_4v2'}) async {
  SharedPreferences.setMockInitialValues(
      {'board_hint_seen': true, 'intro_seen': true, 'remove_ads_pro': true});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  final lib = jsonDecode(
          File('assets/drills/${sport.name}.json').readAsStringSync())
      as Map<String, dynamic>;
  final drill = (lib['drills'] as List)
      .map((d) => Drill.fromJson(Map<String, dynamic>.from(d as Map)))
      .firstWhere((d) => d.id == drillId);
  final state = TacticsState(sportType: sport);
  // The provider above the app, as main.dart has it, so sheets and
  // popovers on their own routes find the board's state.
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: kLocales,
      path: 'assets/translations',
      saveLocale: false,
      startLocale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      child: ChangeNotifierProvider<TacticsState>.value(
        value: state,
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: const TacticsBoardHomePage(),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  state.loadFromJson(Map<String, dynamic>.from(drill.board));
  state.openedDrill(DrillNote.parse(drill.localizedNote('en')).beats);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return state;
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A board point on the screen.
Offset onScreen(WidgetTester tester, Offset p) {
  final box = boardRepaintKey.currentContext!.findRenderObject() as RenderBox;
  return box.localToGlobal(p);
}

/// An empty spot of the board, clear of every element.
Offset emptySpot(TacticsState state) {
  final c = state.canvasSize;
  for (final f in [0.3, 0.5, 0.7, 0.4, 0.6]) {
    final p = Offset(c.width * 0.5, c.height * f);
    if (state.players.every((x) => (x.position - p).distance > 80)) return p;
  }
  return Offset(c.width * 0.5, c.height * 0.45);
}

