import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/pages/home_page.dart';
import 'package:tactics_board/pages/sport_selection_page.dart';

final outDir =
    '/Users/zhenyusong/Desktop/projects/board100/tactics_board/aso/screenshots_raw';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ═══ TACTICS BOARD — Sport Selection ═══
  testWidgets('tactics_board', (t) async {
    await _launchSelection(t);
    await _shot(binding, 'tactics_board_s1_sport_selection');
  });

  // ═══ BADMINTON ═══
  testWidgets('badminton', (t) async {
    await _launchSport(t, SportType.badminton);
    final state = _state(t);

    await _shot(binding, 'badminton_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'badminton_s2_add_menu');

    // Select doubles formation
    state.applyFormation(SportType.badminton.formations[1]);
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'badminton_s3_formation');

    // Add moves
    final c = state.canvasSize;
    final home = _homePlayers(state);
    state.addPlayerMove(home[0].id, Offset(0.30 * c.width, 0.72 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.25 * c.width, 0.64 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.30 * c.width, 0.56 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.70 * c.width, 0.62 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.72 * c.width, 0.55 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.68 * c.width, 0.52 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'badminton_s4_moves');

    // Timeline: one player per step
    _interleavePhases(state, home[0].id, home[1].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'badminton_s5_timeline');
    await _dismissSheet(t);

    // Playback
    await _stepForwardTwice(t, state);
    await _shot(binding, 'badminton_s6_playback');
  });

  // ═══ TENNIS ═══
  testWidgets('tennis', (t) async {
    await _launchSport(t, SportType.tennis);
    final state = _state(t);

    await _shot(binding, 'tennis_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'tennis_s2_add_menu');

    state.applyFormation(SportType.tennis.formations[1]); // doubles
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'tennis_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Player 1 (right baseline 0.7,0.78): move left along baseline then up
    state.addPlayerMove(home[0].id, Offset(0.55 * c.width, 0.76 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.50 * c.width, 0.70 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.55 * c.width, 0.64 * c.height));
    // Player 2 (left net 0.3,0.60): move right at net
    state.addPlayerMove(home[1].id, Offset(0.45 * c.width, 0.58 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.55 * c.width, 0.56 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.65 * c.width, 0.54 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'tennis_s4_moves');

    _interleavePhases(state, home[0].id, home[1].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'tennis_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'tennis_s6_playback');
  });

  // ═══ TABLE TENNIS ═══
  testWidgets('tableTennis', (t) async {
    await _launchSport(t, SportType.tableTennis);
    final state = _state(t);

    await _shot(binding, 'tabletennis_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'tabletennis_s2_add_menu');

    state.applyFormation(SportType.tableTennis.formations[1]); // doubles
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'tabletennis_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Player 1 (left 0.35,0.90): move left-forward
    state.addPlayerMove(home[0].id, Offset(0.28 * c.width, 0.86 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.22 * c.width, 0.84 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.30 * c.width, 0.82 * c.height));
    // Player 2 (right 0.65,0.90): move right-forward
    state.addPlayerMove(home[1].id, Offset(0.72 * c.width, 0.86 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.78 * c.width, 0.84 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.70 * c.width, 0.82 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'tabletennis_s4_moves');

    _interleavePhases(state, home[0].id, home[1].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'tabletennis_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'tabletennis_s6_playback');
  });

  // ═══ PICKLEBALL ═══
  testWidgets('pickleball', (t) async {
    await _launchSport(t, SportType.pickleball);
    final state = _state(t);

    await _shot(binding, 'pickleball_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'pickleball_s2_add_menu');

    state.applyFormation(SportType.pickleball.formations[1]); // doubles
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'pickleball_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Player 1 (left 0.33,0.72): move forward on left
    state.addPlayerMove(home[0].id, Offset(0.28 * c.width, 0.66 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.25 * c.width, 0.60 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.30 * c.width, 0.55 * c.height));
    // Player 2 (right 0.67,0.72): move forward on right
    state.addPlayerMove(home[1].id, Offset(0.72 * c.width, 0.66 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.75 * c.width, 0.60 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.70 * c.width, 0.55 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'pickleball_s4_moves');

    _interleavePhases(state, home[0].id, home[1].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'pickleball_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'pickleball_s6_playback');
  });

  // ═══ VOLLEYBALL ═══
  testWidgets('volleyball', (t) async {
    await _launchSport(t, SportType.volleyball);
    final state = _state(t);

    await _shot(binding, 'volleyball_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'volleyball_s2_add_menu');

    state.applyFormation(SportType.volleyball.formations[0]); // 6v6
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'volleyball_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Move front-left (pos 4) and front-right (pos 2) players
    // Player 0 (LF 0.18,0.56): move right along net
    state.addPlayerMove(home[0].id, Offset(0.30 * c.width, 0.56 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.40 * c.width, 0.58 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.35 * c.width, 0.62 * c.height));
    // Player 2 (RF 0.82,0.56): move left along net
    state.addPlayerMove(home[2].id, Offset(0.70 * c.width, 0.56 * c.height));
    state.addPlayerMove(home[2].id, Offset(0.60 * c.width, 0.58 * c.height));
    state.addPlayerMove(home[2].id, Offset(0.65 * c.width, 0.62 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'volleyball_s4_moves');

    _interleavePhases(state, home[0].id, home[2].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'volleyball_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'volleyball_s6_playback');
  });

  // ═══ SOCCER ═══
  testWidgets('soccer', (t) async {
    await _launchSport(t, SportType.soccer);
    final state = _state(t);

    await _shot(binding, 'soccer_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'soccer_s2_add_menu');

    state.applyFormation(SportType.soccer.formations[0]); // 4-4-2
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'soccer_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Move two forwards (index 9,10 — the 2 strikers in 4-4-2)
    // FWD left (0.38,0.50): push forward-left
    state.addPlayerMove(home[9].id, Offset(0.32 * c.width, 0.46 * c.height));
    state.addPlayerMove(home[9].id, Offset(0.28 * c.width, 0.42 * c.height));
    state.addPlayerMove(home[9].id, Offset(0.35 * c.width, 0.38 * c.height));
    // FWD right (0.62,0.50): push forward-right
    state.addPlayerMove(home[10].id, Offset(0.68 * c.width, 0.46 * c.height));
    state.addPlayerMove(home[10].id, Offset(0.72 * c.width, 0.42 * c.height));
    state.addPlayerMove(home[10].id, Offset(0.65 * c.width, 0.38 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'soccer_s4_moves');

    _interleavePhases(state, home[9].id, home[10].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'soccer_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'soccer_s6_playback');
  });

  // ═══ BASKETBALL ═══
  testWidgets('basketball', (t) async {
    await _launchSport(t, SportType.basketball);
    final state = _state(t);

    await _shot(binding, 'basketball_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'basketball_s2_add_menu');

    state.applyFormation(SportType.basketball.formations[0]); // 1-2-2
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'basketball_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Move PG (0.5,0.58) and SG (0.28,0.68)
    // PG: drive right
    state.addPlayerMove(home[0].id, Offset(0.60 * c.width, 0.62 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.65 * c.width, 0.68 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.58 * c.width, 0.72 * c.height));
    // SG: cut to basket from left wing
    state.addPlayerMove(home[1].id, Offset(0.35 * c.width, 0.72 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.42 * c.width, 0.78 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.48 * c.width, 0.82 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'basketball_s4_moves');

    _interleavePhases(state, home[0].id, home[1].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'basketball_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'basketball_s6_playback');
  });

  // ═══ FIELD HOCKEY ═══
  testWidgets('fieldHockey', (t) async {
    await _launchSport(t, SportType.fieldHockey);
    final state = _state(t);

    await _shot(binding, 'fieldHockey_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'fieldHockey_s2_add_menu');

    state.applyFormation(SportType.fieldHockey.formations[0]); // 4-3-3
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'fieldHockey_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // CFWD (idx 9) push toward circle
    state.addPlayerMove(home[9].id, Offset(0.50 * c.width, 0.44 * c.height));
    state.addPlayerMove(home[9].id, Offset(0.45 * c.width, 0.36 * c.height));
    state.addPlayerMove(home[9].id, Offset(0.50 * c.width, 0.28 * c.height));
    // LFWD (idx 8) overlap on left
    state.addPlayerMove(home[8].id, Offset(0.22 * c.width, 0.45 * c.height));
    state.addPlayerMove(home[8].id, Offset(0.28 * c.width, 0.38 * c.height));
    state.addPlayerMove(home[8].id, Offset(0.32 * c.width, 0.30 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'fieldHockey_s4_moves');

    _interleavePhases(state, home[9].id, home[8].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'fieldHockey_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'fieldHockey_s6_playback');
  });

  // ═══ RUGBY ═══
  testWidgets('rugby', (t) async {
    await _launchSport(t, SportType.rugby);
    final state = _state(t);

    await _shot(binding, 'rugby_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'rugby_s2_add_menu');

    state.applyFormation(SportType.rugby.formations[0]); // 15v15
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'rugby_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Fly-half (idx 9 — 0.36,0.79) — backline pass play
    state.addPlayerMove(home[9].id, Offset(0.32 * c.width, 0.72 * c.height));
    state.addPlayerMove(home[9].id, Offset(0.28 * c.width, 0.62 * c.height));
    state.addPlayerMove(home[9].id, Offset(0.25 * c.width, 0.50 * c.height));
    // Left wing (idx 12 — 0.07,0.78) — overlap run
    state.addPlayerMove(home[12].id, Offset(0.12 * c.width, 0.65 * c.height));
    state.addPlayerMove(home[12].id, Offset(0.10 * c.width, 0.50 * c.height));
    state.addPlayerMove(home[12].id, Offset(0.15 * c.width, 0.35 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'rugby_s4_moves');

    _interleavePhases(state, home[9].id, home[12].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'rugby_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'rugby_s6_playback');
  });

  // ═══ BASEBALL ═══
  testWidgets('baseball', (t) async {
    await _launchSport(t, SportType.baseball);
    final state = _state(t);

    await _shot(binding, 'baseball_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'baseball_s2_add_menu');

    state.applyFormation(SportType.baseball.formations[0]); // standard defense
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'baseball_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // SS (idx 4 — 0.42,0.62) — cover 2nd
    state.addPlayerMove(home[4].id, Offset(0.46 * c.width, 0.58 * c.height));
    state.addPlayerMove(home[4].id, Offset(0.50 * c.width, 0.56 * c.height));
    state.addPlayerMove(home[4].id, Offset(0.54 * c.width, 0.58 * c.height));
    // CF (idx 7 — 0.50,0.18) — back up
    state.addPlayerMove(home[7].id, Offset(0.50 * c.width, 0.24 * c.height));
    state.addPlayerMove(home[7].id, Offset(0.46 * c.width, 0.30 * c.height));
    state.addPlayerMove(home[7].id, Offset(0.42 * c.width, 0.36 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'baseball_s4_moves');

    _interleavePhases(state, home[4].id, home[7].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'baseball_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'baseball_s6_playback');
  });

  // ═══ HANDBALL ═══
  testWidgets('handball', (t) async {
    await _launchSport(t, SportType.handball);
    final state = _state(t);

    await _shot(binding, 'handball_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'handball_s2_add_menu');

    state.applyFormation(SportType.handball.formations[0]); // 7v7
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'handball_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // CB (idx 3 — 0.50,0.64) — drive to 9m line
    state.addPlayerMove(home[3].id, Offset(0.50 * c.width, 0.50 * c.height));
    state.addPlayerMove(home[3].id, Offset(0.46 * c.width, 0.36 * c.height));
    state.addPlayerMove(home[3].id, Offset(0.42 * c.width, 0.22 * c.height));
    // Pivot (idx 6 — 0.50,0.56) — slide along 6m
    state.addPlayerMove(home[6].id, Offset(0.40 * c.width, 0.40 * c.height));
    state.addPlayerMove(home[6].id, Offset(0.32 * c.width, 0.28 * c.height));
    state.addPlayerMove(home[6].id, Offset(0.30 * c.width, 0.18 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'handball_s4_moves');

    _interleavePhases(state, home[3].id, home[6].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'handball_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'handball_s6_playback');
  });

  // ═══ WATER POLO ═══
  testWidgets('waterPolo', (t) async {
    await _launchSport(t, SportType.waterPolo);
    final state = _state(t);

    await _shot(binding, 'waterPolo_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'waterPolo_s2_add_menu');

    state.applyFormation(SportType.waterPolo.formations[0]); // 7v7 umbrella
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'waterPolo_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Hole set (idx 1 — 0.50,0.10) — wrap around
    state.addPlayerMove(home[1].id, Offset(0.40 * c.width, 0.10 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.34 * c.width, 0.14 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.30 * c.width, 0.18 * c.height));
    // Point (idx 6 — 0.50,0.30) — penetrate
    state.addPlayerMove(home[6].id, Offset(0.50 * c.width, 0.22 * c.height));
    state.addPlayerMove(home[6].id, Offset(0.54 * c.width, 0.16 * c.height));
    state.addPlayerMove(home[6].id, Offset(0.60 * c.width, 0.12 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'waterPolo_s4_moves');

    _interleavePhases(state, home[1].id, home[6].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'waterPolo_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'waterPolo_s6_playback');
  });

  // ═══ SEPAK TAKRAW ═══
  testWidgets('sepakTakraw', (t) async {
    await _launchSport(t, SportType.sepakTakraw);
    final state = _state(t);

    await _shot(binding, 'sepakTakraw_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'sepakTakraw_s2_add_menu');

    state.applyFormation(SportType.sepakTakraw.formations[0]); // Regu 3v3
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'sepakTakraw_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Apit Kiri (idx 1 — 0.20,0.60) — net spike approach
    state.addPlayerMove(home[1].id, Offset(0.25 * c.width, 0.55 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.30 * c.width, 0.52 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.35 * c.width, 0.51 * c.height));
    // Apit Kanan (idx 2 — 0.80,0.60)
    state.addPlayerMove(home[2].id, Offset(0.75 * c.width, 0.55 * c.height));
    state.addPlayerMove(home[2].id, Offset(0.70 * c.width, 0.52 * c.height));
    state.addPlayerMove(home[2].id, Offset(0.65 * c.width, 0.51 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'sepakTakraw_s4_moves');

    _interleavePhases(state, home[1].id, home[2].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'sepakTakraw_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'sepakTakraw_s6_playback');
  });

  // ═══ BEACH TENNIS ═══
  testWidgets('beachTennis', (t) async {
    await _launchSport(t, SportType.beachTennis);
    final state = _state(t);

    await _shot(binding, 'beachTennis_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'beachTennis_s2_add_menu');

    state.applyFormation(SportType.beachTennis.formations[0]); // doubles
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'beachTennis_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Left (idx 0 — 0.30,0.70) — close net
    state.addPlayerMove(home[0].id, Offset(0.28 * c.width, 0.62 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.30 * c.width, 0.56 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.34 * c.width, 0.55 * c.height));
    // Right (idx 1 — 0.70,0.70) — close net
    state.addPlayerMove(home[1].id, Offset(0.72 * c.width, 0.62 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.70 * c.width, 0.56 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.66 * c.width, 0.55 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'beachTennis_s4_moves');

    _interleavePhases(state, home[0].id, home[1].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'beachTennis_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'beachTennis_s6_playback');
  });

  // ═══ FOOTVOLLEY ═══
  testWidgets('footvolley', (t) async {
    await _launchSport(t, SportType.footvolley);
    final state = _state(t);

    await _shot(binding, 'footvolley_s1_initial');

    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    await _shot(binding, 'footvolley_s2_add_menu');

    state.applyFormation(SportType.footvolley.formations[0]); // doubles
    await _dismissSheet(t);
    await t.pumpAndSettle();
    await _shot(binding, 'footvolley_s3_formation');

    final c = state.canvasSize;
    final home = _homePlayers(state);
    // Left (idx 0 — 0.30,0.72) — set up attack
    state.addPlayerMove(home[0].id, Offset(0.32 * c.width, 0.62 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.36 * c.width, 0.56 * c.height));
    state.addPlayerMove(home[0].id, Offset(0.42 * c.width, 0.54 * c.height));
    // Right (idx 1 — 0.70,0.72) — bicycle kick approach
    state.addPlayerMove(home[1].id, Offset(0.68 * c.width, 0.62 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.64 * c.width, 0.56 * c.height));
    state.addPlayerMove(home[1].id, Offset(0.58 * c.width, 0.54 * c.height));
    state.selectPlayer(null);
    await t.pumpAndSettle();
    await _shot(binding, 'footvolley_s4_moves');

    _interleavePhases(state, home[0].id, home[1].id, 3);
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.view_timeline).first);
    await t.pumpAndSettle();
    await _shot(binding, 'footvolley_s5_timeline');
    await _dismissSheet(t);

    await _stepForwardTwice(t, state);
    await _shot(binding, 'footvolley_s6_playback');
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
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, brightness: Brightness.dark),
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

List<PlayerIcon> _homePlayers(TacticsState state) =>
    state.players.where((p) => p.team == PlayerTeam.home).toList();

Future<void> _dismissSheet(WidgetTester t) async {
  await t.tapAt(const Offset(200, 50));
  await t.pumpAndSettle();
}

/// Interleave phases: P1 move0→0, P2 move0→1, P1 move1→2, P2 move1→3, ...
void _interleavePhases(TacticsState state, String p1Id, String p2Id, int movesPerPlayer) {
  for (int i = 0; i < movesPerPlayer; i++) {
    state.setMovePhase(p1Id, i, i * 2);
    state.setMovePhase(p2Id, i, i * 2 + 1);
  }
}

Future<void> _stepForwardTwice(WidgetTester t, TacticsState state) async {
  state.stepForward();
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(milliseconds: 500));
  state.finishAnimation();
  await t.pump(const Duration(milliseconds: 100));
  state.stepForward();
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(milliseconds: 500));
  state.finishAnimation();
  await t.pump(const Duration(milliseconds: 100));
}

Future<void> _shot(IntegrationTestWidgetsFlutterBinding b, String name) async {
  await b.convertFlutterSurfaceToImage();
  await Future.delayed(const Duration(milliseconds: 300));
  final bytes = await b.takeScreenshot(name);
  final f = File('$outDir/$name.png');
  await f.writeAsBytes(bytes);
  print('📸 $name (${(bytes.length / 1024).toStringAsFixed(0)} KB)');
}
