import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/court_layout.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// Field hockey's other pitches (indoor, Hockey5s) belong to the board drawn
/// on them; boards saved before they existed keep the full pitch.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  TacticsState board() =>
      TacticsState(sportType: SportType.fieldHockey, preview: true)
        ..setCanvasSizeSilent(const Size(402, 730));

  Map<String, dynamic> page({String? court}) => {
        'sportType': SportType.fieldHockey.index,
        'players': <dynamic>[],
        'strokes': <dynamic>[],
        'canvasWidth': 402.0,
        'canvasHeight': 730.0,
        'courtLayout': ?court,
      };

  test('field hockey offers the indoor pitch and the Hockey5s court', () {
    expect(SportType.fieldHockey.courtLayouts,
        containsAll([CourtLayout.indoor, CourtLayout.hockey5s]));
    expect(SportType.waterPolo.courtLayouts, isNot(contains(CourtLayout.indoor)));
  });

  test('a board that names the indoor pitch opens on it and saves it', () {
    final s = board()..loadFromJson(page(court: 'indoor'));
    expect(s.courtLayout(SportType.fieldHockey), CourtLayout.indoor);
    expect(s.toJson()['courtLayout'], 'indoor');
    final again = board()..loadFromJson(jsonDecode(jsonEncode(s.toJson())));
    expect(again.courtLayout(SportType.fieldHockey), CourtLayout.indoor);
  });

  test('a board without the key stays on the full pitch, even after indoor',
      () {
    final s = board()..setCourtLayout(SportType.fieldHockey, CourtLayout.indoor);
    expect(s.courtLayout(SportType.fieldHockey), CourtLayout.indoor);
    s.loadFromJson(page());
    expect(s.courtLayout(SportType.fieldHockey), CourtLayout.full);
    expect(s.toJson().containsKey('courtLayout'), isFalse);
  });

  test('picking a view of the full pitch drops the board pitch', () {
    final s = board()..loadFromJson(page(court: 'hockey5s'));
    expect(s.courtLayout(SportType.fieldHockey), CourtLayout.hockey5s);
    s.setCourtLayout(SportType.fieldHockey, CourtLayout.half);
    expect(s.courtLayout(SportType.fieldHockey), CourtLayout.half);
    expect(s.toJson().containsKey('courtLayout'), isFalse);
  });

  test('an unknown pitch name is ignored', () {
    final s = board()..loadFromJson(page(court: 'moon'));
    expect(s.courtLayout(SportType.fieldHockey), CourtLayout.full);
  });

  test('formations follow the pitch: 5 + GK indoor, 4 + GK on Hockey5s', () {
    final s = board()..loadFromJson(page(court: 'indoor'));
    expect(s.formations.map((f) => f.homeCount).toSet(), {6});
    s.loadFromJson(page(court: 'hockey5s'));
    expect(s.formations.map((f) => f.homeCount).toSet(), {5});
    s.loadFromJson(page());
    expect(s.formations, SportType.fieldHockey.formations);
  });

  test('indoor formations stand inside the indoor side-boards', () {
    const share = (22 / 44) / (55 / 91.4);
    for (final f in SportType.fieldHockey.formationsOn(CourtLayout.indoor)) {
      for (final p in [...f.homePositions, ...f.awayPositions]) {
        expect((p.dx - 0.5).abs(), lessThan(share / 2));
      }
    }
  });

  test('every indoor drill in the pack names its pitch and stays on it', () {
    final pack = jsonDecode(
        File('assets/drills/fieldHockey.json').readAsStringSync()) as Map;
    final indoor = [
      for (final d in pack['drills'] as List)
        if ((d['id'] as String).startsWith('fh_in_')) d as Map
    ];
    // Empty while the indoor drills are held out of the pack (see
    // field_hockey_expansion in tools/drills/field_hockey.py).
    for (final d in indoor) {
      expect((d['board'] as Map)['courtLayout'], 'indoor', reason: d['id']);
    }
  });
}
