import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/drill_note.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

/// A rugby lineout drawn at Law 18's spacing opens on its own close-up
/// (the board's "viewWindow"), where the figures — drawn 1/zoom the size on
/// the canvas — are narrower than the gap between two men.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final drills = (jsonDecode(
          File('assets/drills/rugby.json').readAsStringSync())['drills'] as List)
      .map((d) => Drill.fromJson(Map<String, dynamic>.from(d as Map)))
      .toList();
  Drill drill(String id) => drills.firstWhere((d) => d.id == id);

  const sizes = {
    'phone': Size(402, 730),
    'phone sideways': Size(390, 640),
    'iPad 11"': Size(760, 1010),
    'iPad 13"': Size(980, 1240),
  };

  TacticsState open(String id, Size size) {
    final s = TacticsState(sportType: SportType.rugby);
    s.setCanvasSizeSilent(size);
    s.loadFromJson(Map<String, dynamic>.from(drill(id).board));
    s.applyViewFrame();
    return s;
  }

  for (final id in [
    'rg_set_lineout_five',
    'rg_set_lineout_seven',
    'rg_maul_drive',
    'rg_maul_defend',
  ]) {
    for (final e in sizes.entries) {
      test('$id on a ${e.key}: zoomed in, figures narrower than the gaps', () {
        final s = open(id, e.value);
        expect(s.viewWindow, isNotNull);
        expect(s.frameZoom, greaterThan(4.0));
        final court = SportType.rugby.fieldRect(e.value);
        final metresPerPt = 70 / court.width;
        // The drawn figure: FIGURE_PT's 26pt at the tight scale, grown on
        // a tablet, shrunk by the zoom (TacticsCanvas).
        final figure = 26 *
            s.figureScale *
            boardFigureScaleFor(e.value) /
            s.frameZoom *
            metresPerPt;
        expect(figure, lessThan(1.0), reason: 'figure ${figure}m wide');
        // The closest two men in the lineout at the set-up (the thrower and
        // the ball are outside touch).
        final xs = [
          for (final p in s.players)
            if (p.markerShape.index == 0 &&
                p.sportType == null &&
                p.position.dx > court.left)
              if ((p.position.dy - s.players.first.position.dy).abs() <
                  2 / metresPerPt)
                p.position.dx
        ]..sort();
        var gap = double.infinity;
        for (var i = 1; i < xs.length; i++) {
          if (xs[i] - xs[i - 1] < gap) gap = xs[i] - xs[i - 1];
        }
        expect(figure, lessThan(gap * metresPerPt),
            reason: 'figure ${figure}m, gap ${gap * metresPerPt}m');
        // The whole window is on the screen.
        final win = s.viewFrameWindow()!;
        expect(win.width * s.frameZoom, lessThanOrEqualTo(e.value.width + 0.5));
        expect(win.height * s.frameZoom, lessThanOrEqualTo(e.value.height + 0.5));
      });
    }
  }

  test('the note is drawn at 1/zoom inside the view, and back on reset', () {
    final d = drill('rg_set_lineout_five');
    final s = open(d.id, const Size(402, 730));
    s.openedDrill(DrillNote.parse(d.localizedNote('en')).beats, id: d.id);
    s.placeDrillNote(sideways: false);
    final note =
        s.players.firstWhere((p) => p.id == TacticsState.kDrillNoteId);
    expect(note.scale, closeTo(1 / s.frameZoom, 1e-9));
    final m = s.transformationController.value;
    final onScreen = MatrixUtils.transformPoint(m, note.position);
    expect(const Rect.fromLTWH(0, 0, 402, 730).contains(onScreen), isTrue);

    s.resetZoom();
    expect(s.viewWindow, isNull);
    expect(s.frameZoom, 1.0);
    expect(
        s.players.firstWhere((p) => p.id == TacticsState.kDrillNoteId).scale,
        1.0);
    expect(s.noteWanted, isTrue); // put back under the court
  });

  test('the window is kept with the board', () {
    final s = open('rg_maul_drive', const Size(402, 730));
    final win = s.viewFrameWindow()!;
    final r = TacticsState(sportType: SportType.rugby)
      ..setCanvasSizeSilent(const Size(760, 1010));
    r.loadFromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    r.setCanvasSizeSilent(const Size(402, 730));
    final back = r.viewFrameWindow()!;
    expect((back.left - win.left).abs(), lessThan(0.01));
    expect((back.bottom - win.bottom).abs(), lessThan(0.01));
  });

  test('a board without a window has none', () {
    final s = open('rg_set_scrum', const Size(402, 730));
    expect(s.viewWindow, isNull);
    expect(s.frameZoom, 1.0);
  });
}
