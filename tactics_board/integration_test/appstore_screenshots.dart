import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/config_constants.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/services/recent_boards_service.dart';
import 'package:tactics_board/services/working_board_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/pages/drill_library_page.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/pages/main_shell.dart';
import 'package:tactics_board/pages/sport_home_page.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart' show PlayerArt;
import 'package:tactics_board/widgets/toolbar.dart';

// V2 raw app screenshots for the "PLAN EVERY RALLY" design.
// Output: aso/screenshots_v2_raw/<sport>/<locale>/s{1..5}.png
// 5-shot story: home · add-menu · timeline · drill library · player bar.
final outDir =
    '/Users/zhenyusong/projects/board100/tactics_board/aso/screenshots_v2_raw';

// (ASC locale name, Flutter locale). 11 store locales.
final allLocales = <(String, Locale)>[
  ('en-US', const Locale('en', 'US')),
  ('es-ES', const Locale('es', 'ES')),
  ('fr-FR', const Locale('fr', 'FR')),
  ('id', const Locale('id', 'ID')),
  ('ja', const Locale('ja', 'JP')),
  ('ko', const Locale('ko', 'KR')),
  ('ms', const Locale('ms', 'MY')),
  ('th', const Locale('th', 'TH')),
  ('vi', const Locale('vi', 'VN')),
  ('zh-Hans', const Locale('zh', 'CN')),
  ('zh-Hant', const Locale('zh', 'TW')),
];

final _supportedLocales = allLocales.map((e) => e.$2).toList();

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // The empty board offers a coach a first-run hint on how to put something
  // on it. It is the right thing in the app and the wrong thing on the
  // leading store screenshot, which is a picture of the pitch.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    // The hint on an empty board, and the three-panel intro the shell shows
    // a first run: both are right in the app and both are the wrong thing
    // to photograph. Without the second, the front-door shot came out as
    // the onboarding page and the drill shot found no home page under it.
    'flutter.board_hint_seen': true,
    'flutter.intro_seen': true,
    // Picking a player up the first time explains what following one does.
    // It is a toast across the bottom of the player bar — which is the
    // subject of s6.
    'flutter.focus_hint_seen': true,
    // An ad over the top of a store screenshot.
    'flutter.remove_ads_pro': true,
  });
  // This file is run from a SHELL app — SoccerBoard, BasketballBoard — not
  // from the core. The core is a library now: a sport's ball, its equipment
  // and its drills are dev dependencies there, so a board shot from it has
  // no ball on it. In a shell every asset of the core sits under
  // packages/tactics_board/, which is what the shell's own main() says.
  ConfigConstants.hasPackagePath = true;

  group('Screenshots V2', () {
    for (final sport in SportType.values) {
      final sn = sport.name;
      for (final (lang, locale) in allLocales) {
        // s1: the app's front door — the library, what to run today, the
        // board waiting where it was left. An empty pitch was the old first
        // shot, and an empty pitch is what every tactics board looks like.
        testWidgets('${sn}_${lang}_s1', (t) async {
          await _seedHome(t, sport, locale);
          await _launchHome(t, sport, locale);
          await _shot(binding, '$sn/$lang/s1');
        });

        // s2: Add-element bottom sheet (match setups), over a board in use —
        // opened on an empty pitch the top half of the shot is grass.
        testWidgets('${sn}_${lang}_s2', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          await _putShowcase(t, s, sport);
          s.selectPlayer(null);
          s.clearMultiSelect();
          await t.pumpAndSettle();
          final ctx = t.element(find.byType(TacticsBoardHomePage));
          showAddElementSheet(ctx, s);
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s2');
        });

        // s3: timeline editor
        testWidgets('${sn}_${lang}_s3', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          await _putShowcase(t, s, sport);
          s.selectPlayer(null);
          await t.pumpAndSettle();
          // The outlined variant: the play bar's button, which is what the
          // filled Icons.view_timeline stopped being some releases ago.
          await t.tap(find.byIcon(Icons.view_timeline_outlined));
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s3');
        });

        // s4: the drill library — the shelf itself. A single drill's page
        // says what one session looks like; the list says how many there
        // are, sorted and filtered, which is the thing a coach is buying.
        testWidgets('${sn}_${lang}_s4', (t) async {
          await _launchHome(t, sport, locale);
          final ctx = t.element(find.byType(SportHomePage));
          final s = Provider.of<TacticsState>(ctx, listen: false);
          DrillLibraryPage.push(ctx, s);
          await t.pumpAndSettle();
          // The cards carry a board thumbnail each, drawn from the drill's
          // own JSON. Shot the moment the route settles, half the shelf is
          // empty frames.
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 600)));
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s4');
        });

        // s5: one player picked up — the bar that names them, turns them,
        // gives them a run, a colour, a size, a kit. The board behind it is
        // two beats in, so the routes are drawn as well.
        testWidgets('${sn}_${lang}_s5', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          // advanceAtStep, not setTargetStep: the board reads either, but
          // the counter on the bar reads atStep, and a shot captioned 0/8
          // over a board three beats in is a shot of a bug.
          await _putShowcase(t, s, sport, step: 2);
          s.clearMultiSelect();
          await t.pumpAndSettle();
          // Somebody with a run to show: the bar is the same either way, but
          // a player standing still leaves the board's own lines empty.
          final runner = s.players.firstWhere(
              (p) => !p.isBall && !p.isMarker && p.moves.isNotEmpty,
              orElse: () => s.players.firstWhere(
                  (p) => !p.isBall && !p.isMarker));
          s.selectPlayer(runner.id);
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s5');
        });
      }
    }
  });
}

