import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';
import 'package:yaml/yaml.dart';

/// Art that a sport names but nobody bundles renders as a grey box on the
/// board with no error anywhere — the failure is invisible until someone opens
/// the Add sheet on a device. Since the per-sport packages there are sixteen
/// pubspecs it could be missing from, so this checks the two halves agree for
/// every sport.
Set<String> _declared(String pubspecPath, {String prefix = ''}) {
  final yaml = loadYaml(File(pubspecPath).readAsStringSync()) as YamlMap;
  final list = (yaml['flutter'] as YamlMap?)?['assets'] as YamlList?;
  return (list ?? []).map((e) => '$prefix${e.toString()}').toSet();
}

void main() {
  final core = _declared('pubspec.yaml');
  final packages = {
    for (final s in SportType.values)
      s: _declared('../packages/sport_${s.name.toLowerCase()}/pubspec.yaml',
          prefix: 'packages/sport_${s.name.toLowerCase()}/'),
  };
  // Whichever pubspec it came from, the file sits here relative to the test.
  String onDisk(String asset) =>
      asset.startsWith('packages/') ? '../$asset' : asset;

  void expectShipped(String asset, Set<String> declared, String why) {
    expect(declared, contains(asset), reason: '$why: $asset is not declared');
    expect(File(onDisk(asset)).existsSync(), isTrue,
        reason: '$why: $asset is missing from disk');
  }

  test('every sport ships its own drills, ball and equipment', () {
    for (final s in SportType.values) {
      final own = packages[s]!;
      expectShipped('packages/sport_${s.name.toLowerCase()}/'
          'assets/drills/${s.name}.json', own, s.name);
      expectShipped('packages/sport_${s.name.toLowerCase()}/'
          'assets/icon/ball_${s.name}.png', own, s.name);
      for (final m in s.markers) {
        final a = markerImageAsset(m, s);
        if (a == null) continue;
        expectShipped(a, own, '${s.name}/$m');
      }
    }
  });

  test('the shared markers stay in the core', () {
    for (final shape in MarkerShape.values) {
      if (kSportScopedMarkers.contains(shape)) continue;
      final a = markerImageAsset(shape, SportType.soccer);
      if (a == null) continue;
      expectShipped(a, core, '$shape');
    }
  });

  test('a soccer app carries no other sport', () {
    // The whole point of the split. Soccer lists no equipment of its own, so
    // its package is two files and the core has nothing sport-shaped in it.
    expect(packages[SportType.soccer]!.length, 2);
    // assets/drills/index.json is allowed: it is the count for every sport,
    // which the hub's picker needs, and 300 bytes. A sport's own library is
    // not.
    for (final a in core) {
      for (final s in SportType.values) {
        expect(a.endsWith('/drills/${s.name}.json'), isFalse,
            reason: '$a is ${s.name}\'s');
      }
      expect(a.contains('/ball_'), isFalse, reason: '$a is one sport\'s');
    }
  });

  test('the recolourable spot markers keep their code drawing', () {
    // circle / square / triangle / diamond take their colour from the coach,
    // and an image cannot be recoloured — marking four zones in four colours
    // is the entire point of them.
    for (final shape in [
      MarkerShape.circle,
      MarkerShape.square,
      MarkerShape.triangle,
      MarkerShape.diamond,
    ]) {
      expect(markerImageAsset(shape, SportType.soccer), isNull,
          reason: '$shape must stay drawn so it can be recoloured');
    }
  });

  test('every figure ships as a body plate and a kit plate', () {
    // A figure is two images: the body in its own colours and the kit in grey
    // for the team colour to land on. Half a pair renders as the fallback
    // circle and oval with no error anywhere. The plain figure is everybody's
    // and lives in the core; a racket, a bat and a swim cap ship with the
    // sports that use them.
    String file(String g, PlayerFigure f, String layer) =>
        'assets/icon/player_top_$g'
        '${f == PlayerFigure.plain ? '' : '_${f.name}'}_$layer.png';
    for (final g in ['male', 'female']) {
      // The plain figure also ships its turnaround: eight headings in a
      // 4x2 sheet, so a player can face where they are going.
      for (final layer in ['base', 'kit', 'turn_base', 'turn_kit']) {
        expectShipped(file(g, PlayerFigure.plain, layer), core, 'plain/$g');
      }
      for (final s in SportType.values) {
        for (final f in {s.playerBody, s.playerImplement}) {
          if (f == null || f == PlayerFigure.plain) continue;
          for (final layer in ['base', 'kit', 'turn_base', 'turn_kit']) {
            expectShipped(
                'packages/sport_${s.name.toLowerCase()}/${file(g, f, layer)}',
                packages[s]!,
                '${s.name}/${f.name}/$g');
          }
        }
      }
    }
  });

  test('every marker is either upright on screen or aimed at the pitch', () {
    // Turning the board turns the pitch, and with it everything whose
    // picture means a direction on that pitch. A cone means nothing of the
    // kind: it stood on the grass in portrait and lay on its side in
    // landscape, which is the one thing a cone never does.
    const upright = kUprightMarkers;
    // Nothing in the set may carry a bearing, and nothing that carries one
    // may be in it. Listed rather than derived: which of a goal, a hurdle
    // and a ladder points somewhere is a judgement about the artwork, and
    // the point of writing it down is that adding a sprite makes somebody
    // make it again.
    const aimed = <MarkerShape>{
      MarkerShape.goal,
      MarkerShape.miniGoal,
      MarkerShape.hurdle,
      MarkerShape.ladder,
      MarkerShape.arrowMark,
      MarkerShape.bench,
      MarkerShape.rebounder,
      MarkerShape.lScreen,
      MarkerShape.net,
      MarkerShape.laneRope,
      MarkerShape.rugbyPosts,
      MarkerShape.hoop,
      MarkerShape.floatingGoal,
      MarkerShape.hockeyStick,
      MarkerShape.racket,
      MarkerShape.paddle,
      MarkerShape.base,
      MarkerShape.homePlate,
    };
    for (final shape in MarkerShape.values) {
      if (markerImageAsset(shape, SportType.soccer) == null &&
          !kSportScopedMarkers.contains(shape)) {
        continue; // a drawn symbol, not a photographed object
      }
      expect(upright.contains(shape) || aimed.contains(shape), isTrue,
          reason: '${shape.name} ships artwork and nobody has said whether '
              'it stands up or points somewhere');
    }
    expect(upright.intersection(aimed), isEmpty);

    PlayerIcon marker(MarkerShape shape) => PlayerIcon(
          id: shape.name,
          label: '',
          team: PlayerTeam.neutral,
          position: Offset.zero,
          markerShape: shape,
        );
    expect(staysUpright(marker(MarkerShape.cone)), isTrue);
    expect(staysUpright(marker(MarkerShape.goal)), isFalse);
    // A ball is a sphere with its highlight painted on.
    expect(
        staysUpright(PlayerIcon(
          id: 'b',
          label: '',
          team: PlayerTeam.neutral,
          sportType: SportType.soccer,
          position: Offset.zero,
        )),
        isTrue);
  });

  test('the sprites are the size and format the board expects', () {
    final seen = <String>{};
    for (final s in SportType.values) {
      for (final shape in MarkerShape.values) {
        final asset = markerImageAsset(shape, s);
        if (asset == null || !seen.add(asset)) continue;
        final f = File(onDisk(asset));
        if (!f.existsSync()) continue; // covered by the tests above
        final bytes = f.readAsBytesSync();
        expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10],
            reason: '$asset is not a PNG');
        // IHDR: width and height are big-endian uint32 at offsets 16 and 20,
        // and colour type 6 at offset 25 is the one that carries alpha.
        final w = ByteData.sublistView(bytes, 16, 20).getUint32(0);
        final h = ByteData.sublistView(bytes, 20, 24).getUint32(0);
        expect([w, h], [512, 512], reason: '$asset is ${w}x$h');
        expect(bytes[25], 6, reason: '$asset has no alpha channel');
      }
    }
  });
}
