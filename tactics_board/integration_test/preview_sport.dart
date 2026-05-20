// Preview-video integration test — drives the demo workflow for ANY sport.
//
// The sport is selected at compile time via --dart-define=SPORT=<enum-name>
// (e.g. soccer, basketball, tennis). It drives the full demo workflow
// programmatically while a `xcrun simctl io recordVideo` process captures
// the simulator screen. The PhotoImportSheet is short-circuited via the
// `--dart-define=PREVIEW_PHOTO_PATH=asset:...` hook, so this test never
// needs to touch the native iOS UIImagePicker (which Flutter integration
// tests can't drive).
//
// Run with:
//   flutter test integration_test/preview_sport.dart \
//     -d <simulator-id> \
//     --dart-define=SPORT=basketball \
//     --dart-define=PREVIEW_PHOTO_PATH=asset:assets/preview/team_photo.jpg
//
// Pacing notes:
//   Scene 1 (0-2.5s)      empty board
//   Scene 2/3 (2.5-9s)    photo sheet + face detection + preview grid
//   Scene 4 (9-13s)       confirm + players land on board
//   Scene 5 (13-19s)      tap-to-add moves for two players
//   Scene 6 (19-22s)      timeline editor opens then closes
//   Scene 7 (22-29s)      players animate along their move paths

import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_formation.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/services/photo_library_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/photo_import_sheet.dart';
import 'package:tactics_board/widgets/timeline_editor.dart';
import 'package:tactics_board/widgets/toolbar.dart' show showAddElementSheet;

const _sportName = String.fromEnvironment('SPORT', defaultValue: 'soccer');

/// Maps the SPORT dart-define onto a SportType enum value.
SportType _resolveSport() {
  for (final s in SportType.values) {
    if (s.name == _sportName) return s;
  }
  return SportType.soccer;
}

/// The formation the preview places for `sport`: a realistic, complete team
/// that fits within the 8 imported faces. Racquet sports use doubles (2 a
/// side); team sports use a full side that fits (5–8 players).
SportFormation _previewFormation(SportType sport) {
  const preferred = <String, String>{
    'badminton': 'formation_doubles',
    'tableTennis': 'formation_doubles',
    'tennis': 'formation_doubles',
    'pickleball': 'formation_doubles',
    'beachTennis': 'formation_doubles',
    'footvolley': 'formation_doubles',
    'sepakTakraw': 'formation_regu',
    'basketball': 'formation_122',
    'volleyball': 'formation_6v6',
    'handball': 'formation_7v7',
    'waterPolo': 'formation_7v7',
    'soccer': 'formation_7v7',
    'fieldHockey': 'formation_5v5',
    'rugby': 'formation_7v7',
    'baseball': 'formation_defense',
  };
  final want = preferred[sport.name];
  final formations = sport.formations;
  return formations.firstWhere((f) => f.nameKey == want,
      orElse: () => formations.first);
}

/// Open-field team sports place the whole squad with one drag of the
/// "+N" tile; racquet / small-net sports place a precise small formation.
const _dragWholeTeamSports = {
  SportType.soccer, SportType.basketball, SportType.volleyball,
  SportType.handball, SportType.rugby, SportType.fieldHockey,
  SportType.baseball, SportType.waterPolo,
};

/// Racquet sports whose preview places a front-back doubles pair: the female
/// (photos[1]) up front near the net, the male (photos[0]) at the back.
const _racketDoublesSports = {
  SportType.badminton, SportType.tennis, SportType.pickleball,
  SportType.beachTennis, SportType.footvolley,
};

