// Integration tests for the 2026-05 UX overhaul — drives the real app on a
// simulator and asserts the interaction flows that static screenshots can't
// cover (tap-to-deselect, add-run sub-mode, clear sheet, presentation lock,
// eraser, half-court, undo/redo, player edit bar).
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UX overhaul flows', () {
    testWidgets('1.0 board loads with the new toolbar', (t) async {
      await _launch(t);
      expect(find.byType(TacticsCanvas), findsOneWidget);
      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Draw'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);
      // Undo/Redo are now always present in the main toolbar.
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
    });

    testWidgets('1.1 tapping empty canvas deselects (no stray waypoint)',
        (t) async {
      await _launch(t);
      final s = _state(t);
      _addPlayer(s, 0.30, 0.25);
      await t.pumpAndSettle();
      expect(s.selectedPlayerId, isNotNull); // addPlayer auto-selects

      await t.tapAt(t.getRect(find.byType(TacticsCanvas)).center);
      await t.pumpAndSettle();

      expect(s.selectedPlayerId, isNull, reason: 'tap on empty should deselect');
      expect(s.players.first.moves, isEmpty,
          reason: 'tap on empty must NOT add a run waypoint');
    });

    testWidgets('1.1 add-run sub-mode: a tap appends a waypoint', (t) async {
      await _launch(t);
      final s = _state(t);
      _addPlayer(s, 0.30, 0.25);
      await t.pumpAndSettle();
      // Enter the explicit "Add Run" sub-mode via the player edit bar.
      expect(find.text('Add Run'), findsOneWidget);
      await t.tap(find.text('Add Run'));
      await t.pumpAndSettle();
      expect(s.isAddingMove, isTrue);
      expect(find.text('Done'), findsOneWidget); // toggle label flipped

      await t.tapAt(t.getRect(find.byType(TacticsCanvas)).center);
      await t.pumpAndSettle();
      expect(s.players.first.moves.length, 1,
          reason: 'tap in add-run mode appends one waypoint');
    });

    testWidgets('1.2 undo / redo from the main toolbar', (t) async {
      await _launch(t);
      final s = _state(t);
      _addPlayer(s, 0.4, 0.4);
      await t.pumpAndSettle();
      expect(s.players.length, 1);

      await t.tap(find.byIcon(Icons.undo));
      await t.pumpAndSettle();
      expect(s.players.length, 0, reason: 'undo removes the added player');

      await t.tap(find.byIcon(Icons.redo));
      await t.pumpAndSettle();
      expect(s.players.length, 1, reason: 'redo restores it');
    });

    testWidgets('1.3 clear offers two scopes; "Clear Lines" keeps players',
        (t) async {
      await _launch(t);
      final s = _state(t);
      _addPlayer(s, 0.4, 0.4);
      _addStroke(s);
      await t.pumpAndSettle();
      expect(s.strokes.length, 1);

      await t.tap(find.byIcon(Icons.delete_sweep));
      await t.pumpAndSettle();
      expect(find.text('Clear Lines'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);

      await t.tap(find.text('Clear Lines'));
      await t.pumpAndSettle();
      expect(s.strokes, isEmpty, reason: 'lines cleared');
      expect(s.players, isNotEmpty, reason: 'players kept');
    });

    testWidgets('1.4 presentation mode locks the board and hides the toolbar',
        (t) async {
      await _launch(t);
      final s = _state(t);

      await t.tap(find.byIcon(Icons.more_horiz));
      await t.pumpAndSettle();
      await t.tap(find.text('Presentation'));
      await t.pumpAndSettle();
      expect(s.presentationMode, isTrue);
      expect(find.text('Move'), findsNothing,
          reason: 'editing toolbar is hidden in presentation mode');
      expect(find.text('Exit Presentation'), findsOneWidget);

      await t.tap(find.text('Exit Presentation'));
      await t.pumpAndSettle();
      expect(s.presentationMode, isFalse);
      expect(find.text('Move'), findsOneWidget);
    });

    testWidgets('2.1 drawing mode exposes the eraser toggle', (t) async {
      await _launch(t);
      final s = _state(t);
      await t.tap(find.text('Draw'));
      await t.pumpAndSettle();
      expect(s.isDrawingMode, isTrue);

      final eraser = find.text('⌫ Eraser');
      expect(eraser, findsOneWidget);
      await t.ensureVisible(eraser);
      await t.pumpAndSettle();
      await t.tap(eraser);
      await t.pumpAndSettle();
      expect(s.eraserMode, isTrue);
    });

    testWidgets('2.2 selecting a player shows the unified edit bar', (t) async {
      await _launch(t);
      final s = _state(t);
      _addPlayer(s, 0.5, 0.3);
      await t.pumpAndSettle();
      // The floating edit bar appears inline — no extra gear tap.
      expect(find.text('Add Run'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsWidgets);
    });

    testWidgets('1.5 single-finger drag moves a player (no gesture conflict)',
        (t) async {
      await _launch(t);
      final s = _state(t);
      _addPlayer(s, 0.5, 0.5);
      await t.pumpAndSettle();
      final before = s.players.first.position;
      final start = t.getRect(find.byType(TacticsCanvas)).topLeft + before;
      // Drive the scale recogniser with several incremental moves — a
      // single-jump drag isn't recognised by ScaleGestureRecognizer.
      final g = await t.startGesture(start);
      for (int i = 0; i < 10; i++) {
        await g.moveBy(const Offset(6, 6));
        await t.pump();
      }
      await g.up();
      await t.pumpAndSettle();
      final after = s.players.first.position;
      expect((after - before).distance, greaterThan(20),
          reason: 'a single-finger drag on a player must move the player');
    });

    testWidgets('1.5 zoom mode toggles on and off', (t) async {
      await _launch(t);
      final s = _state(t);
      expect(find.byIcon(Icons.pinch), findsOneWidget);
      await t.tap(find.byIcon(Icons.pinch));
      await t.pumpAndSettle();
      expect(s.zoomMode, isTrue);
      await t.tap(find.byIcon(Icons.pinch));
      await t.pumpAndSettle();
      expect(s.zoomMode, isFalse);
    });

    testWidgets('2.5 half-court toggle zooms the basketball view', (t) async {
      await _launch(t);
      final s = _state(t);
      expect(find.text('Half Court'), findsOneWidget);

      await t.tap(find.text('Half Court'));
      await t.pumpAndSettle();
      expect(s.basketballHalfCourt, isTrue);
      expect(s.transformationController.value, isNot(Matrix4.identity()),
          reason: 'half-court applies a zoom transform');

      await t.tap(find.text('Full Court'));
      await t.pumpAndSettle();
      expect(s.basketballHalfCourt, isFalse);
      expect(s.transformationController.value, Matrix4.identity());
    });

    testWidgets('2.6 Add sheet opens with the collapsed My Teams section',
        (t) async {
      await _launch(t);
      await t.tap(find.text('Add'));
      await t.pumpAndSettle();
      // Sheet content for a team sport.
      expect(find.text('Players'), findsOneWidget);
      // My Teams photo library is present but collapsed by default.
      expect(find.text('My Teams'), findsOneWidget);
    });
  });
}

