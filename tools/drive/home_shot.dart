import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/pages/intro_page.dart';
import 'package:tactics_board/services/ad_service.dart';
import 'package:__PACKAGE__/main.dart' as app;

/// Photographs the home screen, which is where the hero and the nine drill
/// covers actually have to hold up.
///
///   WALK=home_shot tools/drive_app.sh soccer <udid>
///
/// The two prefs are set in this process on purpose. Writing them into the
/// simulator's NSUserDefaults from outside does not work: `defaults write`
/// lands in cfprefsd's cache, the app still reads the snapshot it had, and
/// the key is gone from the plist again once the app writes anything of its
/// own. A pref set here is set in the process that reads it.
///
/// Leaves <App>/screenshots/sim-home-*.png.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('photograph the home screen', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remove_ads_pro', true);
    await IntroPage.markSeen(); // the intro owns the first launch otherwise

    app.main();
    // Same latch board_shot needs: the Pro pref is read asynchronously and
    // the app-open ad fires on its own timer, so without this the shot comes
    // back as an App Store page.
    AdService.instance.pushAdSuppression();

    Future<void> settle([int beats = 12]) async {
      for (var i = 0; i < beats; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    await settle(25);
    await binding.takeScreenshot('sim-home-top');

    // Down the page: the drill cards carry the covers, and the category grid
    // and "my boards" sit below the fold on a phone.
    final scrollable = find.byType(Scrollable).first;
    for (var i = 1; i <= 3; i++) {
      await tester.drag(scrollable, const Offset(0, -420));
      await settle(8);
      await binding.takeScreenshot('sim-home-$i');
    }
  });
}
