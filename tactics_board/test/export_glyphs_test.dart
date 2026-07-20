// Exports the app's SportGlyph family to transparent PNGs for use in the
// App Store screenshot compositor (tool/aso_design_compositor.py).
//   flutter test test/export_glyphs_test.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/widgets/sport_glyph.dart';

const _outDir =
    '/Users/zhenyusong/projects/board100/tactics_board/aso/glyphs';

// This file is an on-demand PNG exporter, not a real test — each case renders
// a glyph and blocks on toImage, which hangs a plain `flutter test` run. It
// only runs when explicitly requested:
//   EXPORT_GLYPHS=1 flutter test test/export_glyphs_test.dart
final bool _shouldExport = Platform.environment.containsKey('EXPORT_GLYPHS');

void main() {
  if (_shouldExport) Directory(_outDir).createSync(recursive: true);
  for (final sport in SportType.values) {
    testWidgets('glyph_${sport.name}', skip: !_shouldExport, (tester) async {
      const px = 512.0;
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: px,
                height: px,
                child: SportGlyph(sport: sport, size: px),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      late ui.Image image;
      await tester.runAsync(() async {
        image = await boundary.toImage(pixelRatio: 2.0);
      });
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_outDir/${sport.name}.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  }
}