// ── helpers ──────────────────────────────────────────────────────────────────

Future<void> _launch(WidgetTester t) async {
  await EasyLocalization.ensureInitialized();
  await t.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: const Locale('en', 'US'),
      child: Builder(builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => TacticsState(sportType: SportType.basketball),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: const Locale('en', 'US'),
            home: const TacticsBoardHomePage(),
          ),
        );
      }),
    ),
  );
  await t.pumpAndSettle();
}

TacticsState _state(WidgetTester t) {
  final ctx = t.element(find.byType(TacticsBoardHomePage));
  return Provider.of<TacticsState>(ctx, listen: false);
}

/// Adds a home player at a normalized canvas position; addPlayer auto-selects.
void _addPlayer(TacticsState s, double nx, double ny) {
  final c = s.canvasSize;
  s.addPlayer(PlayerIcon(
    id: 'ux_${DateTime.now().microsecondsSinceEpoch}',
    label: '1',
    team: PlayerTeam.home,
    position: Offset(c.width * nx, c.height * ny),
  ));
}

void _addStroke(TacticsState s) {
  final c = s.canvasSize;
  s.startStroke(Offset(c.width * 0.2, c.height * 0.5));
  for (int i = 1; i <= 6; i++) {
    s.addPoint(Offset(c.width * (0.2 + 0.08 * i), c.height * 0.5));
  }
  s.endStroke();
}
