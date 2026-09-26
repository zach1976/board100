import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/services/recent_boards_service.dart';
import 'package:tactics_board/services/working_board_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
// __PACKAGE__ is replaced with the app's own package name by
// tools/drive_app.sh, so this walks the shell's real main().
import 'package:__PACKAGE__/main.dart' as app;

/// A paced tour of the app, for the App Store preview video.
///
/// Unlike [ui_walk], which exists to photograph screens and can jump about,
/// this is meant to be WATCHED. Every step is held on the clock so the
/// recording has a rhythm: arrive, let the eye land, move. The screen is
/// captured from outside by tools/record_preview.sh, which trims the film to
/// the two marks this prints.
///
///   tools/record_preview.sh soccer
///
/// Nothing here fakes the app. The taps are real taps on the real controls,
/// so what the film shows is what a coach's thumb would do.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('preview tour', (tester) async {
    // Device-source pointer events are DROPPED by default — the live
    // binding throws away real touches so they cannot disturb a running
    // test. Without this the tour sent every touch into a void and filmed
    // twenty seconds of a home page. Put back at the end: the binding
    // checks the value is unchanged when the test finishes.
    binding.shouldPropagateDevicePointerEvents = true;

    final prefs = await SharedPreferences.getInstance();
    // Everything that is right in the app and wrong in a film: the ad, the
    // three-panel intro, the empty-board coach mark, the toast that explains
    // what following a player does.
    await prefs.setBool('remove_ads_pro', true);
    await prefs.setBool('intro_seen', true);
    await prefs.setBool('board_hint_seen', true);
    await prefs.setBool('focus_hint_seen', true);

    // A film of an app with nothing in it is a film of an empty app. Same
    // seed the store screenshots use: boards saved today, yesterday and last
    // week, drills in the recent row, one board left open.
    await _seed(SportType.soccer);

    app.main();

    /// Hold for [ms] of real time, drawing frames the whole way.
    ///
    /// Not pumpAndSettle: this is a film, and the pauses between moves are
    /// the point.
    ///
    /// Counted off the wall clock rather than by adding up the durations
    /// asked for. A pump of 16ms does not take 16ms — in a debug build on a
    /// simulator it takes two or three times that — so the first cut of this
    /// tour was written for 26 seconds and ran for 61.
    Future<void> hold(int ms) async {
      final until = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(until)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    // Touches go in as DEVICE events, not test events.
    //
    // tester.tap and tester.drag mark themselves as coming from the test,
    // and the live binding paints a yellow crosshair wherever one lands —
    // helpful when you are watching a test, fatal in a film. Handing the
    // same pointer events to the binding directly defaults them to the
    // device source, which the marker ignores.
    var pointer = 1;

    Future<void> touch(Offset at) async {
      final id = pointer++;
      tester.binding.handlePointerEvent(PointerDownEvent(
          pointer: id, position: at));
      await hold(90);
      tester.binding.handlePointerEvent(PointerUpEvent(
          pointer: id, position: at));
      await hold(600);
    }

    Future<bool> tapFinder(Finder f) async {
      final hit = f.hitTestable();
      if (hit.evaluate().isEmpty) return false;
      await touch(tester.getCenter(hit.first));
      return true;
    }

    Future<bool> tapIcon(IconData icon) => tapFinder(find.byIcon(icon));
    Future<bool> tapText(String text) => tapFinder(find.text(text));

    /// Drag the list under [at] by [dy], in steps, the way a thumb would.
    ///
    /// No fling: every event carries the same timestamp, so the arena reads
    /// no velocity and the list stops exactly where it is put. A preview
    /// that overshoots and bounces is a preview of the scroll physics.
    Future<void> swipe(Offset at, double dy, {int steps = 18}) async {
      final id = pointer++;
      var p = at;
      tester.binding.handlePointerEvent(PointerDownEvent(
          pointer: id, position: p));
      await hold(40);
      for (var i = 0; i < steps; i++) {
        p = p + Offset(0, dy / steps);
        tester.binding.handlePointerEvent(PointerMoveEvent(
            pointer: id, position: p, delta: Offset(0, dy / steps)));
        await hold(16);
      }
      tester.binding.handlePointerEvent(PointerUpEvent(
          pointer: id, position: p));
      await hold(500);
    }

    // Launch, splash, first frame of the home page.
    await hold(4000);
    print('PREVIEW_MARK start ${DateTime.now().millisecondsSinceEpoch}');

    final view0 = tester.view;
    final screen = view0.physicalSize / view0.devicePixelRatio;
    final middle = Offset(screen.width * 0.5, screen.height * 0.55);

    // ── 1. the front door ────────────────────────────────────────────────
    await hold(1800);
    await swipe(middle, -380);
    await hold(1100);
    await swipe(middle, 380);
    await hold(700);

    // ── 2. the shelf ─────────────────────────────────────────────────────
    await tapIcon(Icons.fitness_center);
    await hold(1600);
    await swipe(middle, -460);
    await hold(1300);

    // ── 3. one drill onto the board ──────────────────────────────────────
    // The board icon on the first card, which is what the page's own
    // subtitle tells a coach to use: "the board icon opens it on the board".
    // Scoped to the card rather than found on the page, because the Board
    // tab carries the same glyph — an earlier cut tapped whichever came
    // first in the tree and only looked deliberate by luck.
    // Scoping it to the first card does not work: after a scroll the first
    // _DrillRow in the tree is the one above the viewport, and its icon is
    // not hit-testable. Take the topmost one that actually is, and stay
    // clear of the tab bar, which carries the same glyph at the foot of the
    // screen.
    var loaded = false;
    final icons = find.byIcon(Icons.dashboard_outlined).hitTestable();
    for (final e in icons.evaluate()) {
      final box = e.renderObject as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final centre = box.localToGlobal(box.size.center(Offset.zero));
      if (centre.dy > screen.height * 0.85) continue; // the tab bar
      await touch(centre);
      loaded = true;
      break;
    }
    print('PREVIEW_STEP board=$loaded');
    await hold(1600);

    // ── 5. play it ───────────────────────────────────────────────────────
    final played = await tapIcon(Icons.play_arrow_rounded);
    print('PREVIEW_STEP play=$played');
    if (played) await hold(6500);

    // ── 6. pick a player up ──────────────────────────────────────────────
    // Middle of the pitch, above the play bar: whoever is there gets the
    // bar that names them, turns them and gives them a run.
    await touch(Offset(screen.width * 0.5, screen.height * 0.42));
    await hold(2000);

    // ── 7. the timeline ──────────────────────────────────────────────────
    final timeline = await tapIcon(Icons.view_timeline_outlined);
    print('PREVIEW_STEP timeline=$timeline');
    await hold(2400);

    print('PREVIEW_MARK end ${DateTime.now().millisecondsSinceEpoch}');
    await hold(600);
    binding.shouldPropagateDevicePointerEvents = false;
  });
}

