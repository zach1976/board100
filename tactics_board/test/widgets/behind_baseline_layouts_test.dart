import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/painters/court_art.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

import 'overflow_test.dart' show kLocales;

/// A man standing behind a baseline is drawn whole, on the board, and behind
/// the line — in every layout the app shows, not only the portrait phone
/// board the drills are written on (tools/check_baselines.py).
///
/// The figure is drawn upright on the SCREEN, 26 x 52 pt times the board's
/// figure scale, centred on his point. Sideways (a phone or an iPad turned)
/// the canvas sits in a RotatedBox, so the figure's long side runs across the
/// court; on an iPad the figure grows with the board (boardFigureScaleFor)
/// while the court grows with the canvas. Every person of every board of the
/// four sports whose players stand behind the baseline, at every step, in
/// four layouts: the whole figure on the visible board, and anyone whose
/// point is behind a baseline with his figure clear of that line on the
/// court side: a far man by his feet (his whole figure), and sideways —
/// where the feet are at his point — the serve's near server and receiver
/// too.
///
/// `SHOTS=<dir>` also writes a screenshot of a few boards in each layout.
const _sports = [
  SportType.tennis,
  SportType.pickleball,
  SportType.beachTennis,
  SportType.volleyball,
];

const _shots = {
  'tn_serve_deuce_wide',
  'pb_serve_deep_backhand',
  'bt_serve_flat',
  'vb_receive_r1',
  'vb_serve_float_deep',
};

/// The boards that open with a serve (tools/check_baselines.py).
final _serveDrills = {
  SportType.tennis: RegExp(r'serve|return|_game_'),
  SportType.beachTennis: RegExp(r'serve|return|_game_'),
  SportType.volleyball: RegExp(r'serve|receive|_game_'),
  SportType.pickleball: RegExp(r''),
};

class _Layout {
  const _Layout(this.name, this.size, this.dpr, this.padding);
  final String name;
  final Size size;
  final double dpr;
  final FakeViewPadding padding;
}

const _layouts = [
  _Layout('phone_portrait', Size(402, 874), 3,
      FakeViewPadding(top: 62 * 3, bottom: 34 * 3)),
  _Layout('phone_landscape', Size(874, 402), 3,
      FakeViewPadding(left: 62 * 3, right: 62 * 3, bottom: 21 * 3)),
  _Layout('ipad_portrait', Size(1032, 1376), 2,
      FakeViewPadding(top: 24 * 2, bottom: 20 * 2)),
  _Layout('ipad_landscape', Size(1376, 1032), 2,
      FakeViewPadding(top: 24 * 2, bottom: 20 * 2)),
];

Offset _at(PlayerIcon p, int step) {
  var pos = p.position;
  for (var i = 0; i < p.moves.length && i < p.movePhases.length; i++) {
    if (p.movePhases[i] < step) pos = p.moves[i];
  }
  return pos;
}

