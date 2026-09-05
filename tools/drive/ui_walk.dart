import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// __PACKAGE__ is replaced with the app's own package name by tools/drive_app.sh,
// so this walks the shell's real main() — the part that picks the sport.
import 'package:__PACKAGE__/main.dart' as app;

/// A guided walk through one app on a simulator, for looking at it.
///
/// Not a release test: it exists so an app can be opened and its drill library
/// browsed without anyone touching the mouse, leaving a screenshot per step
/// in <App>/screenshots/.
///
///   tools/drive_app.sh <sport-key>
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open the board and the drill library', (tester) async {
    app.main();
    // The splash and any app-open ad need real time to clear, and
    // pumpAndSettle gives up on a spinner, so settle by the clock.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await binding.takeScreenshot('01-board');

    // The hub opens on the sport grid; a single-sport app opens on its board.
    // Either way the library lives behind the overflow menu.
    final menu = find.byIcon(Icons.more_horiz);
    if (menu.evaluate().isEmpty) {
      await binding.takeScreenshot('02-no-menu');
      return;
    }
    await tester.tap(menu.first);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02-menu');

    await tester.tap(find.byIcon(Icons.menu_book_outlined).last);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    // The category chips are the thing worth looking at: they are supposed to
    // be in this sport's words, not football's.
    await binding.takeScreenshot('03-library');

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04-library-scrolled');

    // Load the first drill and look at it on the board. A family card offers
    // a chip per variant; a drill that stands alone offers the round button.
    var play = find.byIcon(Icons.play_arrow_rounded);
    if (play.evaluate().isEmpty) play = find.byIcon(Icons.play_circle_outline);
    if (play.evaluate().isNotEmpty) {
      await tester.tap(play.first);
      await tester.pumpAndSettle();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await binding.takeScreenshot('05-drill-loaded');
    }
  });
}
