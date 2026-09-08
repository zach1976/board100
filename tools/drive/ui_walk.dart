import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// __PACKAGE__ is replaced with the app's own package name by tools/drive_app.sh,
// so this walks the shell's real main() — the part that picks the sport.
import 'package:__PACKAGE__/main.dart' as app;

/// A guided walk through one app on a simulator, for looking at it.
///
/// Not a release test: it exists so an app can be opened and its screens
/// browsed without anyone touching the mouse, leaving a screenshot per step
/// in <App>/screenshots/.
///
///   tools/drive_app.sh <sport-key>
///
/// Share and login are deliberately skipped: both hand off to the platform,
/// and a system sheet is not this app's screen to photograph.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('walk the main screens', (tester) async {
    // Suppress ads for the walk from inside the installed app, before main()
    // reads it — flutter drive reinstalls and wipes any plist written from
    // the shell, but a pref set here lives in the same process it launches.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remove_ads_pro', true);
    // Start on a clean board so the first-run coach mark is in the shot.
    await prefs.setBool('board_hint_seen', false);
    app.main();

    /// Settle by the clock, not by pumpAndSettle: a spinner or an ad makes
    /// that give up, and the splash needs real time.
    Future<void> settle([int beats = 12]) async {
      for (var i = 0; i < beats; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    /// Tap something if it is there, and say whether it was.
    Future<bool> tapIcon(IconData icon, {bool last = false}) async {
      final f = find.byIcon(icon).hitTestable();
      if (f.evaluate().isEmpty) return false;
      await tester.tap(last ? f.last : f.first, warnIfMissed: false);
      await settle(8);
      return true;
    }

    /// Back to the board, whichever way this screen leaves.
    Future<void> home() async {
      for (var attempt = 0; attempt < 3; attempt++) {
        if (find.byIcon(Icons.more_horiz).hitTestable().evaluate().isNotEmpty) {
          return;
        }
        // Presentation mode hides the ⋯ button and has no back button; its
        // only way out is its own pill. Without this the walk stayed in
        // presentation for the rest of the run and shot it twice.
        final exit = find.text('Exit Presentation').hitTestable();
        if (exit.evaluate().isNotEmpty) {
          await tester.tap(exit.first, warnIfMissed: false);
          await settle(8);
          continue;
        }
        final back = find.byType(BackButton).hitTestable();
        if (back.evaluate().isNotEmpty) {
          await tester.tap(back.first, warnIfMissed: false);
          await settle(8);
        } else if (!await tapIcon(Icons.arrow_back) &&
            !await tapIcon(Icons.arrow_back_ios_new) &&
            !await tapIcon(Icons.close)) {
          await tester.tapAt(const Offset(8, 8));
          await settle(6);
        }
      }
    }

    /// Open the overflow menu and go to one of its entries.
    Future<bool> viaMenu(IconData entry) async {
      await home();
      if (!await tapIcon(Icons.more_horiz)) return false;
      return tapIcon(entry, last: true);
    }

    await settle(40);
    await binding.takeScreenshot('01-board');

    // The hub opens on the sport grid, a single-sport app straight onto its
    // board. On the hub, pick the first sport so the rest of the walk is the
    // same for both shapes.
    if (find.byIcon(Icons.more_horiz).evaluate().isEmpty) {
      if (!await tapIcon(Icons.arrow_forward_ios_rounded)) {
        await binding.takeScreenshot('02-no-board');
        return;
      }
      await binding.takeScreenshot('02-picked-sport');
      if (find.byIcon(Icons.more_horiz).evaluate().isEmpty) return;
    }

    await tapIcon(Icons.more_horiz);
    await binding.takeScreenshot('02-menu');

    // ── the board's own tools, before a drill is loaded: once one is, the
    // bottom bar becomes the playback controls and the mode tabs are gone
    // for the rest of the walk.
    await home();
    if (await tapIcon(Icons.add_rounded)) {
      await binding.takeScreenshot('03-add-element');
      await home();
    }
    if (await tapIcon(Icons.gesture_rounded)) {
      await binding.takeScreenshot('04-draw-tools');
      await tapIcon(Icons.open_with_rounded);          // back to move mode
    }

    // ── the drill library ────────────────────────────────────────────────
    // Through the menu, not by looking for the icon: the toolbar steps above
    // close the menu behind them, and a bare tapIcon then finds nothing.
    if (await viaMenu(Icons.menu_book_outlined)) {
      await settle(20);
      await binding.takeScreenshot('05-drills');
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await settle(6);
      await binding.takeScreenshot('06-drills-scrolled');

      // Load a drill onto the board. A family card offers a chip per
      // variant; a drill that stands alone offers the round button.
      // The circled + is the drill card's own button; plain add_rounded is
      // the toolbar's add tool, so look for the card's first.
      var play = find.byIcon(Icons.add_circle_outline).hitTestable();
      if (play.evaluate().isEmpty) {
        play = find.byIcon(Icons.add_rounded).hitTestable();
      }
      if (play.evaluate().isNotEmpty) {
        await tester.tap(play.first, warnIfMissed: false);
        await settle(14);
        await binding.takeScreenshot('07-drill-on-the-board');
      }
    }

    // ── the sheets behind the menu ───────────────────────────────────────
    if (await viaMenu(Icons.grass_outlined)) {
      await binding.takeScreenshot('08-pitch');
    }
    if (await viaMenu(Icons.event_note_outlined)) {
      await settle(10);
      await binding.takeScreenshot('09-practice-plan');
      // History lives on the plan page's own bar.
      if (await tapIcon(Icons.history_rounded)) {
        await settle(10);
        await binding.takeScreenshot('10-practice-history');
      }
    }
    if (await viaMenu(Icons.language_rounded)) {
      await binding.takeScreenshot('11-language');
    }
    if (await viaMenu(Icons.co_present_outlined)) {
      await settle(10);
      await binding.takeScreenshot('12-presentation');
    }
    await home();
    await binding.takeScreenshot('13-board-with-play');
  });
}
