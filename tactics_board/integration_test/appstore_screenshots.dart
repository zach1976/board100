import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/models/drawing_stroke.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/pages/sport_selection_page.dart';
import 'package:tactics_board/widgets/timeline_editor.dart';

final outDir = '/Users/zhenyusong/Desktop/projects/board100/tactics_board/aso/screenshots_localized';

final allLocales = [
  ('en-US', const Locale('en', 'US')),
  ('zh-Hans', const Locale('zh', 'CN')),
  ('ja', const Locale('ja', 'JP')),
  ('ko', const Locale('ko', 'KR')),
  ('zh-Hant', const Locale('zh', 'TW')),
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Localized Screenshots', () {
    // ═══ Sport Selection Page (all languages) ═══
    for (final (lang, locale) in allLocales) {
      testWidgets('selection_$lang', (t) async {
        await _launchSelection(t, locale);
        await _shot(binding, 'tactics_board/$lang/s1_sport_selection');
      });
    }

    // ═══ Per-sport screenshots (6 each) ═══
    for (final sport in SportType.values) {
      final sn = sport.name;
      for (final (lang, locale) in allLocales) {
        // s1: Initial empty court
        testWidgets('${sn}_${lang}_s1', (t) async {
          await _launchSport(t, sport, locale);
          await _shot(binding, '$sn/$lang/s1_empty');
        });

        // s2: Formation applied
        testWidgets('${sn}_${lang}_s2', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          if (sport.formations.isNotEmpty) {
            s.applyFormation(sport.formations[0]);
          }
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s2_formation');
        });

        // s3: Drawing annotations
        testWidgets('${sn}_${lang}_s3', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          if (sport.formations.isNotEmpty) {
            s.applyFormation(sport.formations.length > 1 ? sport.formations[1] : sport.formations[0]);
          }
          await t.pumpAndSettle();
          s.setDrawingMode(true);
          s.setStrokeColor(const Color(0xFFFFD600));
          s.setArrowStyle(ArrowStyle.end);
          s.setStrokeStyle(StrokeStyle.solid);
          s.setStrokeWidth(3.0);
          _draw(s, 0.35, 0.65, 0.60, 0.40);
          _draw(s, 0.65, 0.60, 0.45, 0.35);
          s.setStrokeColor(const Color(0xFF43A047));
          _draw(s, 0.50, 0.70, 0.50, 0.45);
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s3_drawing');
        });

        // s4: Moves added — home player 1 moves 3 times, home player 2 moves 3 times
        testWidgets('${sn}_${lang}_s4', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          _setupFormationAndMoves(s, sport);
          s.selectPlayer(null);
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s4_moves');
        });

        // s5: Timeline editor — court visible with timeline panel pinned at bottom
        testWidgets('${sn}_${lang}_s5', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          _setupFormationAndMoves(s, sport);
          s.selectPlayer(null);
          await t.pumpAndSettle();
          await t.tap(find.byIcon(Icons.view_timeline));
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s5_timeline');
        });

        // s6: Step-by-step playback — at step 2
        testWidgets('${sn}_${lang}_s6', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          _setupFormationAndMoves(s, sport);
          s.selectPlayer(null);
          // Step forward twice
          s.stepForward();
          s.stepForward();
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s6_playback');
        });
      }
    }
  });
}

/// Setup formation + moves + sequential phases
void _setupFormationAndMoves(TacticsState s, SportType sport) {
  if (sport.formations.isNotEmpty) {
    s.applyFormation(sport.formations[0]);
  }
  final c = s.canvasSize;
  final home = s.players.where((p) => p.team == PlayerTeam.home).toList();
  if (home.isNotEmpty) {
    _addMovesToState(s, sport, home);
  }
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
    // Sequential phases: p1 on 0,2,4; p2 on 1,3,5
    s.setMovePhase(p1.id, 0, 0);
    s.setMovePhase(p1.id, 1, 2);
    s.setMovePhase(p1.id, 2, 4);
    s.setMovePhase(p2.id, 0, 1);
    s.setMovePhase(p2.id, 1, 3);
    s.setMovePhase(p2.id, 2, 5);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════════

final _supportedLocales = allLocales.map((e) => e.$2).toList();

Future<void> _launchSelection(WidgetTester t, Locale locale) async {
  await EasyLocalization.ensureInitialized();
  await t.pumpWidget(
    EasyLocalization(
      supportedLocales: _supportedLocales,
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: locale,
      child: Builder(builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => TacticsState(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: locale,
            theme: _theme(),
            home: const SportSelectionPage(),
          ),
        );
      }),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _launchSport(WidgetTester t, SportType sport, Locale locale) async {
  await EasyLocalization.ensureInitialized();
  await t.pumpWidget(
    EasyLocalization(
      supportedLocales: _supportedLocales,
      path: 'assets/translations',
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
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
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

void _draw(TacticsState s, double fx, double fy, double tx, double ty) {
  final c = s.canvasSize;
  final from = Offset(fx * c.width, fy * c.height);
  final to = Offset(tx * c.width, ty * c.height);
  s.startStroke(from);
  for (int i = 1; i <= 8; i++) {
    s.addPoint(Offset.lerp(from, to, i / 8.0)!);
  }
  s.endStroke();
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
