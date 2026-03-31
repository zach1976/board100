import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/models/drawing_stroke.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/pages/sport_selection_page.dart';

final outDir = '/Users/zhenyusong/Desktop/projects/board100/tactics_board/aso/screenshots_raw';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshots', () {
    // ═══ TACTICS BOARD — Sport Selection ═══
    testWidgets('tactics_board_s1', (t) async {
      await _launchSelection(t);
      await _shot(binding, 'tactics_board_s1_sport_selection');
    });

    // ═══ SOCCER ═══
    testWidgets('soccer_s1', (t) async {
      await _launchSport(t, SportType.soccer);
      final s = _state(t);
      s.applyFormation(SportType.soccer.formations[0]); // 4-4-2
      await t.pumpAndSettle();
      await _shot(binding, 'soccer_s1_hero');
    });

    testWidgets('soccer_s2', (t) async {
      await _launchSport(t, SportType.soccer);
      final s = _state(t);
      s.applyFormation(SportType.soccer.formations[1]); // 4-3-3
      await t.pumpAndSettle();
      s.setDrawingMode(true);
      s.setStrokeColor(const Color(0xFFFFD600));
      s.setArrowStyle(ArrowStyle.end);
      s.setStrokeStyle(StrokeStyle.solid);
      s.setStrokeWidth(3.0);
      _draw(s, 0.35, 0.70, 0.50, 0.55); // pass from left mid
      _draw(s, 0.50, 0.55, 0.70, 0.35); // through ball
      s.setStrokeColor(const Color(0xFF43A047)); // green
      _draw(s, 0.65, 0.68, 0.72, 0.40); // run
      s.setStrokeStyle(StrokeStyle.dashed);
      s.setStrokeColor(Colors.white);
      s.setArrowStyle(ArrowStyle.none);
      _draw(s, 0.20, 0.44, 0.55, 0.44); // defensive line
      await t.pumpAndSettle();
      await _shot(binding, 'soccer_s2_drawing');
    });

    testWidgets('soccer_s3', (t) async {
      await _launchSport(t, SportType.soccer);
      final s = _state(t);
      s.applyFormation(SportType.soccer.formations[1]); // 4-3-3
      await t.pumpAndSettle();
      final c = s.canvasSize;
      final home = s.players.where((p) => p.team == PlayerTeam.home).toList();
      if (home.length >= 4) {
        // Forward: 2-step run up the pitch
        _move(s, home[0], 0.0, -0.12, c);
        _move(s, home[0], 0.08, -0.22, c);
        // Midfielder push right
        _move(s, home[2], 0.1, -0.08, c);
        // Winger: 2-step cut inside
        _move(s, home[3], -0.05, -0.15, c);
        _move(s, home[3], 0.05, -0.25, c);
      }
      await t.pumpAndSettle();
      await _shot(binding, 'soccer_s3_animation');
    });

    testWidgets('soccer_s4_futsal', (t) async {
      await _launchSport(t, SportType.soccer);
      final s = _state(t);
      // 5v5 futsal
      final futsal = SportType.soccer.formations.firstWhere(
        (f) => f.homePositions.length == 5,
        orElse: () => SportType.soccer.formations.last,
      );
      s.applyFormation(futsal);
      await t.pumpAndSettle();
      await _shot(binding, 'soccer_s4_futsal');
    });

    // ═══ BASKETBALL ═══
    testWidgets('basketball_s1', (t) async {
      await _launchSport(t, SportType.basketball);
      final s = _state(t);
      s.applyFormation(SportType.basketball.formations[0]); // 1-2-2
      await t.pumpAndSettle();
      await _shot(binding, 'basketball_s1_hero');
    });

    testWidgets('basketball_s2', (t) async {
      await _launchSport(t, SportType.basketball);
      final s = _state(t);
      s.applyFormation(SportType.basketball.formations[0]);
      await t.pumpAndSettle();
      s.setDrawingMode(true);
      s.setStrokeColor(const Color(0xFFFFD600));
      s.setArrowStyle(ArrowStyle.end);
      _draw(s, 0.50, 0.62, 0.30, 0.48); // screen
      _draw(s, 0.30, 0.48, 0.55, 0.35); // cut
      s.setStrokeColor(const Color(0xFFE53935)); // red
      _draw(s, 0.70, 0.62, 0.55, 0.45); // roll
      s.setStrokeStyle(StrokeStyle.dashed);
      s.setStrokeColor(Colors.white);
      _draw(s, 0.55, 0.35, 0.65, 0.25); // pass option
      await t.pumpAndSettle();
      await _shot(binding, 'basketball_s2_drawing');
    });

    testWidgets('basketball_s3', (t) async {
      await _launchSport(t, SportType.basketball);
      final s = _state(t);
      s.applyFormation(SportType.basketball.formations[0]);
      await t.pumpAndSettle();
      final c = s.canvasSize;
      final home = s.players.where((p) => p.team == PlayerTeam.home).toList();
      if (home.length >= 3) {
        _move(s, home[0], 0.15, -0.15, c);
        _move(s, home[1], -0.12, -0.10, c);
        _move(s, home[2], 0.05, -0.20, c);
      }
      await t.pumpAndSettle();
      await _shot(binding, 'basketball_s3_animation');
    });

    testWidgets('basketball_s4_3v3', (t) async {
      await _launchSport(t, SportType.basketball);
      final s = _state(t);
      s.applyFormation(SportType.basketball.formations.last); // 3v3
      await t.pumpAndSettle();
      await _shot(binding, 'basketball_s4_3v3');
    });

    // ═══ VOLLEYBALL ═══
    testWidgets('volleyball_s1', (t) async {
      await _launchSport(t, SportType.volleyball);
      final s = _state(t);
      s.applyFormation(SportType.volleyball.formations[0]);
      await t.pumpAndSettle();
      await _shot(binding, 'volleyball_s1_hero');
    });

    testWidgets('volleyball_s2', (t) async {
      await _launchSport(t, SportType.volleyball);
      final s = _state(t);
      s.applyFormation(SportType.volleyball.formations[0]);
      await t.pumpAndSettle();
      s.setDrawingMode(true);
      s.setStrokeColor(const Color(0xFFFFD600));
      s.setArrowStyle(ArrowStyle.end);
      _draw(s, 0.30, 0.62, 0.50, 0.38); // attack 1
      _draw(s, 0.70, 0.62, 0.50, 0.38); // attack 2
      s.setStrokeColor(const Color(0xFF43A047));
      _draw(s, 0.50, 0.58, 0.35, 0.38); // setter
      await t.pumpAndSettle();
      await _shot(binding, 'volleyball_s2_drawing');
    });

    testWidgets('volleyball_s3', (t) async {
      await _launchSport(t, SportType.volleyball);
      final s = _state(t);
      s.applyFormation(SportType.volleyball.formations[0]);
      await t.pumpAndSettle();
      final c = s.canvasSize;
      final home = s.players.where((p) => p.team == PlayerTeam.home).toList();
      if (home.length >= 3) {
        _move(s, home[0], 0.1, -0.1, c);
        _move(s, home[1], -0.08, -0.12, c);
        _move(s, home[2], 0.0, -0.15, c);
      }
      await t.pumpAndSettle();
      await _shot(binding, 'volleyball_s3_animation');
    });

    // ═══ BADMINTON ═══
    testWidgets('badminton_s1', (t) async {
      await _launchSport(t, SportType.badminton);
      final s = _state(t);
      s.applyFormation(SportType.badminton.formations.last); // doubles
      await t.pumpAndSettle();
      await _shot(binding, 'badminton_s1_hero');
    });

    testWidgets('badminton_s2', (t) async {
      await _launchSport(t, SportType.badminton);
      final s = _state(t);
      s.applyFormation(SportType.badminton.formations.last);
      await t.pumpAndSettle();
      s.setDrawingMode(true);
      s.setStrokeColor(const Color(0xFFFFD600));
      s.setArrowStyle(ArrowStyle.end);
      _draw(s, 0.35, 0.65, 0.65, 0.35); // cross court
      _draw(s, 0.65, 0.35, 0.35, 0.30); // drop
      s.setStrokeColor(const Color(0xFF43A047));
      _draw(s, 0.60, 0.60, 0.40, 0.40); // straight
      await t.pumpAndSettle();
      await _shot(binding, 'badminton_s2_drawing');
    });

    testWidgets('badminton_s3', (t) async {
      await _launchSport(t, SportType.badminton);
      final s = _state(t);
      s.applyFormation(SportType.badminton.formations.last);
      await t.pumpAndSettle();
      final c = s.canvasSize;
      final home = s.players.where((p) => p.team == PlayerTeam.home).toList();
      if (home.length >= 2) {
        _move(s, home[0], 0.15, -0.12, c);
        _move(s, home[0], 0.10, -0.25, c);
        _move(s, home[1], -0.10, -0.15, c);
        _move(s, home[1], 0.05, -0.28, c);
      }
      await t.pumpAndSettle();
      await _shot(binding, 'badminton_s3_animation');
    });

    // ═══ TENNIS ═══
    testWidgets('tennis_s1', (t) async {
      await _launchSport(t, SportType.tennis);
      final s = _state(t);
      s.applyFormation(SportType.tennis.formations.last); // doubles
      await t.pumpAndSettle();
      await _shot(binding, 'tennis_s1_hero');
    });

    testWidgets('tennis_s2', (t) async {
      await _launchSport(t, SportType.tennis);
      final s = _state(t);
      s.applyFormation(SportType.tennis.formations[0]); // singles
      await t.pumpAndSettle();
      s.setDrawingMode(true);
      s.setStrokeColor(const Color(0xFFFFD600));
      s.setArrowStyle(ArrowStyle.end);
      _draw(s, 0.50, 0.82, 0.30, 0.32); // serve wide
      _draw(s, 0.50, 0.82, 0.65, 0.30); // serve T
      s.setStrokeColor(const Color(0xFF43A047));
      _draw(s, 0.50, 0.82, 0.50, 0.28); // serve body
      await t.pumpAndSettle();
      await _shot(binding, 'tennis_s2_serve');
    });

    // ═══ TABLE TENNIS ═══
    testWidgets('tabletennis_s1', (t) async {
      await _launchSport(t, SportType.tableTennis);
      final s = _state(t);
      s.applyFormation(SportType.tableTennis.formations.last); // doubles
      await t.pumpAndSettle();
      await _shot(binding, 'tabletennis_s1_hero');
    });

    testWidgets('tabletennis_s2', (t) async {
      await _launchSport(t, SportType.tableTennis);
      final s = _state(t);
      s.applyFormation(SportType.tableTennis.formations[0]); // singles
      await t.pumpAndSettle();
      s.setDrawingMode(true);
      s.setStrokeColor(const Color(0xFFFFD600));
      s.setArrowStyle(ArrowStyle.end);
      _draw(s, 0.40, 0.62, 0.60, 0.38); // serve 1
      _draw(s, 0.40, 0.62, 0.30, 0.35); // serve 2
      await t.pumpAndSettle();
      await _shot(binding, 'tabletennis_s2_serve');
    });

    // ═══ PICKLEBALL ═══
    testWidgets('pickleball_s1', (t) async {
      await _launchSport(t, SportType.pickleball);
      final s = _state(t);
      s.applyFormation(SportType.pickleball.formations.last); // doubles
      await t.pumpAndSettle();
      await _shot(binding, 'pickleball_s1_hero');
    });

    testWidgets('pickleball_s2', (t) async {
      await _launchSport(t, SportType.pickleball);
      final s = _state(t);
      s.applyFormation(SportType.pickleball.formations.last);
      await t.pumpAndSettle();
      s.setDrawingMode(true);
      s.setStrokeColor(const Color(0xFFFFD600));
      s.setArrowStyle(ArrowStyle.end);
      _draw(s, 0.35, 0.55, 0.60, 0.45); // dink cross
      _draw(s, 0.60, 0.45, 0.40, 0.52); // dink back
      s.setStrokeColor(const Color(0xFF43A047));
      _draw(s, 0.65, 0.75, 0.45, 0.48); // 3rd shot drop
      await t.pumpAndSettle();
      await _shot(binding, 'pickleball_s2_drawing');
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> _launchSelection(WidgetTester t) async {
  await EasyLocalization.ensureInitialized();
  await t.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: const Locale('en', 'US'),
      child: Builder(builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => TacticsState(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: const Locale('en', 'US'),
            theme: _theme(),
            home: const SportSelectionPage(),
          ),
        );
      }),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _launchSport(WidgetTester t, SportType sport) async {
  await EasyLocalization.ensureInitialized();
  await t.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: const Locale('en', 'US'),
      child: Builder(builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => TacticsState(sportType: sport),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: const Locale('en', 'US'),
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

/// Add a move waypoint relative to player's current position (dx/dy in 0-1 range)
void _move(TacticsState s, PlayerIcon p, double dx, double dy, Size canvas) {
  s.addPlayerMove(p.id, Offset(
    p.position.dx + dx * canvas.width,
    p.position.dy + dy * canvas.height,
  ));
}

Future<void> _shot(IntegrationTestWidgetsFlutterBinding b, String name) async {
  await b.convertFlutterSurfaceToImage();
  await Future.delayed(const Duration(milliseconds: 300));
  final bytes = await b.takeScreenshot(name);
  final f = File('$outDir/$name.png');
  await f.writeAsBytes(bytes);
  print('📸 $name (${(bytes.length / 1024).toStringAsFixed(0)} KB)');
}
