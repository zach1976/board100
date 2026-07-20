import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // TacticsBoardApp reads context.localizationDelegates, so it must be built
    // under an EasyLocalization ancestor (mirrors main()).
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en', 'US')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: const TacticsBoardApp(),
      ),
    );
    await tester.pumpAndSettle();

    // It rendered an app without throwing during build.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
