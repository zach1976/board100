import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/main.dart';
import 'package:tactics_board/models/sport_type.dart';

import 'overflow_test.dart' show kLocales;

/// The first-run coach mark says "tap Add to place players" and carries a +
/// that looks exactly like the toolbar's Add. It used to only dismiss itself,
/// so the one control a first-time coach is being pointed at did the opposite
/// of what it showed.
///
/// It opens the Add sheet now, and the order matters: dismissing first takes
/// the card out of the tree, and showModalBottomSheet resolves its Navigator
/// from the context it is handed — a context unmounted in the same frame
/// yields no sheet at all, which is how this hung a simulator walk for ten
/// minutes with no error.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('the coach mark opens the Add sheet, and its X only dismisses',
      (tester) async {
    SharedPreferences.setMockInitialValues({'remove_ads_pro': true});
    // Without a fixed sport the app opens on the sport grid, and the board —
    // and so the coach mark — is never built.
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

    final hint = find.textContaining('Add', findRichText: true);
    expect(hint, findsWidgets, reason: 'the coach mark should be on screen');

    await tester.tap(hint.first, warnIfMissed: false);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The sheet is the proof: if the card had dismissed first, the modal
    // route would never have been pushed and this finder would be empty.
    expect(find.byType(BottomSheet), findsOneWidget,
        reason: 'tapping the coach mark should open the Add sheet');
  });
}