void main() {
  testWidgets('behind the baseline, whole and on the board, in every layout',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'board_hint_seen': true,
      'intro_seen': true,
      'remove_ads_pro': true,
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await EasyLocalization.ensureInitialized();
    addTearDown(tester.view.reset);
    final shotsDir = Platform.environment['SHOTS'];
    if (shotsDir != null) {
      await tester.runAsync(PlayerArt.warm);
      await tester.runAsync(CourtArt.warm);
    }

    final problems = <String>[];
    var checked = 0;
    for (final layout in _layouts) {
      tester.view.physicalSize = layout.size * layout.dpr;
      tester.view.devicePixelRatio = layout.dpr;
      tester.view.padding = layout.padding;
      tester.view.viewPadding = layout.padding;
      for (final sport in _sports) {
        final state = TacticsState(sportType: sport);
        final screenKey = GlobalKey();
        // A fresh tree per board shape (board_on_the_court_test.dart).
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(
          RepaintBoundary(
            key: screenKey,
            child: EasyLocalization(
              supportedLocales: kLocales,
              path: 'assets/translations',
              saveLocale: false,
              startLocale: const Locale('en', 'US'),
              fallbackLocale: const Locale('en', 'US'),
              child: ChangeNotifierProvider<TacticsState>.value(
                value: state,
                child: Builder(
                  builder: (context) => MaterialApp(
                    debugShowCheckedModeBanner: false,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: context.locale,
                    home: const TacticsBoardHomePage(),
                  ),
                ),
              ),
            ),
          ),
        );
        for (var i = 0;
            i < 40 && boardRepaintKey.currentContext == null;
            i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pump(const Duration(milliseconds: 100));
        final board =
            boardRepaintKey.currentContext!.findRenderObject() as RenderBox;
        final canvas = board.size;
        state.setCanvasSizeSilent(canvas);
        // What is visible of the board, on the screen.
        final c0 = board.localToGlobal(Offset.zero);
        final c1 = board.localToGlobal(Offset(canvas.width, canvas.height));
        final onScreen = Rect.fromPoints(c0, c1);
        // Turned: the canvas's x axis runs down the screen.
        final sideways =
            (board.localToGlobal(Offset(canvas.width, 0)).dy - c0.dy).abs() >
                1;
        final field = sport.fieldRect(canvas);
        final k0 =
            boardFigureScaleFor(canvas, sport: sport, sideways: sideways);

        final lib = jsonDecode(
                File('assets/drills/${sport.name}.json').readAsStringSync())
            as Map<String, dynamic>;
        for (final raw in lib['drills'] as List) {
          final drill = raw as Map<String, dynamic>;
          final b = drill['board'] as Map<String, dynamic>;
          if (b['viewWindow'] != null) continue;
          state.loadFromJson(Map<String, dynamic>.from(b));
          final k = k0 * state.figureScale;
          final people = state.players
              .where((p) => !p.isBall && !p.isMarker)
              .toList();
          // The serve (tools/check_baselines.py rule 3): its server until
          // he strikes it, its receiver until it arrives.
          final serveUntil = <String, int>{};
          final ball = state.players.where((p) => p.isBall).firstOrNull;
          if (ball != null &&
              _serveDrills[sport]!.hasMatch(drill['id'] as String) &&
              ball.movePhases.isNotEmpty) {
            final struck = ball.movePhases.first;
            if (ball.holder != null) serveUntil[ball.holder!] = struck;
            final to = ball.moveHolders.firstOrNull;
            if (to != null && sport != SportType.volleyball) {
              serveUntil[to] = struck + 1;
            }
          }
          for (var step = 0; step <= state.maxMoveSteps; step++) {
            for (final p in people) {
              final s = k * p.scale;
              final pt = _at(p, step);
              final sp = board.localToGlobal(pt);
              final box = Rect.fromCenter(
                  center: sp, width: 26 * s, height: 52 * s);
              checked++;
              final who = '${layout.name} ${drill['id']} step $step '
                  '${p.label.isEmpty ? p.id : p.label}';
              if (box.left < onScreen.left - 0.5 ||
                  box.top < onScreen.top - 0.5 ||
                  box.right > onScreen.right + 0.5 ||
                  box.bottom > onScreen.bottom + 0.5) {
                problems.add('$who: drawn off the board '
                    '(${box.left.toStringAsFixed(0)},'
                    '${box.top.toStringAsFixed(0)})-'
                    '(${box.right.toStringAsFixed(0)},'
                    '${box.bottom.toStringAsFixed(0)}) on $onScreen');
              }
              // Behind a baseline: the figure's extent along the court's
              // length, measured on the screen.
              final far = pt.dy < field.top;
              final near = pt.dy > field.bottom;
              if (!far && !near) continue;
              final lineY = far ? field.top : field.bottom;
              final onLine = board.localToGlobal(Offset(pt.dx, lineY));
              final along = onLine - sp; // from his point to the line
              // Upright the far man's feet are half a figure below his
              // point, toward the court, and the near man's are behind it.
              // Sideways the figure stands across the court and his feet
              // are at his point: a quarter of the figure's width each way.
              if (near && !sideways) continue;
              // A near man behind his line upright has his feet behind it
              // whatever his point; sideways that is asked of the serve.
              if (near && step > (serveUntil[p.id] ?? -1)) continue;
              final half = sideways ? box.width / 4 : box.height / 2;
              final clear = along.distance - half;
              if (clear < 0.5) {
                problems.add('$who: ${far ? "far" : "near"} figure '
                    '${(-clear).toStringAsFixed(1)} pt over his baseline');
              }
            }
          }
          if (shotsDir != null && _shots.contains(drill['id'])) {
            state.setTargetStep(0);
            await tester.pump(const Duration(milliseconds: 60));
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 300)));
            await tester.pump(const Duration(milliseconds: 60));
            await tester.runAsync(() async {
              final rb = screenKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary;
              final image = await rb.toImage(pixelRatio: 1.0);
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              Directory(shotsDir).createSync(recursive: true);
              File('$shotsDir/${layout.name}-${drill['id']}.png')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
        // ignore: avoid_print
        print('${layout.name} ${sport.name}: canvas $canvas '
            'court ${field.size} figure x${k0.toStringAsFixed(2)} '
            'sideways $sideways');
      }
    }
    // ignore: avoid_print
    print('$checked figures checked, ${problems.length} problems');
    debugDefaultTargetPlatformOverride = null;
    expect(checked, greaterThan(8000));
    expect(problems, isEmpty);
  });
}
