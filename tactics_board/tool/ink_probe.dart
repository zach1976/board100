import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

/// How big a player is actually DRAWN, against the box he is positioned by.
///
///     flutter test tool/ink_probe.dart
///
/// The token is a [kPlayerIconSize] square and everything — taps, selection,
/// the drill generator's spacing — is sized by that square. The figure is
/// not: it stands out of the top and bottom of it. This prints the ink's
/// real width and height so FIGURE_PT in tools/drills/engine.py is a
/// measurement rather than a guess.
void main() {
  testWidgets('ink bounds', (t) async {
    await t.runAsync(PlayerArt.warm);
    const pad = 60.0;
    const box = kPlayerIconSize + pad * 2;
    final key = GlobalKey();
    for (final sport in [SportType.soccer, SportType.fieldHockey,
                         SportType.basketball, SportType.rugby]) {
      await t.pumpWidget(MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: box, height: box, color: Colors.white,
              child: Center(
                child: PlayerIconWidget(
                  player: PlayerIcon(
                    id: 'a', label: '7', team: PlayerTeam.home,
                    position: Offset.zero),
                  sport: sport,
                ),
              ),
            ),
          ),
        ),
      ));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        final ro = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await ro.toImage(pixelRatio: 4.0);
        final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        final b = d!.buffer.asUint8List();
        final w = img.width, h = img.height;
        int minX = w, maxX = -1, minY = h, maxY = -1;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            final i = (y * w + x) * 4;
            if (b[i] > 245 && b[i + 1] > 245 && b[i + 2] > 245) continue;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
        final c = box * 4 / 2;   // the cell's centre, in device pixels
        stdout.writeln('${sport.name}: '
            'w=${((maxX - minX + 1) / 4).toStringAsFixed(1)} '
            'h=${((maxY - minY + 1) / 4).toStringAsFixed(1)} '
            '(cell ${kPlayerIconSize.toStringAsFixed(0)}) '
            'top=${((minY - c) / 4).toStringAsFixed(1)} '
            'bottom=${((maxY - c) / 4).toStringAsFixed(1)}');
      });
    }
  });
}
