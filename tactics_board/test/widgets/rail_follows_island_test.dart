import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

import 'overflow_test.dart' show kLocales;

/// Sideways, the rail sits on the Dynamic Island's side so the pill lies
/// over the rail and never over the board (reported 2026-10-10: a server
/// behind the end line was hidden under the island).
void main() {
  testWidgets('the landscape rail goes to the island side', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(
        {'board_hint_seen': true, 'intro_seen': true, 'remove_ads_pro': true});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(874 * 3, 402 * 3);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding =
        const FakeViewPadding(left: 59 * 3, right: 59 * 3, bottom: 21 * 3);
    addTearDown(tester.view.reset);
    addTearDown(() => IslandSide.side.value = 'none');

    final state = TacticsState(sportType: SportType.volleyball);
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
            home: ChangeNotifierProvider<TacticsState>.value(
              value: state,
              child: const TacticsBoardHomePage(),
            ),
          ),
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // The Move button is the rail's first row.
    Rect board() => tester.getRect(find.byType(TacticsCanvas).first);
    Rect move() => tester.getRect(find.text('Move').first);

    for (final side in ['none', 'right', 'left']) {
      IslandSide.side.value = side;
      await settle();
      if (side == 'left') {
        expect(move().right, lessThan(board().left), reason: side);
      } else {
        expect(move().left, greaterThan(board().right), reason: side);
      }
      expect(tester.takeException(), isNull, reason: side);
    }
  });
}
