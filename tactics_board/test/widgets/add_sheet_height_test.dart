import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/main.dart';
import 'package:tactics_board/models/sport_type.dart';

import 'overflow_test.dart' show kLocales;

/// The Add sheet has to open showing everything it holds.
///
/// TacticalSheet takes its child's height and only scrolls past its cap, so a
/// low cap does not produce a compact sheet — it produces one whose last
/// section is hidden behind a swipe. At 0.62 the My Teams group sat below the
/// fold on a 402x874 phone.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('the Add sheet opens with nothing left to scroll to',
      (tester) async {
    SharedPreferences.setMockInitialValues({'remove_ads_pro': true});
    ConfigConstants.fixedSportType = SportType.soccer;
    addTearDown(() => ConfigConstants.fixedSportType = null);
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: const TacticsBoardApp(),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.byIcon(Icons.add_rounded).first, warnIfMissed: false);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(BottomSheet), findsOneWidget);

    // Pick 11v11 first: the Formation row only appears once a count is
    // chosen, and it is what pushes the sheet past its cap. Measuring
    // without it measures a sheet the user never sees.
    await tester.tap(find.text('11v11').first, warnIfMissed: false);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('4-4-2'), findsWidgets,
        reason: 'the Formation row should be showing before measuring');

    // Expand My Teams — the group that was below the fold. The chevron is
    // the honest handle for it, and flipping to expand_less is the proof the
    // section actually opened: an earlier version of this test tapped a text
    // finder that matched nothing, so it measured the collapsed sheet, which
    // fits at any cap, and passed while the bug was still there.
    expect(find.byIcon(Icons.expand_more_rounded), findsWidgets);
    await tester.tap(find.byIcon(Icons.expand_more_rounded).first,
        warnIfMissed: false);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byIcon(Icons.expand_less_rounded), findsWidgets,
        reason: 'My Teams should be expanded before the height is measured');

    // maxScrollExtent is how much content sits outside the viewport. Zero
    // means every group is on screen at once.
    final sheetScroll = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(Scrollable),
    );
    var worst = 0.0;
    for (final e in sheetScroll.evaluate()) {
      final st = e as StatefulElement;
      final pos = (st.state as ScrollableState).position;
      if (pos.axis == Axis.vertical && pos.hasContentDimensions) {
        worst = worst > pos.maxScrollExtent ? worst : pos.maxScrollExtent;
      }
    }
    expect(worst, 0.0,
        reason: 'the Add sheet still hides $worst logical pixels of content '
            'below the fold on a 402x874 phone');
  });
}
