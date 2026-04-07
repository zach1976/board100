import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tactics_board/main.dart' as app;

/// Takes App Store screenshots by automating the UI flow.
/// Run with: flutter test integration_test/screenshot_test.dart -d 6BA0E025-...
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> screenshot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot('screenshot_$name');
  }

  testWidgets('App Store screenshot flow - badminton', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 1. Initial page (badminton court, empty)
    await screenshot(tester, '01_initial');

    // 2. Tap "+ 添加" / "+ Add Player" button
    final addBtns = find.byIcon(Icons.add);
    if (addBtns.evaluate().isNotEmpty) {
      await tester.tap(addBtns.first);
      await tester.pumpAndSettle();
      await screenshot(tester, '02_add_menu');

      // 3. Tap "双打" formation card (doubles)
      // Find text containing "双打" or "Doubles"
      Finder? formationFinder;
      for (final text in ['双打', 'Doubles', 'formation_doubles']) {
        final f = find.text(text);
        if (f.evaluate().isNotEmpty) {
          formationFinder = f;
          break;
        }
      }
      if (formationFinder != null) {
        await tester.tap(formationFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await screenshot(tester, '03_formation_applied');
      } else {
        // Close bottom sheet
        await tester.tapAt(const Offset(200, 100));
        await tester.pumpAndSettle();
      }
    }

    // 4. Add moves: select player 1, tap 3 positions
    await tester.pumpAndSettle();
    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    final w = screenSize.width;
    final h = screenSize.height;

    // Tap on player 1 area (bottom half of court, left side)
    await tester.tapAt(Offset(w * 0.35, h * 0.65));
    await tester.pumpAndSettle();

    // Add 3 moves for player 1
    await tester.tapAt(Offset(w * 0.5, h * 0.55));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(w * 0.65, h * 0.45));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(w * 0.4, h * 0.40));
    await tester.pumpAndSettle();

    await screenshot(tester, '04_player1_moves');

    // Tap on player 2 area (bottom half, right side)
    await tester.tapAt(Offset(w * 0.65, h * 0.72));
    await tester.pumpAndSettle();

    // Add 3 moves for player 2
    await tester.tapAt(Offset(w * 0.45, h * 0.60));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(w * 0.3, h * 0.50));
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(w * 0.55, h * 0.45));
    await tester.pumpAndSettle();

    await screenshot(tester, '05_both_moves');

    // 5. Open timeline editor
    final timelineBtn = find.byIcon(Icons.view_timeline);
    if (timelineBtn.evaluate().isNotEmpty) {
      await tester.tap(timelineBtn.first);
      await tester.pumpAndSettle();
      await screenshot(tester, '06_timeline');

      // Close timeline by tapping outside
      await tester.tapAt(Offset(w * 0.5, h * 0.3));
      await tester.pumpAndSettle();
    }

    // 6. Step forward
    final stepFwd = find.byIcon(Icons.skip_next);
    if (stepFwd.evaluate().isNotEmpty) {
      await tester.tap(stepFwd.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await screenshot(tester, '07_step_play');

      // One more step
      await tester.tap(stepFwd.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await screenshot(tester, '08_step2');
    }

    // 7. Save
    final saveBtn = find.byIcon(Icons.save_outlined);
    if (saveBtn.evaluate().isNotEmpty) {
      await tester.tap(saveBtn.first);
      await tester.pumpAndSettle();
      await screenshot(tester, '09_save');

      // Close save sheet
      await tester.tapAt(Offset(w * 0.5, h * 0.2));
      await tester.pumpAndSettle();
    }

    // 8. Share
    final shareBtn = find.byIcon(Icons.ios_share);
    if (shareBtn.evaluate().isNotEmpty) {
      // Just screenshot the board before share (share opens native dialog)
      await screenshot(tester, '10_before_share');
    }
  });
}