/// Three-step movement paths (absolute board-canvas points) keyed by player
/// id. Targets stay on the legal surface for the sport.
Map<String, List<Offset>> _previewMovePaths(
    SportType sport, List<PlayerIcon> homePlayers, Rect field, Size canvas) {
  Offset fp(double fx, double fy) => Offset(
      field.left + field.width * fx, field.top + field.height * fy);
  Offset cv(double fx, double fy) =>
      Offset(canvas.width * fx, canvas.height * fy);

  // Racquet doubles — a classic front-back footwork drill. The front player
  // (female, preview_home_0, near the net) sweeps right → left → centre; the
  // back player (male, preview_home_1) sweeps left → right → centre. Every
  // waypoint stays clear of (on the net side of) the player's own start, so
  // the move line never loops back through the starting marker, and the
  // depth varies step to step so the footwork reads naturally.
  if (_racketDoublesSports.contains(sport)) {
    return {
      'preview_home_0': [fp(0.74, 0.57), fp(0.27, 0.54), fp(0.50, 0.59)],
      'preview_home_1': [fp(0.26, 0.80), fp(0.74, 0.82), fp(0.50, 0.78)],
    };
  }

  // Table tennis — lateral footwork in the apron below the table. Each
  // player keeps to their own side, so the two never occupy the same point
  // at the same time (their paths never share a waypoint).
  if (sport == SportType.tableTennis) {
    return {
      'preview_home_0': [cv(0.27, 0.82), cv(0.41, 0.90), cv(0.32, 0.86)],
      'preview_home_1': [cv(0.73, 0.82), cv(0.59, 0.90), cv(0.68, 0.86)],
    };
  }

  // Open-field / net team sports — move the left-most and right-most
  // players forward in fanning runs that curve out in opposite directions.
  final sorted = [...homePlayers]
    ..sort((a, b) => a.position.dx.compareTo(b.position.dx));
  if (sorted.length < 2) return {};
  final leftP = sorted.first;
  final rightP = sorted.last;
  const netSports = {SportType.volleyball, SportType.sepakTakraw};
  Offset toFrac(PlayerIcon p) => Offset(
      ((p.position.dx - field.left) / field.width).clamp(0.0, 1.0),
      ((p.position.dy - field.top) / field.height).clamp(0.0, 1.0));
  final l = toFrac(leftP);
  final r = toFrac(rightP);
  double cx(double v) => v.clamp(0.07, 0.93);
  // Net-sport players may approach but not cross the net (y ≥ 0.53);
  // open-field sports may run anywhere downfield (y ≥ 0.12).
  final double yMin = netSports.contains(sport) ? 0.53 : 0.12;
  double cy(double v) => v.clamp(yMin, 0.96);
  return {
    leftP.id: [
      fp(cx(l.dx - 0.13), cy(l.dy - 0.11)),
      fp(cx(l.dx + 0.02), cy(l.dy - 0.23)),
      fp(cx(l.dx + 0.13), cy(l.dy - 0.37)),
    ],
    rightP.id: [
      fp(cx(r.dx + 0.13), cy(r.dy - 0.11)),
      fp(cx(r.dx - 0.02), cy(r.dy - 0.23)),
      fp(cx(r.dx - 0.13), cy(r.dy - 0.37)),
    ],
  };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('preview_sport_workflow', (t) async {
    await EasyLocalization.ensureInitialized();
    await _launch(t);

    // ─── Scene 1: empty board ────────────────────────────────────────────
    // Kept short — just long enough to register the board before the photo
    // import sheet slides up. A long empty opening reads as dead air.
    await _wait(t, 1200);

    // ─── Scene 2: open the Add-Element popup ─────────────────────────────
    // The import workflow lives inside the Add-Element popup: the user opens
    // it, imports a team photo, and returns to it once the faces are
    // detected. Show that container before the import begins.
    final ctx = t.element(find.byType(TacticsBoardHomePage));
    final state = Provider.of<TacticsState>(ctx, listen: false);

    Future<void> closeSheet() async {
      await Navigator.of(t.element(find.byType(TacticsBoardHomePage)))
          .maybePop();
      await t.pumpAndSettle();
    }

    // listGroups() seeds the default group on a fresh install, so the photo
    // library is never empty; import into that group.
    final libGroups = await PhotoLibraryService.instance.listGroups();
    final groupId = libGroups.first.id;

    // ignore: unawaited_futures
    showAddElementSheet(ctx, state);
    await t.pumpAndSettle();
    await _wait(t, 1000);
    await closeSheet();
    await _wait(t, 250);

    // ─── Scene 3: import a team photo + detect faces ─────────────────────
    // ignore: unawaited_futures
    PhotoImportSheet.showWithSourcePicker(ctx, groupId: groupId);
    // Sheet slides up + detection runs + preview grid renders.
    await _wait(t, 3400);
    // Tap the Save (Confirm) button — its label is "Save N" for N faces.
    final save = find.textContaining('Save ');
    if (save.evaluate().isNotEmpty) {
      await t.tap(save.first);
      await t.pumpAndSettle();
    }
    await _wait(t, 600);

    // ─── Scene 3b: back in the Add popup, now showing the imported team ──
    // Reopen the Add-Element popup so its photo strip rebuilds with the
    // freshly-imported faces, then scroll the My-Teams "+N" whole-team tile
    // into view.
    final all = await PhotoLibraryService.instance.list();
    final photos = all.where((p) => p.groupId == groupId).toList();
    // ignore: avoid_print
    print('[preview-mode] sport=$_sportName: ${photos.length} faces imported');
    final tileLabel = '+${photos.length}';

    // ignore: unawaited_futures
    showAddElementSheet(ctx, state);
    await t.pumpAndSettle();
    await _wait(t, 600);
    final addScrollables = find.byType(Scrollable);
    for (var i = 0; i < 12; i++) {
      if (find.text(tileLabel).evaluate().isNotEmpty) break;
      if (addScrollables.evaluate().isEmpty) break;
      await t.drag(addScrollables.last, const Offset(0, -240));
      await t.pumpAndSettle();
      await _wait(t, 130);
    }
    if (find.text(tileLabel).evaluate().isNotEmpty) {
      await t.ensureVisible(find.text(tileLabel).first);
      await t.pumpAndSettle();
    }
    await _wait(t, 800);

    // ─── Scene 4: put the team on the board ──────────────────────────────
    // Team sports: long-press-drag the whole-team "+N" tile onto the board.
    // Racquet / small-net sports: close the popup and place a precise
    // formation — the correct per-sport count (2 a side for badminton-type
    // sports) at positions inside the legal playing area.
    final sport = _resolveSport();
    final canvas = state.canvasSize;
    final field = sport.fieldRect(canvas);

    if (_dragWholeTeamSports.contains(sport) &&
        find.text(tileLabel).evaluate().isNotEmpty &&
        boardRepaintKey.currentContext != null) {
      final tilePos = t.getCenter(find.text(tileLabel).first);
      final boardRO =
          boardRepaintKey.currentContext!.findRenderObject()! as RenderBox;
      final boardCenter = boardRO.localToGlobal(boardRO.size.center(Offset.zero));
      final g = await t.startGesture(tilePos);
      await t.pump(const Duration(milliseconds: 700)); // long-press triggers
      for (var i = 1; i <= 28; i++) {
        await g.moveTo(Offset.lerp(tilePos, boardCenter, i / 28)!);
        await t.pump(const Duration(milliseconds: 33));
      }
      await g.up();
      await t.pumpAndSettle();
      await _wait(t, 1000);
    } else {
      // Racquet / small-net sports — direct formation placement.
      await closeSheet();
      await _wait(t, 400);
      // Table tennis is special: its fieldRect *is* the table surface, which
      // players may never stand on, so its players go in the apron below it.
      // Racquet doubles place a front-back pair: photos[0] (male) at the
      // back near the baseline, photos[1] (female) up front near the net.
      final List<Offset> homeSpots;
      if (sport == SportType.tableTennis) {
        homeSpots = [
          Offset(canvas.width * 0.38, canvas.height * 0.84),
          Offset(canvas.width * 0.62, canvas.height * 0.84),
        ];
      } else if (_racketDoublesSports.contains(sport)) {
        // photos[0] is female (front, near net), photos[1] is male (back).
        homeSpots = [
          Offset(field.left + field.width * 0.50,
              field.top + field.height * 0.62), // front — female (photos[0])
          Offset(field.left + field.width * 0.50,
              field.top + field.height * 0.84), // back — male (photos[1])
        ];
      } else {
        homeSpots = [
          for (final f in _previewFormation(sport).homePositions)
            Offset(field.left + field.width * f.dx,
                field.top + field.height * f.dy),
        ];
      }
      final count =
          photos.isEmpty ? 0 : math.min(homeSpots.length, photos.length);
      for (var i = 0; i < count; i++) {
        state.addPlayer(PlayerIcon(
          id: 'preview_home_$i',
          label: '',
          team: PlayerTeam.home,
          position: homeSpots[i],
          photoId: photos[i % photos.length].id,
        ));
        await _wait(t, 200);
      }
    }
    state.selectPlayer(null);
    await _wait(t, 800);

    // ─── Scene 5: add movement paths to two players ──────────────────────
    // Movement paths are drawn in Move mode. The drag-the-team step leaves
    // the board in multi-select (Select) mode, so switch back to Move first
    // — the toolbar should read "Move" while paths are being added.
    state.setMultiSelectMode(false);
    state.setDrawingMode(false);
    await _wait(t, 350);
    // Give two players a sport-appropriate movement path (see
    // _previewMovePaths — racquet doubles get a front-back footwork drill).
    final homePlayers = state.players
        .where((p) => p.team == PlayerTeam.home)
        .toList();
    if (homePlayers.length >= 2) {
      final paths = _previewMovePaths(sport, homePlayers, field, canvas);
      for (final entry in paths.entries) {
        if (!state.players.any((p) => p.id == entry.key)) continue;
        state.selectPlayer(entry.key);
        await _wait(t, 480);
        for (final wp in entry.value) {
          state.addPlayerMove(entry.key, wp);
          await _wait(t, 560);
        }
        await _wait(t, 620);
      }
      state.selectPlayer(null);
    }

    // ─── Scene 6: edit the timeline ──────────────────────────────────────
    // Open the timeline editor and drag one move block one phase slot later,
    // so the viewer sees the timeline actually being edited.
    final timelineBtn = find.byIcon(Icons.view_timeline);
    if (timelineBtn.evaluate().isNotEmpty) {
      await t.tap(timelineBtn.first);
      await t.pumpAndSettle();
    }
    await _wait(t, 1100);

    // The editor renders phaseCount = maxPhase + 2, so the trailing column
    // is always an empty drop target. Drag the first player's last move
    // block (block #2) into its empty next slot (drop target #3).
    final tlBlocks = find.descendant(
        of: find.byType(TimelineEditor),
        matching: find.byWidgetPredicate((w) => w is Draggable));
    final tlSlots = find.descendant(
        of: find.byType(TimelineEditor),
        matching: find.byWidgetPredicate((w) => w is DragTarget));
    if (tlBlocks.evaluate().length >= 3 && tlSlots.evaluate().length >= 4) {
      final src = t.getCenter(tlBlocks.at(2));
      final dst = t.getCenter(tlSlots.at(3));
      final g = await t.startGesture(src);
      for (var i = 1; i <= 24; i++) {
        await g.moveTo(Offset.lerp(src, dst, i / 24)!);
        await t.pump(const Duration(milliseconds: 34));
      }
      await g.up();
      await t.pumpAndSettle();
    }
    await _wait(t, 1200);
    await closeSheet(); // close the modal timeline sheet
    await _wait(t, 500);

    // ─── Scene 7: play the movement ──────────────────────────────────────
    // Drive playback from the state directly. The toolbar Play button is
    // occluded by transient overlays (e.g. the modal timeline sheet), so
    // tapping it is unreliable. _AnimationDriver picks up isAnimating and
    // slides every player along its move path (~700 ms per phase, 3 phases
    // ≈ 2.1 s total).
    state.selectPlayer(null);
    state.startAnimation();
    // The first animation tick fires synchronously inside _AnimationDriver's
    // didUpdateWidget (via AnimationController.forward), so its reentrant
    // notifyListeners trips a debug-only "setState during build" assertion.
    // It is caught by the framework, renders no error UI, and the animation
    // plays correctly. Drain it so the test reports the workflow as passing.
    await t.pump(const Duration(milliseconds: 16));
    while (t.takeException() != null) {}
    await _wait(t, 3000);
  });
}

// ─── helpers ─────────────────────────────────────────────────────────────

Future<void> _launch(WidgetTester t) async {
  await t.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: const Locale('en', 'US'),
      child: Builder(builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => TacticsState(sportType: _resolveSport()),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: const Locale('en', 'US'),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue, brightness: Brightness.dark),
              scaffoldBackgroundColor: const Color(0xFF0D0D1A),
            ),
            home: const TacticsBoardHomePage(),
          ),
        );
      }),
    ),
  );
  await t.pumpAndSettle();
}

/// Wall-clock pause that keeps pumping frames so the screen recorder
/// captures continuous animation during long waits.
Future<void> _wait(WidgetTester t, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await Future.delayed(const Duration(milliseconds: 80));
    await t.pump();
  }
}
