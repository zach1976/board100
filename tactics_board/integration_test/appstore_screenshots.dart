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
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart' show PlayerArt;
import 'package:tactics_board/widgets/toolbar.dart';

// V2 raw app screenshots for the "PLAN EVERY RALLY" design.
// Output: aso/screenshots_v2_raw/<sport>/<locale>/s{1..6}.png
// 6-shot story: empty · formation · timeline · add-menu · routes · playback.
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
  SharedPreferences.setMockInitialValues({'flutter.board_hint_seen': true});
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
        // s1: empty court
        testWidgets('${sn}_${lang}_s1', (t) async {
          await _launchSport(t, sport, locale);
          await _shot(binding, '$sn/$lang/s1');
        });

        // s2: formation (players placed)
        testWidgets('${sn}_${lang}_s2', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          if (sport.formations.isNotEmpty) s.applyFormation(sport.formations[0]);
          s.clearMultiSelect();
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s2');
        });

        // s3: timeline editor
        testWidgets('${sn}_${lang}_s3', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          _setupFormationAndMoves(s, sport);
          s.selectPlayer(null);
          await t.pumpAndSettle();
          // The outlined variant: the play bar's button, which is what the
          // filled Icons.view_timeline stopped being some releases ago.
          await t.tap(find.byIcon(Icons.view_timeline_outlined));
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s3');
        });

        // s4: Add-element bottom sheet (match setups), over a board in use —
        // opened on an empty pitch the top half of the shot is grass.
        testWidgets('${sn}_${lang}_s4', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          if (sport.formations.isNotEmpty) s.applyFormation(sport.formations[0]);
          s.clearMultiSelect();
          await t.pumpAndSettle();
          final ctx = t.element(find.byType(TacticsBoardHomePage));
          showAddElementSheet(ctx, s);
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s4');
        });

        // s5: a real drill off the shelf, one beat in — a pass drawn from
        // the ball to the man it is played to, the cones that make the
        // shape, the names under the players. The hand-built formation this
        // used to show had no ball on it at all, which on a tactics board's
        // own store page is the one thing a coach looks for.
        testWidgets('${sn}_${lang}_s5', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          final drill = await _showcase(t, sport);
          if (drill == null) {
            _setupFormationAndMoves(s, sport);
          } else {
            s.loadFromJson(Map<String, dynamic>.from(drill.board));
            s.setShowMoveLines(true);
            // advanceAtStep, not setTargetStep: the board reads either, but
            // the counter on the bar reads atStep, and a shot captioned 0/8
            // over a board three beats in is a shot of a bug.
            s.advanceAtStep(1);
          }
          s.selectPlayer(null);
          s.clearMultiSelect();
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s5');
        });

        // s6: the same drill two beats further on — where the players have
        // got to, and the faint tokens they left behind.
        testWidgets('${sn}_${lang}_s6', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          final drill = await _showcase(t, sport);
          if (drill == null) {
            _setupFormationAndMoves(s, sport);
            s.stepForward();
            s.stepForward();
          } else {
            s.loadFromJson(Map<String, dynamic>.from(drill.board));
            s.setShowMoveLines(true);
            s.advanceAtStep(3);
          }
          s.selectPlayer(null);
          s.clearMultiSelect();
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s6');
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

Future<void> _launchSport(WidgetTester t, SportType sport, Locale locale) async {
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
          create: (_) => TacticsState(sportType: sport),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: locale,
            theme: _theme(),
            home: const TacticsBoardHomePage(),
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
