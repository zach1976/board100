import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/ui/tokens.dart';
import 'package:tactics_board/widgets/toolbar.dart';

import 'overflow_test.dart' show kLocales;

/// A line that is already on the board can be restyled.
///
/// The palette only ever set what the NEXT line would look like: a coach who
/// wanted a thicker line had to delete the one they had drawn and draw it
/// again. `updateStroke` was written for this and had no callers.
void main() {
  testWidgets('the slider thickens the line that is picked out',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState(sportType: SportType.volleyball);
    state.setDrawingMode(true);
    state.setStrokeWidth(1);
    state.startStroke(const Offset(40, 40));
    state.addPoint(const Offset(200, 40));
    state.endStroke();
    final id = state.strokes.single.id;
    state.selectStroke(id);

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

    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    final box = tester.getRect(slider);

    // Drag the thumb from its left end to the right end: 1 → 8.
    final gesture = await tester.startGesture(
        Offset(box.left + 12, box.center.dy));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.moveTo(Offset(box.right - 4, box.center.dy));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(state.strokeWidth, 8, reason: 'the pen is set for the next line');
    expect(state.strokes.single.width, 8,
        reason: 'and the line that is picked out thickens with it');

    // One drag of seven divisions is one step of undo, not seven.
    state.undo();
    expect(state.strokes.single.width, 1);

    // A colour dot takes the picked-out line too.
    state.selectStroke(id);
    await tester.pumpAndSettle();
    final before = state.strokes.single.color;
    final dots = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle);
    await tester.tap(dots.at(2), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(state.strokes.single.color, isNot(before),
        reason: 'the colour lands on the line, not only on the pen');
  });
}
