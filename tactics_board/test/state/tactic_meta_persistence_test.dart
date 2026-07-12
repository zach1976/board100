import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/models/tactic_meta.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// path_provider has no plugin under `flutter test`, so TacticsState._tacticsDir
/// falls back to Directory.systemTemp — these tests exercise real file IO there.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  late TacticsState state;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    state = TacticsState(sportType: SportType.badminton);
    final dir = Directory('${Directory.systemTemp.path}/tactics/badminton');
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  TacticMeta meta(String name,
          {String folder = '', String description = '', DateTime? created}) =>
      TacticMeta(
        name: name,
        folder: folder,
        description: description,
        createdAt: created ?? DateTime(2020),
        updatedAt: created ?? DateTime(2020),
      );

  test('saving one board over another keeps the target board\'s createdAt', () async {
    await state.saveTactics('B',
        meta: meta('B', folder: 'Defence', created: DateTime(2021, 3, 4)));
    final bornAt = (await state.readTacticMeta('B'))!.createdAt;

    // Board A is loaded; the Save page prefills from A, user renames to B.
    final fromA = meta('A', created: DateTime(2026, 1, 1));
    await state.saveTactics('B', meta: fromA.copyWith(name: 'B'));

    expect((await state.readTacticMeta('B'))!.createdAt, bornAt);
  });

  test('quick-save keeps folder and description when the file cannot be parsed',
      () async {
    final path = await state.saveTactics('C',
        meta: meta('C', folder: 'Drills', description: 'press break'));
    File(path).writeAsStringSync('{ not json');

    // Quick-save: no meta passed, readTacticMeta returns null for the bad file.
    await state.saveTactics('C');

    final after = await state.readTacticMeta('C');
    expect(after!.folder, 'Drills');
    expect(after.description, 'press break');
  });

  test('saving the current board under a new name inherits nothing', () async {
    await state.saveTactics('C',
        meta: meta('C', folder: 'Drills', description: 'press break'));
    expect(state.currentTacticName, 'C');

    await state.saveTactics('New Board'); // the practice-planner path

    final fresh = await state.readTacticMeta('New Board');
    expect(fresh!.folder, isEmpty);
    expect(fresh.description, isEmpty);
  });

  test('quick-save advances updatedAt but preserves createdAt', () async {
    await state.saveTactics('D', meta: meta('D', created: DateTime(2021)));
    await state.saveTactics('D');

    final after = await state.readTacticMeta('D')!;
    expect(after!.createdAt, DateTime(2021));
    expect(after.updatedAt.isAfter(DateTime(2021)), isTrue);
  });

  test('a saved folder is offered by listFolders', () async {
    await state.saveTactics('E', meta: meta('E', folder: 'Set Pieces'));
    expect(await state.listFolders(), contains('Set Pieces'));
  });

  test('listFolders(knownMetas:) unions prefs with the supplied metas', () async {
    await state.createFolder('Warmups');
    final folders = await state.listFolders(
      knownMetas: [meta('remote', folder: 'From Other Device')],
    );
    expect(folders, containsAll(['Warmups', 'From Other Device']));
  });

  test('boards saved before metadata existed still list with defaults', () async {
    await state.saveTactics('Legacy');
    final path = '${Directory.systemTemp.path}/tactics/badminton/Legacy.json';
    // Strip the meta block, mimicking a board written by the previous build.
    final raw = File(path).readAsStringSync().replaceAll(RegExp(r',"meta":\{[^}]*\}'), '');
    File(path).writeAsStringSync(raw);

    final metas = await state.listSavedTacticMetas();
    expect(metas.single.name, 'Legacy');
    expect(metas.single.folder, isEmpty);
  });
}
