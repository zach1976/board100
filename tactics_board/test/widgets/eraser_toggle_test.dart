import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/ui/tokens.dart';
import 'package:tactics_board/widgets/toolbar.dart';

import 'overflow_test.dart' show kLocales;

/// The eraser is a mode, not a filter: while it is on, every tap on the
/// board deletes a line. It used to say so with a 12%-opacity wash that a
/// coach could not see, so this pins the two things that make it readable —
/// a solid fill, and a label that is not the same colour as the one next
/// to it that is off.
void main() {
  testWidgets('the eraser looks on when it is on', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState(sportType: SportType.volleyball);
    state.setDrawingMode(true);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              backgroundColor: T.bg0,
              // The bar takes the state as a plain field; in the app a
              // Consumer above it is what rebuilds it.
              body: Center(
                child: ListenableBuilder(
                  listenable: state,
                  builder: (_, __) => DrawingOptionsBar(state: state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final label = find.text('eraser'.tr());
    expect(label, findsOneWidget);

    Color fill() => tester
        .widgetList<Material>(
            find.ancestor(of: label, matching: find.byType(Material)))
        .first
        .color!;
    Color ink() => tester.widget<Text>(label).style!.color!;

    expect(fill(), T.surfaceHi, reason: 'off is the panel surface');
    final offInk = ink();

    await tester.tap(label);
    await tester.pumpAndSettle();

    expect(state.eraserMode, isTrue);
    expect(fill(), T.toolOn,
        reason: 'on is a solid fill, the way the active tool is solid');
    expect(ink(), isNot(offInk),
        reason: 'the words change colour too, not only the box');
    // 44 is the row height next to it: the two controls line up.
    expect(tester.getSize(find.byWidget(
            tester.widget(find.ancestor(
                of: label, matching: find.byType(AnimatedContainer))))).height,
        T.tap);
  });
}
