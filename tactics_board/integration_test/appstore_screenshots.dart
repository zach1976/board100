import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const sportName = String.fromEnvironment('SPORT', defaultValue: 'badminton');

  Future<void> snap(String name) async {
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot(name);
  }

  testWidgets('$sportName screenshots all languages', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final locales = [
      ('en-US', const Locale('en', 'US')),
      ('zh-Hans', const Locale('zh', 'CN')),
      ('ja', const Locale('ja', 'JP')),
      ('ko', const Locale('ko', 'KR')),
      ('zh-Hant', const Locale('zh', 'TW')),
    ];

    for (final (storeLang, locale) in locales) {
      // Get state
      final ctx = tester.element(find.byType(Scaffold).first);
      final state = Provider.of<TacticsState>(ctx, listen: false);

      // Switch language
      ctx.setLocale(locale);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Clear everything for fresh state
      state.clearAll();
      state.clearAnimatedPositions();
      await tester.pumpAndSettle();

      // ── 1: Empty court ──
      await snap('${sportName}_${storeLang}_01_empty');

      // ── 2: Apply formation ──
      final formations = state.sportType.formations;
      if (formations.isNotEmpty) {
        state.applyFormation(formations.first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }
      await snap('${sportName}_${storeLang}_02_formation');

      // ── 3: Add moves ──
      final homePlayers = state.players.where((p) => p.team == PlayerTeam.home).toList();
      if (homePlayers.isNotEmpty) {
        final cs = state.canvasSize;
        state.addPlayerMove(homePlayers[0].id, Offset(cs.width * 0.5, cs.height * 0.55));
        state.addPlayerMove(homePlayers[0].id, Offset(cs.width * 0.65, cs.height * 0.45));
        state.addPlayerMove(homePlayers[0].id, Offset(cs.width * 0.35, cs.height * 0.40));
        if (homePlayers.length >= 2) {
          state.addPlayerMove(homePlayers[1].id, Offset(cs.width * 0.4, cs.height * 0.60));
          state.addPlayerMove(homePlayers[1].id, Offset(cs.width * 0.55, cs.height * 0.50));
        }
      }
      state.selectPlayer(null);
      await tester.pumpAndSettle();
      await snap('${sportName}_${storeLang}_03_moves');

      // ── 4: Step play ──
      if (state.hasMoves) {
        state.startAnimation();
        await tester.pumpAndSettle(const Duration(seconds: 2));
        state.stopAnimation();
        await tester.pumpAndSettle();
        await snap('${sportName}_${storeLang}_04_playing');
      }

      // ── 5: Drawing mode ──
      state.clearAnimatedPositions();
      state.setDrawingMode(true);
      await tester.pumpAndSettle();
      await snap('${sportName}_${storeLang}_05_draw_mode');
      state.setDrawingMode(false);
      await tester.pumpAndSettle();

      debugPrint('✅ $sportName/$storeLang done');
    }
  });
}
