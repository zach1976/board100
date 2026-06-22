import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/widgets/toolbar.dart';

// V2 raw app screenshots for the "PLAN EVERY RALLY" design.
// Output: aso/screenshots_v2_raw/<sport>/<locale>/s{1..6}.png
// 6-shot story: empty · formation · timeline · add-menu · routes · playback.
final outDir =
    '/Users/zhenyusong/Desktop/projects/board100/tactics_board/aso/screenshots_v2_raw';

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
          await t.tap(find.byIcon(Icons.view_timeline));
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s3');
        });

        // s4: Add-element bottom sheet (match setups)
        testWidgets('${sn}_${lang}_s4', (t) async {
          await _launchSport(t, sport, locale);
          final ctx = t.element(find.byType(TacticsBoardHomePage));
          showAddElementSheet(ctx, _state(t));
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s4');
        });

        // s5: routes / moves with arrows
        testWidgets('${sn}_${lang}_s5', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          _setupFormationAndMoves(s, sport);
          s.selectPlayer(null);
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s5');
        });

        // s6: step-by-step playback (at step 2)
        testWidgets('${sn}_${lang}_s6', (t) async {
          await _launchSport(t, sport, locale);
          final s = _state(t);
          _setupFormationAndMoves(s, sport);
          s.selectPlayer(null);
          s.stepForward();
          s.stepForward();
          await t.pumpAndSettle();
          await _shot(binding, '$sn/$lang/s6');
        });
      }
    }
  });
}

void _setupFormationAndMoves(TacticsState s, SportType sport) {
  if (sport.formations.isNotEmpty) s.applyFormation(sport.formations[0]);
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
