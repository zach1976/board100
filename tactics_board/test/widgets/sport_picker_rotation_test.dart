import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/pages/sport_selection_page.dart';
import 'package:tactics_board/state/tactics_state.dart';

import 'overflow_test.dart' show kLocales;

/// Turning an iPad on the sport picker keeps the coach where he was in the
/// list, both ways round, in one live page (not two separate pumps).
void main() {
  testWidgets('sport picker keeps its place through a rotation',
      (tester) async {
    SharedPreferences.setMockInitialValues({'intro_seen': true});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1032, 1376) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(EasyLocalization(
      supportedLocales: kLocales,
      path: 'assets/translations',
      saveLocale: false,
      startLocale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      child: Builder(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => TacticsState(),
          child: MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: const SportSelectionPage(),
          ),
        ),
      ),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();

    ScrollPosition pos() =>
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    double share() => pos().pixels / pos().maxScrollExtent;

    // Most of the way down, where a lost position is a lost screenful.
    pos().jumpTo(pos().maxScrollExtent * 0.7);
    await tester.pumpAndSettle();
    final before = share();
    expect(before, closeTo(0.7, 0.01));

    for (final size in const [Size(1376, 1032), Size(1032, 1376)]) {
      tester.view.physicalSize = size * 2;
      await tester.pumpAndSettle();
      expect(pos().maxScrollExtent, greaterThan(0), reason: '$size');
      expect(share(), closeTo(before, 0.02), reason: 'after turning to $size');
    }
  });
}
