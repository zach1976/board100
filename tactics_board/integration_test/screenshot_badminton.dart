import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/pages/home_page.dart';

final outDir =
    '/Users/zhenyusong/Desktop/projects/board100/tactics_board/aso/screenshots_raw';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('badminton screenshots', (t) async {
    // Launch badminton with empty court
    await _launchSport(t, SportType.badminton);
    final state = _state(t);

    // ── S1: Initial empty court ──
    await _shot(binding, 'badminton_s1_initial');

    // ── S2: Tap add button → show bottom sheet ──
    final addBtn = find.byIcon(Icons.add);
    await t.tap(addBtn.first);
    await t.pumpAndSettle();
    await _shot(binding, 'badminton_s2_add_menu');

    // ── S3: Select doubles formation ──
    // Find formation card with "doubles" text
    final doublesText = find.text('formation_doubles'.tr());
    if (doublesText.evaluate().isEmpty) {
      // Fallback: tap the last formation card (doubles is last for badminton)
      final cards = find.byType(GestureDetector);
      // The formation cards are GestureDetectors inside the bottom sheet
      // Try to find by the formation name text directly
      final allText = find.textContaining(RegExp(r'doubles|双打|ダブルス|복식'));
      if (allText.evaluate().isNotEmpty) {
        await t.tap(allText.first);
      } else {
        // Programmatic fallback
        Navigator.of(t.element(find.byType(Scaffold).first)).pop();
        await t.pumpAndSettle();
        state.applyFormation(SportType.badminton.formations[1]); // doubles
      }
    } else {
      await t.tap(doublesText.first);
    }
    await t.pumpAndSettle();
    await _shot(binding, 'badminton_s3_formation');

    // ── S4: Add moves — player 1 gets 3 waypoints, player 2 gets 3 waypoints ──
    final canvas = state.canvasSize;
    final home = state.players.where((p) => p.team == PlayerTeam.home).toList();
    assert(home.length >= 2, 'Expected 2 home players for doubles');

    // Select player 1 and add 3 moves (left side, moving forward)
    state.selectPlayer(home[0].id);
    state.addPlayerMove(home[0].id, Offset(0.30 * canvas.width, 0.72 * canvas.height));
    state.addPlayerMove(home[0].id, Offset(0.25 * canvas.width, 0.64 * canvas.height));
    state.addPlayerMove(home[0].id, Offset(0.30 * canvas.width, 0.56 * canvas.height));

    // Select player 2 and add 3 moves (right side, moving forward)
    state.selectPlayer(home[1].id);
    state.addPlayerMove(home[1].id, Offset(0.70 * canvas.width, 0.62 * canvas.height));
    state.addPlayerMove(home[1].id, Offset(0.72 * canvas.width, 0.55 * canvas.height));
    state.addPlayerMove(home[1].id, Offset(0.68 * canvas.width, 0.52 * canvas.height));

    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'badminton_s4_moves');

    // ── S5: Open timeline editor and rearrange so one player moves per step ──
    // By default, both players' moves are in phases 0,1,2 (concurrent).
    // Rearrange: P1 move0=phase0, P2 move0=phase1, P1 move1=phase2, P2 move1=phase3, etc.
    state.setMovePhase(home[0].id, 0, 0); // P1 move 1 → phase 0
    state.setMovePhase(home[1].id, 0, 1); // P2 move 1 → phase 1
    state.setMovePhase(home[0].id, 1, 2); // P1 move 2 → phase 2
    state.setMovePhase(home[1].id, 1, 3); // P2 move 2 → phase 3
    state.setMovePhase(home[0].id, 2, 4); // P1 move 3 → phase 4
    state.setMovePhase(home[1].id, 2, 5); // P2 move 3 → phase 5
    await t.pumpAndSettle();

    // Now open the timeline editor to screenshot it
    final timelineBtn = find.byIcon(Icons.view_timeline);
    await t.tap(timelineBtn.first);
    await t.pumpAndSettle();
    await _shot(binding, 'badminton_s5_timeline');

    // Close the timeline bottom sheet
    // Tap outside the bottom sheet to dismiss
    await t.tapAt(const Offset(200, 100));
    await t.pumpAndSettle();

    // ── S6: Step-by-step playback — show after a few steps ──
    // Use programmatic step to avoid animation timing conflicts
    state.stepForward();
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    state.finishAnimation();
    await t.pump(const Duration(milliseconds: 100));
    state.stepForward();
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    state.finishAnimation();
    await t.pump(const Duration(milliseconds: 100));
    await _shot(binding, 'badminton_s6_playback');
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> _launchSport(WidgetTester t, SportType sport) async {
  await EasyLocalization.ensureInitialized();
  await t.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: const Locale('en', 'US'),
      child: Builder(builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => TacticsState(sportType: sport),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: const Locale('en', 'US'),
            theme: _theme(),
            home: const TacticsBoardHomePage(),
          ),
        );
      }),
    ),
  );
  await t.pumpAndSettle();
}

ThemeData _theme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      sliderTheme: const SliderThemeData(
        thumbColor: Colors.blue,
        activeTrackColor: Colors.blue,
        inactiveTrackColor: Colors.white24,
      ),
    );

TacticsState _state(WidgetTester t) {
  final ctx = t.element(find.byType(TacticsBoardHomePage));
  return Provider.of<TacticsState>(ctx, listen: false);
}

Future<void> _shot(
    IntegrationTestWidgetsFlutterBinding b, String name) async {
  await b.convertFlutterSurfaceToImage();
  await Future.delayed(const Duration(milliseconds: 300));
  final bytes = await b.takeScreenshot(name);
  final f = File('$outDir/$name.png');
  await f.writeAsBytes(bytes);
  print('📸 $name (${(bytes.length / 1024).toStringAsFixed(0)} KB)');
}
