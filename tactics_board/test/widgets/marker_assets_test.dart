import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';
import 'package:yaml/yaml.dart';

/// Five markers ship as artwork; the rest stay drawn in code.
///
/// A marker that names an asset nobody declared renders as a grey box on the
/// board with no error anywhere — the failure is invisible until someone opens
/// the Add sheet on a device. This checks the two halves agree.
void main() {
  final declared = ((loadYaml(File('pubspec.yaml').readAsStringSync())
          as YamlMap)['flutter']['assets'] as YamlList)
      .map((e) => e.toString())
      .toSet();

  test('every marker sprite is declared in pubspec and exists on disk', () {
    for (final shape in MarkerShape.values) {
      final asset = markerImageAsset(shape);
      if (asset == null) continue;
      // packageAsset() is a no-op under test, where the package is the app.
      expect(declared, contains(asset), reason: '$shape names $asset');
      expect(File(asset).existsSync(), isTrue, reason: '$asset is missing');
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
      expect(markerImageAsset(shape), isNull,
          reason: '$shape must stay drawn so it can be recoloured');
    }
  });

  test('the sprites are the size and format the board expects', () {
    for (final shape in MarkerShape.values) {
      final asset = markerImageAsset(shape);
      if (asset == null) continue;
      final bytes = File(asset).readAsBytesSync();
      expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10],
          reason: '$asset is not a PNG');
      // IHDR: width and height are big-endian uint32 at offsets 16 and 20,
      // and colour type 6 at offset 25 is the one that carries alpha.
      final w = ByteData.sublistView(bytes, 16, 20).getUint32(0);
      final h = ByteData.sublistView(bytes, 20, 24).getUint32(0);
      expect([w, h], [512, 512], reason: '$asset is ${w}x$h');
      expect(bytes[25], 6, reason: '$asset has no alpha channel');
    }
  });
}
