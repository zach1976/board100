import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/drill_note.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// The step note goes under the court unless someone stands there.
///
/// Reported 2026-10-10: on a volleyball serve drill the server stands
/// behind the end line, in the very band the note was placed in, and the
/// sentence was printed across him.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final drills = (jsonDecode(
          File('assets/drills/volleyball.json').readAsStringSync())['drills']
          as List)
      .map((d) => Drill.fromJson(Map<String, dynamic>.from(d as Map)))
      .toList();

  Offset placed(String id, {bool sideways = false}) {
    final drill = drills.firstWhere((d) => d.id == id);
    final state = TacticsState(sportType: SportType.volleyball);
    state.setCanvasSizeSilent(const Size(386, 650));
    state.loadFromJson(Map<String, dynamic>.from(drill.board));
    state.openedDrill(DrillNote.parse(drill.localizedNote('en')).beats);
    state.placeDrillNote(sideways: sideways);
    return state.players
        .firstWhere((p) => p.id == TacticsState.kDrillNoteId)
        .position;
  }

  final court = SportType.volleyball.fieldRect(const Size(386, 650));

  test('a server behind the end line sends the note over the court', () {
    expect(placed('vb_serve_float_deep').dy, lessThan(court.top));
  });

  test('with no one under the court the note stays under it', () {
    expect(placed('vb_warm_pepper').dy, greaterThan(court.bottom));
  });
}
