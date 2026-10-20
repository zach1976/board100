import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
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
import 'package:tactics_board/widgets/player_icon_widget.dart';
// __PACKAGE__ is replaced with the app's own package name by
// tools/drive_app.sh, so this walks the shell's real main().
import 'package:__PACKAGE__/main.dart' as app;

/// A paced tour of the app, for the App Store preview video.
///
/// The tour builds a board rather than opening one. An earlier cut loaded a
/// drill from the shelf and played it, which showed what the library holds
/// but not what the app is for: the thing a coach buys is being able to make
/// his own. So this one starts on an empty pitch and ends on a board that
/// did not exist thirty seconds earlier — new board, a squad, a ball, a run
/// drawn on a player, the timeline those steps live in, and play.
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
/// Which sport this shell is, passed in by tools/record_preview.sh.
///
/// The tour used to name soccer in two places: it seeded soccer's boards into
/// whatever app it was driving, and it tapped the literal "5v5" to put a
/// squad out. Field hockey offers 11v11 and 6v6, so that tap hit nothing —
/// and with no squad there was nobody to give a run to, no steps, and no play
/// bar, so five of the eight beats failed off one wrong string.
const _sportName = String.fromEnvironment('SPORT', defaultValue: 'soccer');

SportType get _sport => SportType.values.firstWhere(
      (s) => s.name == _sportName,
      orElse: () => SportType.soccer,
    );

/// The smallest squad this sport offers, named the way its chip is labelled.
/// Fewest figures reads best in a film, and every sport has one.
///
/// The Add sheet has two of these rows and they are labelled differently. A
/// team sport gets a line of "{n}v{n}" chips built from the head count,
/// whatever its formations happen to be called — baseball's say 9v9 even
/// though the formations below them are "Defense", "Bases Loaded",
/// "Shift". A racket sport has no count row at all: the formations
/// themselves are the chips, reading "Singles" and "Doubles". Ask a sheet
/// for the other one's wording and the tap hits nothing — and a tour that
/// cannot put a squad out has nobody to give a run to, so there are no
/// steps, no play bar, and five of its eight beats fail off one string.
/// The sheet tells team from racket by hasDoubles; so does this.
String get _squadChip {
  final fs = _sport.formations;
  if (fs.isEmpty) return '5v5';
  if (!_sport.hasDoubles) {
    final counts = fs.map((f) => f.homePositions.length).toSet().toList()
      ..sort();
    return '${counts.first}v${counts.first}';
  }
  final sorted = fs.toList()
    ..sort((a, b) => (a.homePositions.length + a.awayPositions.length)
        .compareTo(b.homePositions.length + b.awayPositions.length));
  return sorted.first.nameKey.tr();
}

