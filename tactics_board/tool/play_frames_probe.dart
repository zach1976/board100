import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/painters/player_moves_painter.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';
import 'package:tactics_board/widgets/tactics_canvas.dart';

import '../test/widgets/overflow_test.dart' show kLocales;

/// Shoots frames of a drill playing through, for looking at an animation
/// that cannot be seen in a still: which beat the ghosts think is on show,
/// where the ball's line starts mid-flight, what a badge is doing. Writes
/// PNGs to the scratchpad directory named in the file.
///
///     flutter test tool/play_frames_probe.dart
///
/// In tool/, not test/: it is a way of looking, not a check.
void main() {
  testWidgets('probe: frames of play-all on transition_6v6', (tester) async {
    // A dev script driving the real app headless, the same as render_boards.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'remove_ads_pro': true});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(402 * 2, 730 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final state = TacticsState();
    final key = GlobalKey();
    await tester.pumpWidget(EasyLocalization(
      supportedLocales: kLocales, path: 'assets/translations', saveLocale: false,
      fallbackLocale: const Locale('en', 'US'),
      child: Builder(builder: (context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales, locale: context.locale,
        home: ChangeNotifierProvider<TacticsState>.value(value: state,
          child: Scaffold(body: Center(child: RepaintBoundary(key: key,
            child: const SizedBox(width: 402, height: 730, child: TacticsCanvas()))))),
      )),
    ));
    await tester.runAsync(PlayerArt.warm);
    await tester.pump(const Duration(milliseconds: 300));
    final data = jsonDecode(File('assets/drills/soccer.json').readAsStringSync()) as Map<String, dynamic>;
    final drill = (data['drills'] as List).cast<Map<String, dynamic>>().firstWhere((d) => d['id'] == 'transition_6v6');
    state.loadFromJson(Map<String, dynamic>.from(drill['board'] as Map));
    state.setCanvasSizeSilent(const Size(402, 730));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await tester.pump(const Duration(milliseconds: 60));
    state.setShowMoveLines(true);
    // Two steps done, then the third — the shot — the way the › button does it.
    state.stepForward();
    await tester.pump();
    const dir = '/private/tmp/claude-501/-Users-zhenyusong-projects-board100/f8f07df9-0abc-4cbc-a570-256f66abef17/scratchpad/frames';
    Directory(dir).createSync(recursive: true);
    var elapsed = 0;
    for (final ms in [16, 16, 50, 100, 100, 100, 100, 100, 100, 100]) {
      await tester.pump(Duration(milliseconds: ms));
      elapsed += ms;
      // ignore: avoid_print
      print('PROBE t=${elapsed}ms atStep=${state.atStep} target=${state.targetStep} animating=${state.isAnimating} lines=${state.showMoveLines} animPos=${state.animatedPositions.length}');
      {
        final c = state.players.firstWhere((p) => p.label == 'C');
        final cx6 = state.players.firstWhere((p) => p.label == 'X6');
        String where(PlayerIcon p) {
          final keyed = find.byKey(ValueKey(p.id));
          var w = tester.widgetList<Positioned>(find.descendant(of: keyed, matching: find.byType(Positioned))).toList();
          if (w.isEmpty) w = tester.widgetList<Positioned>(find.ancestor(of: keyed, matching: find.byType(Positioned))).toList();
          return 'anim=${state.animatedPositions[p.id]} drawn=${w.isEmpty ? '?' : '(${w.first.left?.toStringAsFixed(1)},${w.first.top?.toStringAsFixed(1)})'}';
        }
        final ghostC = find.byKey(const ValueKey('ghost_d2')).evaluate().length;
        final ghostF = find.byKey(const ValueKey('ghost_d5')).evaluate().length;
        final ghostB = find.byKey(const ValueKey('ghost_b0')).evaluate().length;
        int? shown;
        for (final cp in tester.widgetList<CustomPaint>(find.byType(CustomPaint))) {
          final pm = cp.painter;
          if (pm is PlayerMovesPainter && pm.startShift.isNotEmpty) shown = pm.completedSteps;
        }
        final f = state.players.firstWhere((p) => p.label == 'F');
        final fAnim = state.animatedPositions[f.id];
        final beat = state.isAnimating ? (state.animToStep > state.animFromStep ? (state.atStep + 1 < state.animToStep ? state.atStep + 1 : state.animToStep) : (state.atStep > 1 ? state.atStep : 1)) : (state.atStep > 0 ? state.atStep : state.targetStep);
        final moving = fAnim != null && (fAnim - chainEndAt(f, state.atStep)).distance > 0.5;
        final b = state.players.firstWhere((p) => p.isBall);
        final bAnim = state.animatedPositions[b.id];
        var bw = tester.widgetList<Positioned>(find.descendant(of: find.byKey(ValueKey(b.id)), matching: find.byType(Positioned))).toList();
        if (bw.isEmpty) bw = tester.widgetList<Positioned>(find.ancestor(of: find.byKey(ValueKey(b.id)), matching: find.byType(Positioned))).toList();
        final drawn = bw.isEmpty ? null : Offset(bw.first.left! + 22, bw.first.top! + 22);
        String near = '';
        if (bAnim != null) {
          double best = 1e9;
          for (final q in state.players) { if (q.isBall || q.isMarker) continue; final d = ((state.animatedPositions[q.id] ?? chainEndAt(q, state.atStep)) - bAnim).distance; if (d < best) { best = d; near = '${q.label}@${d.toStringAsFixed(0)}'; } }
        }
        // ignore: avoid_print
        print('PROBE BALL anim=${bAnim == null ? null : '(${bAnim.dx.toStringAsFixed(1)},${bAnim.dy.toStringAsFixed(1)})'} drawn=${drawn == null ? null : '(${drawn.dx.toStringAsFixed(1)},${drawn.dy.toStringAsFixed(1)})'} shift=${(bAnim != null && drawn != null) ? (drawn - bAnim).distance.toStringAsFixed(1) : '?'} nearest=$near');
        // ignore: avoid_print
        print('PROBE F anim=$fAnim moving=$moving beat=$beat boardHeading=${boardHeading(state.players, f, beat)?.toStringAsFixed(2)} runHeading=${fAnim == null ? null : playerHeadingAt(f, fAnim)?.toStringAsFixed(2)} ghostC=$ghostC ghostF=$ghostF ghostBall=$ghostB painterBeat=$shown');
      }
      if (elapsed == 2300 || elapsed == 2500) {
        final ball = state.players.firstWhere((p) => p.isBall);
        for (final cp in tester.widgetList<CustomPaint>(find.byType(CustomPaint))) {
          final pm = cp.painter;
          if (pm is! PlayerMovesPainter || pm.startShift.isEmpty && pm.endShift.isEmpty && pm.livePos.isEmpty) continue;
          final lim = pm.completedSteps ?? pm.targetStep;
          // ignore: avoid_print
          print('PROBE@$elapsed completedSteps=${pm.completedSteps} targetStep=${pm.targetStep} '
              'stepStart(ball,lim)=${stepStart(ball, lim)} startShift=${pm.startShift[ball.id]} '
              'livePos=${pm.livePos[ball.id]} anim=${state.animatedPositions[ball.id]} endShift=${pm.endShift[ball.id]} '
              'legs=${stepLegs(ball, lim).map((e) => e.value).toList()}');
        }
      }
      await tester.runAsync(() async {
        final ro = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await ro.toImage(pixelRatio: 2);
        final png = await img.toByteData(format: ImageByteFormat.png);
        File('$dir/f_${elapsed.toString().padLeft(4, '0')}.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  });
}
