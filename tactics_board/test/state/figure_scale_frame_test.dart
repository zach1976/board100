import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart' show MatrixUtils;
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/drill_note.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

/// Figure size on a tablet board, a tight drill's figures, and a drill
/// that lives in one half opening zoomed to it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Drill> drills(SportType s) => (jsonDecode(
              File('assets/drills/${s.name}.json').readAsStringSync())['drills']
          as List)
      .map((d) => Drill.fromJson(Map<String, dynamic>.from(d as Map)))
      .toList();

  tearDown(() {
    gBoardFigureScale = 1.0;
    gTightFigureScale = 1.0;
  });

  test('phones draw figures at 36pt; tablets grow them, capped', () {
    for (final phone in const [
      Size(402, 730), Size(440, 800), Size(320, 480), // upright
      Size(330, 800), Size(400, 900), // a phone's board turned sideways
    ]) {
      expect(boardFigureScaleFor(phone), 1.0, reason: '$phone');
    }
    expect(kPlayerIconSize, 36.0);
    final mini = boardFigureScaleFor(const Size(720, 900));
    expect(mini, greaterThan(1.0));
    expect(boardFigureScaleFor(const Size(1000, 1200)), 1.6);
    expect(boardFigureScaleFor(const Size(4000, 4000)), 1.6);
    gBoardFigureScale = 1.6;
    expect(kPlayerIconSize, closeTo(57.6, 1e-9));
  });

  test('a tight drill carries the generator figure and keeps it', () {
    final d = drills(SportType.rugby)
        .firstWhere((d) => d.id == 'rg_set_lineout_seven');
    expect(d.board['figureScale'], 0.654);
    final s = TacticsState(sportType: SportType.rugby)
      ..setCanvasSizeSilent(const Size(402, 730))
      ..loadFromJson(Map<String, dynamic>.from(d.board));
    expect(s.figureScale, 0.654);
    expect(gTightFigureScale, 0.654);
    expect(kPlayerIconSize, closeTo(36 * 0.654, 1e-9));
    // Saved and read back.
    final saved = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
    expect(saved['figureScale'], 0.654);
    final back = TacticsState(sportType: SportType.rugby)
      ..setCanvasSizeSilent(const Size(402, 730))
      ..loadFromJson(saved);
    expect(back.figureScale, 0.654);
    // An ordinary board puts the figures back to full size.
    final open = drills(SportType.rugby).firstWhere((d) => d.board['figureScale'] == null);
    back.loadFromJson(Map<String, dynamic>.from(open.board));
    expect(back.figureScale, 1.0);
    expect(gTightFigureScale, 1.0);
  });

  for (final c in [
    (SportType.soccer, 'corner_near_post'),
    (SportType.waterPolo, 'wp_centre_entry'),
  ]) {
    test('${c.$2} opens zoomed to its half with its note on screen', () {
      final d = drills(c.$1).firstWhere((d) => d.id == c.$2);
      expect(d.frame, 'top');
      for (final size in const [Size(402, 730), Size(1000, 1180)]) {
        final s = TacticsState(sportType: c.$1)..setCanvasSizeSilent(size);
        s.loadFromJson(Map<String, dynamic>.from(d.board));
        s.openedDrill(DrillNote.parse(d.localizedNote('en')).beats,
            frame: d.frame);
        expect(s.frameNeedsApply, isTrue);
        s.placeDrillNote(sideways: false);
        expect(s.frameNeedsApply, isFalse);
        final m = s.transformationController.value;
        final view = MatrixUtils.inverseTransformRect(m, Offset.zero & size);
        // A pitch on a tablet is fitted by its length, so its half has
        // room to grow; a pool nearly as wide as it is long has little.
        if (size.width > 600 && c.$1 == SportType.soccer) {
          expect(s.frameZoom, greaterThan(1.3), reason: '$size');
        }
        // Everything in the drill, and its note, is in the view.
        for (final p in s.players) {
          for (final at in [p.position, ...p.moves]) {
            expect(view.inflate(1).contains(at), isTrue,
                reason: '${p.label} at $at outside $view on $size');
          }
        }
        // One tap back to the full court, for good.
        s.resetZoom();
        expect(s.viewFrame, isNull);
        expect(s.frameZoom, 1.0);
        expect(s.transformationController.value.isIdentity(), isTrue);
        expect(s.toJson().containsKey('viewFrame'), isFalse);
      }
    });
  }

  test('sideways the note slides into the half on show', () {
    final d = drills(SportType.soccer)
        .firstWhere((d) => d.id == 'corner_near_post');
    // A tablet turned sideways: the canvas is laid out upright inside the
    // RotatedBox, the card's height for its width.
    const size = Size(900, 1300);
    final s = TacticsState(sportType: SportType.soccer)
      ..setCanvasSizeSilent(size)
      ..loadFromJson(Map<String, dynamic>.from(d.board))
      ..openedDrill(DrillNote.parse(d.localizedNote('en')).beats,
          frame: d.frame);
    s.placeDrillNote(sideways: true);
    final note =
        s.players.firstWhere((p) => p.id == TacticsState.kDrillNoteId);
    final win = s.viewFrameWindow()!;
    expect(note.position.dy, lessThan(win.bottom));
    final view = MatrixUtils.inverseTransformRect(
        s.transformationController.value, Offset.zero & size);
    expect(view.contains(note.position), isTrue);
  });
}
