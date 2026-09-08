import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/services/ad_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:__PACKAGE__/main.dart' as app;

import 'dart:convert';

/// Photographs one drill on a real simulator, one shot per phase.
///
/// This exists to answer a single question: does the offline renderer that
/// feeds the review page draw the same board the phone draws? The page is
/// there so drills can be corrected, and correcting a board you are not
/// actually looking at is worse than not reviewing at all — so the two have
/// to be checked against each other before anyone trusts the page.
///
///   DRILL=passing_diamond WALK=board_shot tools/drive_app.sh soccer <udid>
///
/// Leaves <App>/screenshots/sim-<id>-<step>.png next to the walk's own shots.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('photograph one drill phase by phase', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remove_ads_pro', true);

    app.main();
    // The Pro pref alone is not enough: PurchaseService reads it
    // asynchronously and the app-open ad fires on its own timer, so on a
    // second launch the same day the ad won every race and every shot came
    // back as an App Store page instead of a board. This is the same latch
    // presentation mode holds, and it is checked synchronously.
    AdService.instance.pushAdSuppression();
    Future<void> settle([int beats = 12]) async {
      for (var i = 0; i < beats; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    await settle(20);

    const id = String.fromEnvironment('DRILL', defaultValue: 'passing_diamond');
    final raw = await rootBundle
        .loadString('packages/tactics_board/assets/drills/soccer.json');
    final drills = (jsonDecode(raw) as Map<String, dynamic>)['drills'] as List;
    final drill = drills.firstWhere((d) => d['id'] == id);

    // Reach the live TacticsState the board is already using, rather than
    // making a second one — the point is to photograph the real screen.
    final ctx = tester.element(find.byType(Scaffold).first);
    final state = Provider.of<TacticsState>(ctx, listen: false);
    state.loadFromJson(Map<String, dynamic>.from(drill['board'] as Map));
    await settle(10);

    for (var step = 0; step <= state.maxMoveSteps; step++) {
      state.setTargetStep(step);
      await settle(8);
      await binding.takeScreenshot('sim-$id-$step');
    }
  });
}