/// Boards, recents and a board left open, so the home page has a past.
///
/// The same three drills the store screenshots use, through the app's own
/// services, before main() reads any of it.
Future<void> _seed(SportType sport) async {
  List<Drill> all = const [];
  try {
    all = await DrillLibraryService.instance.forSport(sport);
  } catch (_) {
    return;
  }
  if (all.isEmpty) return;
  final picks = <Drill>[];
  for (final d in all) {
    if (picks.length >= 6) break;
    if (d.family != null && picks.any((e) => e.family == d.family)) continue;
    picks.add(d);
  }
  final s = TacticsState(sportType: sport, preview: true);
  try {
    for (final name in await s.listSavedTactics()) {
      await s.deleteTactics(name);
    }
    const ages = <int>[0, 1, 6];
    for (var i = 0; i < ages.length && i < picks.length; i++) {
      final d = picks[i];
      final name = d.localizedName('en');
      s.loadFromJson(Map<String, dynamic>.from(d.board));
      final path = await s.saveTactics(name);
      final when = DateTime.now().subtract(Duration(days: ages[i]));
      if (ages[i] != 0) await _backdate(path, when);
      await RecentBoardsService.instance.record(
        sport,
        RecentBoard(
            kind: RecentBoardKind.tactic,
            id: name,
            label: name,
            openedAt: when),
      );
    }
    for (var i = picks.length - 1; i >= 0; i--) {
      await RecentBoardsService.instance.record(
        sport,
        RecentBoard(
          kind: RecentBoardKind.drill,
          id: picks[i].id,
          label: picks[i].localizedName('en'),
          openedAt: DateTime.now().subtract(Duration(hours: 5 * i)),
        ),
      );
    }
    final open = picks.first;
    s.loadFromJson(Map<String, dynamic>.from(open.board));
    await WorkingBoardService.instance.save(
        sport, s.toJson()..['currentName'] = open.localizedName('en'));
  } catch (_) {
    // A film with an empty home page is worse than this one failing quietly.
  } finally {
    s.dispose();
  }
}

Future<void> _backdate(String path, DateTime when) async {
  final file = File(path);
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final meta = json['meta'];
  if (meta is! Map) return;
  meta['updatedAt'] = when.toIso8601String();
  meta['createdAt'] = when.subtract(const Duration(days: 3)).toIso8601String();
  await file.writeAsString(jsonEncode(json));
}
