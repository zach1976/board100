import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/models/volleyball_rotation.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';
import 'package:tactics_board/widgets/volleyball_rotation_widgets.dart';

import 'overflow_test.dart' show kLocales;

/// A volleyball rotation board shows an overlap on the board — and only
/// then: a legal six, a free drawing, or the check turned off show nothing.
/// And the Add sheet opens on its rotation controls, where one tap rotates.
///
/// One test, one pumpWidget: only the first EasyLocalization in a file
/// initialises.
void main() {
  testWidgets('an overlap is drawn on a rotation board, and rotating works',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(
        {'board_hint_seen': true, 'intro_seen': true, 'remove_ads_pro': true});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = TacticsState(sportType: SportType.volleyball);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: kLocales,
        path: 'assets/translations',
        saveLocale: false,
        startLocale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        // Above the app, as in main.dart: the Add sheet is its own route.
        child: ChangeNotifierProvider<TacticsState>.value(
          value: state,
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const TacticsBoardHomePage(),
            ),
          ),
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    await settle();
    final card = tester.getRect(find.byType(TacticsCanvas).first);
    state.setCanvasSizeSilent(card.size);
    final faultLayer = find.byKey(const ValueKey('rotation-faults'));

    // A free drawing is never judged, however it stands.
    state.addTeamFromFormation(
        SportType.volleyball.formations.first, PlayerTeam.home);
    state.movePlayer(state.players.last.id, state.players.first.position);
    await settle();
    expect(faultLayer, findsNothing);
    state.clearAll();

    // A rotation board, legal: nothing on it.
    state.applyRotation(const RotationSetup(libero: false));
    await settle();
    expect(faultLayer, findsNothing);

    // OH2 (zone 5) stepped in front of the opposite (zone 4): a fault.
    final oh2 = state.players.firstWhere((p) => p.role == 'OH2');
    final opp = state.players.firstWhere((p) => p.role == 'OPP');
    state.movePlayer(oh2.id, Offset(oh2.position.dx, opp.position.dy - 20));
    await settle();
    expect(faultLayer, findsOneWidget);
    final painter = tester.widget<CustomPaint>(faultLayer).painter
        as RotationFaultPainter;
    expect(painter.pairs, hasLength(1));
    expect(painter.message, 'Overlap: OPP must be in front of OH');

    // The check off: the board stops judging.
    state.setRotationCheck(false);
    await settle();
    expect(faultLayer, findsNothing);
    state.setRotationCheck(true);
    await settle();
    expect(faultLayer, findsOneWidget);

    // The Add sheet opens on the rotation controls; one tap rotates on.
    state.applyRotation(state.rotation!);
    await settle();
    expect(faultLayer, findsNothing);
    await tester.tap(find.byIcon(Icons.add_rounded).first, warnIfMissed: false);
    await settle();
    final forward = find.byKey(const ValueKey('rotation-forward'));
    await tester.ensureVisible(forward);
    await tester.tap(forward);
    await settle();
    expect(state.rotation!.rotation, 2);
    expect(state.rotationFaults(), isEmpty);
  });
}
