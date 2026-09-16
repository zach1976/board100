// Renders every drill's library thumbnail to a PNG, so a page of them can be
// looked at all at once.
//
// The thumbnail is the one picture a coach sees before deciding to open a
// drill, and there are 624 of them. Judging that from inside the app means
// scrolling one sport at a time on a phone; judging it from the source means
// imagining what a painter draws. This runs the real DrillThumbnail widget —
// the same code the list builds — and writes what it drew.
//
//   cd tactics_board
//   FLUTTER_ROOT=<flutter> flutter test tool/render_thumbs.dart
//
// Output: tools/thumb_png/<sport>/<id>.png, and then
// tools/thumb_review.py builds the page that shows them.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/widgets/drill_thumbnail.dart';

/// Rendered at four times the size it ships at, so the page can show it big
/// enough to argue about without it being a different picture.
const double kThumbHeight = 96;
const double kPixelRatio = 4.0;

/// Without a real font the test binding draws every glyph as a filled box,
/// so the shirt numbers came out as white squares. Roboto ships with Flutter.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.path;
  for (final file in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
    final f = File('$root/bin/cache/artifacts/material_fonts/$file');
    if (!f.existsSync()) continue;
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
}

void main() {
  testWidgets('render every drill thumbnail', (tester) async {
    final repo = Directory.current.parent;
    final drillDir = Directory('${Directory.current.path}/assets/drills');
    final outRoot = Directory('${repo.path}/tools/thumb_png');
    // ONLY=soccer/rondo_4v2,soccer/dribble_slalom renders a handful in
    // place while the painter is being argued about; the full run wipes and
    // rebuilds everything.
    final only = Platform.environment['ONLY']
        ?.split(',')
        .map((e) => e.trim())
        .toSet();
    if (only == null && outRoot.existsSync()) outRoot.deleteSync(recursive: true);

    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await _loadRoboto();

    final boundaryKey = GlobalKey();
    final thumb = ValueNotifier<Widget>(const SizedBox.shrink());
    addTearDown(thumb.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: material.TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto'),
          child: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: ValueListenableBuilder<Widget>(
              valueListenable: thumb,
              builder: (_, w, __) => w,
            ),
          ),
        ),
        ),
      ),
    );

    var shots = 0;
    final files = drillDir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      if (!f.path.endsWith('.json')) continue;
      final sportName = f.uri.pathSegments.last.replaceAll('.json', '');
      final sport = SportType.values.firstWhere((s) => s.name == sportName);
      final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final dir = Directory('${outRoot.path}/$sportName')
        ..createSync(recursive: true);

      for (final raw in data['drills'] as List) {
        final drill = Drill.fromJson(Map<String, dynamic>.from(raw as Map));
        if (only != null && !only.contains('$sportName/${drill.id}')) continue;
        thumb.value = DrillThumbnail(
          drill: drill,
          sport: sport,
          height: kThumbHeight,
        );
        await tester.pump(const Duration(milliseconds: 16));
        // runAsync: toImage is a real GPU round-trip and does not resolve
        // inside the fake-async zone a widget test runs in.
        await tester.runAsync(() async {
          final boundary = boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: kPixelRatio);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('${dir.path}/${drill.id}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        shots++;
      }
    }
    // ignore: avoid_print
    print('rendered $shots thumbnails -> ${outRoot.path}');
    expect(shots, greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