/// The drill the store page shows, where somebody has looked at it.
///
/// Which board photographs best is a judgement, not a score: soccer's
/// pentagon puts six players across the pitch with the cones that make the
/// shape and one clear pass, where the 4v4 the heuristic liked is eight
/// players and four goals in the same space. Sports without an entry fall
/// back to the rule below, which is what picked this one's shortlist.
const _showcaseIds = <SportType, String>{
  SportType.soccer: 'passing_pentagon',
  // The heuristic picked a five-player aerial that sat in the bottom third
  // and left half the pitch empty. A counter-attack runs the length of it:
  // seven players spread 791 board units top to bottom, the ball travelling
  // through all four beats.
  SportType.fieldHockey: 'fh_counter_attack',
};

/// The drill to photograph: the shipped library's own, chosen for what a
/// store screenshot has to show at a glance — a ball that travels, the
/// equipment that makes the shape, and enough beats to have a past and a
/// future. Deterministic, so every locale shoots the same board.
Future<Drill?> _showcase(WidgetTester t, SportType sport) async {
  List<Drill> all = const [];
  await t.runAsync(() async {
    all = await DrillLibraryService.instance.forSport(sport);
  });
  final named = _showcaseIds[sport];
  if (named != null) {
    for (final d in all) {
      if (d.id == named) return d;
    }
  }
  Drill? best;
  var bestScore = -1;
  for (final d in all) {
    final ps = (d.board['players'] as List?) ?? const [];
    var ball = 0, markers = 0, people = 0, steps = 0;
    for (final raw in ps) {
      final p = Map<String, dynamic>.from(raw as Map);
      final phases = (p['movePhases'] as List?) ?? const [];
      for (final ph in phases) {
        if (ph is int && ph + 1 > steps) steps = ph + 1;
      }
      final shape = p['markerShape'] as int? ?? 0;
      final isBall = p['team'] == 2 && p['sportType'] != null && shape == 0;
      if (isBall) {
        ball += ((p['moves'] as List?) ?? const []).isEmpty ? 0 : 1;
      } else if (shape != 0) {
        markers++;
      } else {
        people++;
      }
    }
    if (ball == 0 || steps < 3 || steps > 6 || people < 5 || people > 9) {
      continue;
    }
    // Equipment first — the cones are what makes a picture read as a drill
    // rather than a match — then the fewest players that still fill the
    // pitch: eleven a side with three defenders in bibs is a crowd at
    // thumbnail size.
    final score = markers * 100 - people * 5 + steps;
    if (score > bestScore) {
      bestScore = score;
      best = d;
    }
  }
  return best;
}

