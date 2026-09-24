// Prints, for every sport, the assets that belong to that sport alone.
//
// One source of truth: the lists come from SportType and markerImageAsset,
// the same getters the app reads at runtime, so the package a sport ships in
// cannot drift from what the app asks for. tools/gen_sport_packages.py turns
// this into packages/sport_<name>/.
//
//     flutter test tool/sport_assets.dart      → tools/sport_assets.json
//
// A test, not a `dart run`: it reaches into the widget layer, and that pulls
// in dart:ui, which the standalone VM does not have.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

void main() {
  test('write the per-sport asset manifest', () {
  final out = <String, List<String>>{};
  for (final s in SportType.values) {
    final files = <String>{
      'assets/drills/${s.name}.json',
      'assets/icon/ball_${s.name}.png',
    };
    for (final m in s.markers) {
      final a = markerImageAsset(m, s);
      if (a != null) files.add(a);
    }
    // The plain figure is everybody's and stays in the core; a sport ships
    // only the body or the implement that is its own.
    for (final f in {s.playerBody, s.playerImplement}) {
      if (f == null || f == PlayerFigure.plain) continue;
      files.add('assets/icon/player_top_male_${f.name}_base.png');
      files.add('assets/icon/player_top_male_${f.name}_kit.png');
      files.add('assets/icon/player_top_female_${f.name}_base.png');
      files.add('assets/icon/player_top_female_${f.name}_kit.png');
    }
    out[s.name] = files.toList()..sort();
  }
  final f = File('${Directory.current.parent.path}/tools/sport_assets.json')
    ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
  // ignore: avoid_print
  print('wrote ${f.path}');
  expect(out.length, SportType.values.length);
  });
}
