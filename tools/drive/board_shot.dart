import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/ad_service.dart';
import 'package:tactics_board/services/drill_library_service.dart';
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
    // The three-panel intro, too. drive_app.sh reinstalls before every run,
    // so the app is always on a first launch and every shot came back as
    // the onboarding page rather than a board — which is why this script
    // had never actually produced a comparison.
    await prefs.setBool('intro_seen', true);
    await prefs.setBool('board_hint_seen', true);

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
    // The library of the sport this shell IS, through the service that
    // knows where a sport's drills live. Since the split into
    // packages/sport_<name>/ there is no soccer.json under the core, so
    // the old hardcoded path threw "unable to load asset" on every app —
    // including, ironically, soccer.
    final sport = ConfigConstants.fixedSportType ?? SportType.soccer;
    final drills = await DrillLibraryService.instance.forSport(sport);
    final drill = drills.firstWhere((d) => d.id == id,
        orElse: () => throw StateError(
            'drill "$id" not in ${sport.name} library of ${drills.length}'));

    // Onto the board. This script was written when a single-sport app
    // opened straight onto its pitch; it opens on a home page now, and
    // the shots were of that home page.
    //
    // By the tab widget itself. Not by icon — the same dashboard glyph is
    // on the home page's own "Open the board" button and on every drill
    // card, and tapping one of those opened a "Name this board" dialog.
    // Not by coordinate either: that missed. The bar is four _TabButton
    // widgets and the board is the second.
    final tabs = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_TabButton');
    if (tabs.evaluate().length >= 2) {
      await tester.tap(tabs.at(1), warnIfMissed: false);
      await settle(14);
    }
    // With no board saved, the Board tab asks for a name before it opens
    // one — see MainShell, which calls createNamedBoard rather than
    // dropping the coach onto an unnamed pitch. Accept the default.
    final confirm = find.text('Apply').hitTestable();
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm.first, warnIfMissed: false);
      await settle(14);
    }

    // Reach the live TacticsState the board is already using, rather than
    // making a second one — the point is to photograph the real screen.
    final ctx = tester.element(find.byType(Scaffold).first);
    final state = Provider.of<TacticsState>(ctx, listen: false);
    state.loadFromJson(Map<String, dynamic>.from(drill.board));
    await settle(10);

    for (var step = 0; step <= state.maxMoveSteps; step++) {
      state.setTargetStep(step);
      await settle(8);
      await binding.takeScreenshot('sim-$id-$step');
    }
  });
}