/// Puts the sport's showcase drill on [s], walked to [step].
///
/// Every board shot is this one board. A formation was what s3 and s4 used
/// to show, and `formations[0]` lays out BOTH teams — so the two midfields
/// stood on each other across the halfway line, twenty-two figures deep, on
/// a pitch dimmed under a sheet. A drill is six players, the cones that
/// make the shape, and a ball that goes somewhere.
Future<void> _putShowcase(WidgetTester t, TacticsState s, SportType sport,
    {int step = 0}) async {
  final drill = await _showcase(t, sport);
  if (drill == null) {
    _setupFormationAndMoves(s, sport);
    return;
  }
  s.loadFromJson(Map<String, dynamic>.from(drill.board));
  s.setShowMoveLines(true);
  if (step > 0) s.advanceAtStep(step);
}

void _setupFormationAndMoves(TacticsState s, SportType sport) {
  if (sport.formations.isNotEmpty) s.applyFormation(sport.formations[0]);
  // Applying a formation leaves every player it placed multi-selected, so a
  // coach can drag the shape as one. On a store screenshot that is eleven
  // selection rings on a pitch nobody has touched.
  s.clearMultiSelect();
  final home = s.players.where((p) => p.team == PlayerTeam.home).toList();
  if (home.isNotEmpty) _addMovesToState(s, sport, home);
}

void _addMovesToState(TacticsState s, SportType sport, List<PlayerIcon> home) {
  final c = s.canvasSize;
  final p1 = home[0];
  final baseY1 = sport.hasNet ? 0.60 : 0.55;
  s.addPlayerMove(p1.id, Offset(c.width * 0.40, c.height * baseY1));
  s.addPlayerMove(p1.id, Offset(c.width * 0.60, c.height * (baseY1 + 0.05)));
  s.addPlayerMove(p1.id, Offset(c.width * 0.50, c.height * (baseY1 + 0.10)));
  if (home.length >= 2) {
    final p2 = home[1];
    final baseY2 = sport.hasNet ? 0.65 : 0.60;
    s.addPlayerMove(p2.id, Offset(c.width * 0.30, c.height * baseY2));
    s.addPlayerMove(p2.id, Offset(c.width * 0.50, c.height * (baseY2 + 0.05)));
    s.addPlayerMove(p2.id, Offset(c.width * 0.70, c.height * (baseY2 + 0.02)));
    s.setMovePhase(p1.id, 0, 0);
    s.setMovePhase(p1.id, 1, 2);
    s.setMovePhase(p1.id, 2, 4);
    s.setMovePhase(p2.id, 0, 1);
    s.setMovePhase(p2.id, 1, 3);
    s.setMovePhase(p2.id, 2, 5);
  }
}

/// Gives the front door something to be a front door TO.
///
/// The home page is a page about the coach's own work: the board they left
/// open, the drills they looked at this week, the boards they saved. Shot on
/// a fresh install every one of those is empty, and the leading store
/// screenshot came out as a photograph, a blank card and the words "nothing
/// saved yet" — an app with nothing in it.
///
/// So it is seeded first, out of the shipped library, in the locale being
/// shot: three saved boards dated today, yesterday and last week, six drills
/// in the recent row, and the first of them left open on the board. All of it
/// through the app's own services, so what the page draws is what it would
/// draw for a coach who had done this by hand.
Future<void> _seedHome(WidgetTester t, SportType sport, Locale locale) async {
  final loc = locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}-${locale.countryCode}';
  List<Drill> all = const [];
  await t.runAsync(() async {
    all = await DrillLibraryService.instance.forSport(sport);
  });
  if (all.isEmpty) return;
  final showcase = await _showcase(t, sport);
  // The drill on the board card is the one s2 and s5 are about; the rest are
  // the library's own order, one per family so the row reads as six different
  // things rather than the same rondo at six sizes.
  final picks = <Drill>[if (showcase != null) showcase];
  for (final d in all) {
    if (picks.length >= 6) break;
    if (picks.any((e) => e.id == d.id)) continue;
    if (d.family != null && picks.any((e) => e.family == d.family)) continue;
    picks.add(d);
  }
  await t.runAsync(() async {
    // preview: a seeder must not claim the external-display channel, and
    // must not write its own loads over the working board this ends by
    // setting.
    final s = TacticsState(sportType: sport, preview: true);
    // Whatever the locale before this one saved: the names are translated,
    // so without this "my boards" grows by three every locale and shows
    // Korean rows on the Spanish page.
    for (final name in await s.listSavedTactics()) {
      await s.deleteTactics(name);
    }
    const ages = <int>[0, 1, 6];
    for (var i = 0; i < ages.length && i < picks.length; i++) {
      final d = picks[i];
      final name = d.localizedName(loc);
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
          openedAt: when,
        ),
      );
    }
    // Recorded oldest first, because record() puts each one on top.
    for (var i = picks.length - 1; i >= 0; i--) {
      await RecentBoardsService.instance.record(
        sport,
        RecentBoard(
          kind: RecentBoardKind.drill,
          id: picks[i].id,
          label: picks[i].localizedName(loc),
          openedAt: DateTime.now().subtract(Duration(hours: 5 * i)),
        ),
      );
    }
    final open = picks.first;
    s.loadFromJson(Map<String, dynamic>.from(open.board));
    await WorkingBoardService.instance.save(
      sport,
      s.toJson()..['currentName'] = open.localizedName(loc),
    );
    s.dispose();
  });
}

