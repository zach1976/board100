import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soccer_board/main.dart' as app;

/// A guided walk through the real app on a real simulator, for looking at it.
///
/// This is not a release test — it exists so the drill library can be opened,
/// searched and loaded without anyone touching the mouse, and so each step
/// leaves a screenshot behind in SoccerBoard/screenshots/.
///
///   tools/drive_soccer.sh
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open the drill library, search it, put a drill on the board',
      (tester) async {
    app.main();
    // The app-open ad and the splash both need real time to clear, and
    // pumpAndSettle would give up on the spinner, so settle by the clock.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await binding.takeScreenshot('01-board');

    // The library lives behind the overflow menu, top right.
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02-menu');

    await tester.tap(find.byIcon(Icons.menu_book_outlined).last);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await binding.takeScreenshot('03-library');

    // Scroll down the list — 119 drills is the point of the exercise.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04-library-scrolled');

    // Search, which is what makes a list this long usable.
    await tester.enterText(find.byType(TextField), 'corner');
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05-search-corner');

    // Load whatever the search turned up, and look at it on the board. Rows
    // carry a play icon; locked ones carry a lock instead.
    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await binding.takeScreenshot('06-drill-loaded');
  });
}
