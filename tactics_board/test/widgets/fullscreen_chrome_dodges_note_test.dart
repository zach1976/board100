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

/// Fullscreen's floating corner buttons keep off the drill's step note.
///
/// Reported 2026-10-10 on a volleyball drill: in fullscreen the back-a-beat,
/// play and forward-a-beat circles sat in the band under the court, which
/// is where the note is placed, and covered the sentence they step through.
void main() {
  testWidgets('fullscreen beat controls do not cover the step note',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(
        {'board_hint_seen': true, 'intro_seen': true, 'remove_ads_pro': true});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final lib = jsonDecode(
            File('assets/drills/volleyball.json').readAsStringSync())
        as Map<String, dynamic>;
    final drill = (lib['drills'] as List)
        .map((d) => Drill.fromJson(Map<String, dynamic>.from(d as Map)))
        .firstWhere((d) =>
            DrillNote.parse(d.localizedNote('en')).beats.length >= 2);

    final state = TacticsState(sportType: SportType.volleyball);
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
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    state.loadFromJson(Map<String, dynamic>.from(drill.board));
    state.openedDrill(DrillNote.parse(drill.localizedNote('en')).beats);
    state.toggleToolbar();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final chips = textChipsOnScreen();
    expect(chips, isNotEmpty, reason: 'the step note was not placed');
    final circles = [
      Icons.chevron_left_rounded,
      Icons.play_arrow_rounded,
      Icons.chevron_right_rounded,
      Icons.fullscreen_exit,
    ].map((i) => tester.getRect(find.byIcon(i).last));
    for (final icon in circles) {
      // The glass circle round the glyph, not just the glyph.
      final circle = Rect.fromCenter(
          center: icon.center, width: 44, height: 44);
      for (final chip in chips) {
        final o = circle.intersect(chip);
        expect(o.width <= 0 || o.height <= 0, isTrue,
            reason: 'circle $circle covers note $chip');
      }
    }
  });
}