/// Dates a saved board back to [when].
///
/// Three boards all saved a second ago all say "today", and a list where
/// every row says the same thing is a list nobody reads. saveTactics stamps
/// the moment it wrote — rightly — so the date is edited on the file.
Future<void> _backdate(String path, DateTime when) async {
  final file = File(path);
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final meta = json['meta'];
  if (meta is! Map) return;
  meta['updatedAt'] = when.toIso8601String();
  meta['createdAt'] = when.subtract(const Duration(days: 3)).toIso8601String();
  await file.writeAsString(jsonEncode(json));
}

/// The app's own front door, with the tab bar under it.
Future<void> _launchHome(WidgetTester t, SportType sport, Locale locale) async {
  await _launch(t, sport, locale, const MainShell());
  // The home page reads its drills, its saved boards and its recents off
  // disk; shot the moment it pumps, it is a page of empty sections.
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
  await t.pumpAndSettle();
}

Future<void> _launchSport(WidgetTester t, SportType sport, Locale locale) =>
    _launch(t, sport, locale, const TacticsBoardHomePage());

/// The app, at [home], in [locale].
Future<void> _launch(WidgetTester t, SportType sport, Locale locale,
    Widget home) async {
  await EasyLocalization.ensureInitialized();
  // The figures, the ball and the equipment decode like any other asset. A
  // test that shoots the moment it pumps catches the board drawn with the
  // circle-and-oval fallback instead — which is what a single-scene run did.
  await t.runAsync(PlayerArt.warm);
  await t.pumpWidget(
    EasyLocalization(
      supportedLocales: _supportedLocales,
      // packageAsset, not a bare path. Since the sports were split into
      // packages the shots have to be taken from the app being shipped —
      // the core builds without a ball on the pitch, because a sport's
      // artwork is a dev dependency there — and in a shell every asset of
      // the core sits under packages/tactics_board/. With the bare path
      // nothing loaded, so the shot came out a blank frame.
      path: packageAsset('assets/translations'),
      fallbackLocale: const Locale('en', 'US'),
      startLocale: locale,
      child: Builder(builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => TacticsState(sportType: sport)..restoreWorkingBoard(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: locale,
            theme: _theme(),
            home: home,
          ),
        );
      }),
    ),
  );
  await t.pumpAndSettle();
}

ThemeData _theme() => ThemeData(
      colorScheme:
          ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      sliderTheme: const SliderThemeData(
        thumbColor: Colors.blue,
        activeTrackColor: Colors.blue,
        inactiveTrackColor: Colors.white24,
      ),
    );

TacticsState _state(WidgetTester t) {
  final ctx = t.element(find.byType(TacticsBoardHomePage));
  return Provider.of<TacticsState>(ctx, listen: false);
}

Future<void> _shot(IntegrationTestWidgetsFlutterBinding b, String name) async {
  await b.convertFlutterSurfaceToImage();
  await Future.delayed(const Duration(milliseconds: 300));
  final bytes = await b.takeScreenshot(name);
  final dir = Directory('$outDir/${name.substring(0, name.lastIndexOf('/'))}');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final f = File('$outDir/$name.png');
  await f.writeAsBytes(bytes);
  print('📸 $name (${(bytes.length / 1024).toStringAsFixed(0)} KB)');
}
