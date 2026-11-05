import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/drill_note.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/working_board_service.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// A drill board read back after the app was killed must still have its
/// step note.
///
/// Reported 2026-10-12: the autosave that loading the drill set off ran
/// before the note was placed, and placing it fell inside the autosave's
/// one-second rate limit — so the board on disk was the drill's shape with
/// no note, and no record that one was still to come.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final drill = (jsonDecode(
          File('assets/drills/volleyball.json').readAsStringSync())['drills']
          as List)
      .map((d) => Drill.fromJson(Map<String, dynamic>.from(d as Map)))
      .firstWhere((d) => d.id == 'vb_warm_pepper');
  final beats = DrillNote.parse(drill.localizedNote('en')).beats;
  const size = Size(386, 650);

  String? noteOf(TacticsState s) => s.players
      .where((p) => p.id == TacticsState.kDrillNoteId)
      .firstOrNull
      ?.label;

  Future<TacticsState> relaunch() async {
    final s = TacticsState(sportType: SportType.volleyball);
    await s.restoreWorkingBoard();
    s.setCanvasSizeSilent(size);
    // What the home page does on its first frame (home_page.dart).
    if (s.noteWanted) s.placeDrillNote(sideways: false);
    return s;
  }

  test('a note placed right after the drill opened is on the restored board',
      () async {
    final s = TacticsState(sportType: SportType.volleyball);
    s.setCanvasSizeSilent(size);
    s.loadFromJson(Map<String, dynamic>.from(drill.board));
    s.openedDrill(beats, id: drill.id);
    s.placeDrillNote(sideways: false);
    expect(noteOf(s), beats.first);
    await Future<void>.delayed(Duration.zero);
    // Killed here: nothing else is written.
    final r = await relaunch();
    expect(r.drillBeats, beats);
    expect(noteOf(r), beats.first);
  });

  test('killed before the note was placed, the restored board places it',
      () async {
    final s = TacticsState(sportType: SportType.volleyball);
    s.loadFromJson(Map<String, dynamic>.from(drill.board));
    s.openedDrill(beats, id: drill.id);
    await Future<void>.delayed(Duration.zero);
    final saved = await WorkingBoardService.instance.load(SportType.volleyball);
    expect(saved, isNotNull);
    final r = await relaunch();
    expect(noteOf(r), beats.first);
  });

  test('a note the coach deleted stays deleted', () async {
    final s = TacticsState(sportType: SportType.volleyball);
    s.setCanvasSizeSilent(size);
    s.loadFromJson(Map<String, dynamic>.from(drill.board));
    s.openedDrill(beats, id: drill.id);
    s.placeDrillNote(sideways: false);
    s.removePlayer(TacticsState.kDrillNoteId);
    expect(noteOf(s), isNull);
    s.saveWorkingBoard();
    await Future<void>.delayed(Duration.zero);
    final r = await relaunch();
    expect(noteOf(r), isNull);
  });

  test('the restored note reads the step the board opens at', () async {
    final s = TacticsState(sportType: SportType.volleyball);
    s.setCanvasSizeSilent(size);
    s.loadFromJson(Map<String, dynamic>.from(drill.board));
    s.openedDrill(beats, id: drill.id);
    s.placeDrillNote(sideways: false);
    s.advanceAtStep(2);
    expect(noteOf(s), beats[1]);
    s.saveWorkingBoard();
    await Future<void>.delayed(Duration.zero);
    final r = await relaunch();
    expect(r.atStep, 0);
    expect(noteOf(r), beats.first);
  });
}
