import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:tactics_board/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final locales = {
    'en-US': const Locale('en', 'US'),
    'zh-Hans': const Locale('zh', 'CN'),
    'zh-Hant': const Locale('zh', 'TW'),
    'ja': const Locale('ja', 'JP'),
    'ko': const Locale('ko', 'KR'),
  };

  Future<void> snap(String name) async {
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot(name);
  }

  for (final entry in locales.entries) {
    final storeLang = entry.key;
    final locale = entry.value;

    testWidgets('Screenshots: badminton $storeLang', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Switch language
      final ctx = tester.element(find.byType(MaterialApp));
      ctx.setLocale(locale);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 1. Initial empty court
      await snap('badminton_${storeLang}_01_initial');

      // 2. Tap Add Player button
      final addBtn = find.byIcon(Icons.add);
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn.first);
        await tester.pumpAndSettle();
        await snap('badminton_${storeLang}_02_add_menu');

        // 3. Tap doubles/formation
        // Find the first tappable card in the formation row
        final formationCards = find.byType(GestureDetector);
        // Close bottom sheet
        await tester.tapAt(const Offset(200, 100));
        await tester.pumpAndSettle();
      }

      // Take final screenshot
      await snap('badminton_${storeLang}_03_final');
    });
  }
}