/// The first formation under the count row, on the sheets that have one.
String get _formationChip {
  final fs = _sport.formations;
  return fs.isEmpty ? 'Apply' : fs.first.nameKey.tr();
}

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
    await _seed(_sport);

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
    /// Unused by the current cut, which builds a board instead of scrolling
    /// through one; kept because every tour that reads a list needs it.
    // ignore: unused_element
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

    // ── 1. the front door ────────────────────────────────────────────────
    await hold(1000);

    // ── 2. a board that does not exist yet ───────────────────────────────
    // New board asks for a name first, and the field takes focus, which is
    // what put a keyboard and iOS's own swipe-typing tutorial over the first
    // cut of this film. The offered name is accepted as it stands.
    final opened = await tapText('New board');
    await hold(600);
    final named = await tapText('Create') || await tapText('Apply');
    print('PREVIEW_STEP new_board=$opened named=$named');
    // The first sight of the board: empty, both goals on it.
    await hold(1500);

    // ── 3. a squad on it ─────────────────────────────────────────────────
    // Add → the squad size → Apply, and ten figures land in a shape.
    //
    // 5v5 rather than 7v7 or a back four: every larger preset in the table
    // puts the two teams' central players on the SAME point — 0.02 to 0.04
    // apart where a figure is 26 x 52 points — so a full squad lands with
    // four people standing in each other at the halfway line. 5v5 keeps
    // 0.12. (Measured off SportType.formations; worth fixing there, and
    // nothing a film should be papering over.)
    final add1 = await tapIcon(Icons.add_rounded);
    await hold(700);
    final squad = await tapText(_squadChip);
    await hold(500);
    // A Formation row appears only where one head count has more than one
    // shape to it: baseball's nine are Defense, Bases Loaded or Shift.
    // Where there is just the one the sheet picks it for you, and that is
    // why Apply alone has always been enough for soccer and basketball.
    // Where there are three it picks none, and Apply then returns without
    // doing anything and without saying so — the tap is found, the button
    // is pressed, the sheet stays open and the field stays empty. Choose
    // the shape first, then press it.
    if (find.text('Formation').hitTestable().evaluate().isNotEmpty) {
      // The LAST match: volleyball's first formation is called "6v6", the
      // same word as the count chip above it, and tapping the first match
      // pressed the count twice while the formation went unchosen.
      // A sheet that pre-selects its standard shape may not list this name;
      // then the chip already chosen is the one to apply.
      if (find.text(_formationChip).evaluate().isNotEmpty) {
        await tapFinder(find.text(_formationChip).last);
        await hold(400);
      }
    }
    final applied = await tapText('Apply');
    print('PREVIEW_STEP add=$add1 squad=$squad($_squadChip) apply=$applied');
    await hold(1500);

    // ── 4. give somebody a run ───────────────────────────────────────────
    // Before the ball goes on, not after: an earlier cut added the ball to
    // the centre spot and then tapped the middle of the pitch, so the run
    // was drawn on the ball.
    //
    // The figure is found, not aimed at. Guessing screen coordinates off
    // the formation's fractions put all four attempts in the gaps between
    // players — and with nobody picked there is no run, with no run there
    // are no steps, and with no steps the play bar is not on screen at all,
    // which is why the timeline and the play button went missing too.
    // Applying a formation leaves the board in multi-select with the whole
    // team held — right for dragging eleven people at once, wrong for the
    // next thing this tour does, because a tap there changes the selection
    // instead of opening anybody's edit bar. Back to Move first.
    final moved = await tapIcon(Icons.open_with_rounded);
    await hold(600);

    Offset? mine;
    final crowd = <Offset>[];
    final figures = find.byType(PlayerIconWidget).hitTestable();
    for (final e in figures.evaluate()) {
      final box = e.renderObject as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final c = box.localToGlobal(box.size.center(Offset.zero));
      crowd.add(c);
      // The home half, and off the centre line: a run across open grass.
      if (c.dy < screen.height * 0.50 || c.dy > screen.height * 0.72) continue;
      if (mine == null || c.dx < mine.dx) mine = c;
    }
    var picked = false;
    if (mine != null) {
      await touch(mine);
      // The bar slides in; ask after it has had time to arrive.
      await hold(500);
      picked = find.text('Add Run').hitTestable().evaluate().isNotEmpty;
    }
    await hold(500);
    final run = picked && await tapText('Add Run');
    print('PREVIEW_STEP move=$moved figures=${figures.evaluate().length} picked=$picked add_run=$run');
    await hold(400);
    if (run) {
      // Up the pitch and inside, measured from where he is standing rather
      // than from the screen — and WHICH way is chosen, not fixed. In run
      // mode a tap that lands on another player selects him instead of
      // ending the run: on a 3v3 basketball court, six figures in a narrow
      // half, the one fixed offset did exactly that. No run means no steps,
      // and with no steps the play bar is not on screen at all, so the play
      // and timeline beats of this tour tapped nothing. Of a few landing
      // spots, take the one standing in the most open court.
      Offset? best;
      var bestGap = -1.0;
      for (final d in const [
        Offset(0.22, -0.20),
        Offset(-0.22, -0.20),
        Offset(0.26, -0.30),
        Offset(-0.26, -0.30),
        Offset(0.12, -0.34),
        Offset(-0.12, -0.34),
      ]) {
        final at = Offset(
            (mine!.dx + screen.width * d.dx)
                .clamp(screen.width * 0.10, screen.width * 0.90),
            (mine.dy + screen.height * d.dy)
                .clamp(screen.height * 0.12, screen.height * 0.78));
        var gap = double.infinity;
        for (final o in crowd) {
          final g = (o - at).distance;
          if (g < gap) gap = g;
        }
        if (gap > bestGap) {
          bestGap = gap;
          best = at;
        }
      }
      await touch(best!);
      print('PREVIEW_STEP run_end gap=${bestGap.toStringAsFixed(0)}');
      await hold(1200);
      await tapText('Done');
      await hold(500);
    }

    // ── 5. and a ball ────────────────────────────────────────────────────
    final add2 = await tapIcon(Icons.add_rounded);
    await hold(600);
    final ball = await tapText('Ball');
    print('PREVIEW_STEP ball=$ball (sheet=$add2)');
    await hold(900);

    // ── 6. play it ───────────────────────────────────────────────────────
    // The edit bar sits where the play bar does and stays up while anything
    // is selected — adding the ball selects the ball — so a tap on bare
    // grass clears it first.
    await touch(Offset(screen.width * 0.12, screen.height * 0.16));
    await hold(400);
    final played = await tapIcon(Icons.play_arrow_rounded);
    print('PREVIEW_STEP play=$played');
    await hold(3000);

    // ── 7. and the steps it lives in ─────────────────────────────────────
    // Last, not before play: the timeline panel opens over the bottom of
    // the screen and covers the play button, which is where the previous
    // cut lost it.
    final timeline = await tapIcon(Icons.view_timeline_outlined);
    print('PREVIEW_STEP timeline=$timeline');
    await hold(1600);

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
