import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/models/volleyball_rotation.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/volleyball_rotation_widgets.dart';

import 'overflow_test.dart' show OverflowWatch, kLocales, kNarrow;

/// The rotation controls — rule set, substitutions, libero, overlap check
/// and the Fix positions button all showing — in every locale at the width
/// the Add sheet gives them on the narrowest phone.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('the rotation controls survive every locale on the narrowest phone',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = Size(kNarrow.width * 3, kNarrow.height * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final watch = OverflowWatch()..start();
    addTearDown(watch.stop);

    final state = TacticsState(sportType: SportType.volleyball);
    state.setCanvasSizeSilent(const Size(320, 560));
    state.applyRotation(const RotationSetup(libero: false));
    // An overlap, so the Fix positions button is on show.
    final oh2 = state.players.firstWhere((p) => p.role == 'OH2');
    final opp = state.players.firstWhere((p) => p.role == 'OPP');
    state.movePlayerEnd(oh2.id, Offset(oh2.position.dx, opp.position.dy - 20));
    expect(state.rotationFaults(), isNotEmpty);

    late BuildContext ctx;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        fallbackLocale: const Locale('en', 'US'),
        child: Builder(
          builder: (context) {
            ctx = context;
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                backgroundColor: Colors.black,
                body: Padding(
                  // The Add sheet's side padding.
                  padding: const EdgeInsets.all(16),
                  child: VolleyballRotationControls(
                    state: state,
                    team: PlayerTeam.home,
                    onPlace: () {},
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('rotation-fix')), findsOneWidget);
    expect(find.byKey(const ValueKey('rotation-rules')), findsOneWidget);

    final broken = <String>[];
    for (final locale in kLocales) {
      await ctx.setLocale(locale);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      broken.addAll(watch.drain('$locale'));
    }
    watch.check(broken);

    // The button does what it says, and goes away once the side is legal.
    await tester.tap(find.byKey(const ValueKey('rotation-fix')));
    await tester.pump();
    expect(state.rotationFaults(), isEmpty);
    expect(find.byKey(const ValueKey('rotation-fix')), findsNothing);
  });
}
