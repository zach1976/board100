import 'dart:io';
import 'dart:ui' as ui show TextDirection;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/drill_detail_page.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/ui/primitives.dart';
import 'package:tactics_board/ui/tokens.dart';

import 'overflow_test.dart' show kLocales;

/// The drill page's main action keeps its name in every language.
///
/// "Put it on the b…" on an iPhone 17 Pro: the primary button beside "Add
/// to plan" had 145pt for a label that needed 158. The button now shrinks a
/// label before it truncates, but shrinking is the backstop, not the plan —
/// this asserts that on the main phone width every locale's label fits at
/// full size, so the backstop is never what a coach sees.
const kMeasureFace = 'MeasureFace';
bool haveFace = false;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('the primary label fits at full size in every locale',
      (tester) async {
    await EasyLocalization.ensureInitialized();
    // iPhone 17 Pro, the phone in the screenshot.
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    late final List<Drill> drills;
    await tester.runAsync(() async {
      drills = await DrillLibraryService.instance.forSport(SportType.soccer);
      // flutter_test draws every glyph as a 1em square (Ahem), which makes
      // "Put on the board" 272pt wide — no label would pass. Measure with a
      // real face instead. Arial Unicode covers every script in kLocales and
      // runs a little wider than the iPhone's SF Pro, so a pass here is
      // conservative. Skipped, not failed, on a machine without it.
      final f = File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf');
      if (await f.exists()) {
        final loader = FontLoader(kMeasureFace)
          ..addFont(f.readAsBytes().then((b) => b.buffer.asByteData()));
        await loader.load();
        haveFace = true;
      }
    });
    if (!haveFace) {
      markTestSkipped('no Arial Unicode on this machine to measure with');
      return;
    }
    final drill = drills.first;

    late BuildContext ctx;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) {
            ctx = context;
            return MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: DrillDetailPage(
                drill: drill,
                sportType: SportType.soccer,
                locale: 'en',
                onLoad: () {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final failures = <String>[];
    for (final locale in kLocales) {
      await ctx.setLocale(locale);
      await tester.pumpAndSettle();

      final label = 'drills_put_on_board'.tr();
      final button = find.widgetWithText(TacticalButton, label);
      expect(button, findsOneWidget, reason: '$locale: the primary is there');

      // What the label needs, unconstrained, at the button's own style.
      final painter = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(
                fontFamily: kMeasureFace,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        maxLines: 1,
        // easy_localization re-exports intl's TextDirection over dart:ui's.
        textDirection: ui.TextDirection.ltr,
      )..layout();
      // What the button gives it: its width less the padding and the icon.
      final available = tester.getSize(button).width -
          2 * T.s20 -
          (T.iLg + T.s8);
      // One line per locale, so a run shows the margins and not just a verdict.
      debugPrint('label-width ${locale.toString().padRight(5)} '
          '${painter.width.round().toString().padLeft(3)}/${available.round()}pt  "$label"');
      if (painter.width > available) {
        failures.add('$locale "$label" needs ${painter.width.round()}pt, '
            'has ${available.round()}pt');
      }
    }
    expect(failures, isEmpty,
        reason: 'these labels would be shrunk or cut:\n${failures.join('\n')}');
  });
}
