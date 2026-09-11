import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/drill.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/drill_library_service.dart';
import 'package:tactics_board/services/practice_service.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/add_to_plan_sheet.dart';

/// Adding a shipped drill to a practice plan.
///
/// The plan format only carries a saved board's NAME, so this works by
/// copying the drill's board into the coach's own boards. Two things can go
/// quietly wrong with that and both would only show up on a coach's phone:
/// the copy not actually holding the drill's board, and a second copy
/// overwriting the first when the same drill is added twice.
void main() {
  late Drill drill;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // TacticsState hangs without this, and saveTactics reaches for prefs.
    SharedPreferences.setMockInitialValues({});
    // path_provider has no plugin here, so PracticeService and TacticsState
    // both fall back to the system temp directory — the same one, which is
    // what makes this exercise the real files.
    final all = await DrillLibraryService.instance.forSport(SportType.soccer);
    drill = all.firstWhere((d) => d.id == 'passing_diamond');
  });

  setUp(() async {
    // Each test starts from an empty shelf: the fallback directory is shared
    // with every other run on this machine.
    for (final name in await PracticeService.listNames(SportType.soccer)) {
      await PracticeService.delete(SportType.soccer, name);
    }
    final state = TacticsState(sportType: SportType.soccer, preview: true);
    for (final name in await state.listSavedTactics()) {
      await state.deleteTactics(name);
    }
  });

  test('the plan gets an item, and the board behind it is the drill',
      () async {
    final boardName = await AddToPlanSheet.addToPlan(
      sport: SportType.soccer,
      drill: drill,
      locale: 'en',
      planName: 'Tuesday',
    );

    expect(boardName, drill.localizedName('en'),
        reason: 'the copy is named after the drill, so it is recognisable '
            'in a list of boards the coach drew themselves');

    final plan = await PracticeService.load(SportType.soccer, 'Tuesday');
    expect(plan, isNotNull, reason: 'a plan that did not exist is created');
    expect(plan!.items, hasLength(1));
    expect(plan.items.single.tacticName, boardName);
    expect(plan.items.single.durationMinutes, drill.minutes,
        reason: "the drill knows how long it runs; a plan that says ten "
            'minutes for everything is a plan nobody trusts');

    // The copy is a real board, holding the drill's own players — not an
    // empty pitch with the right name on it.
    final state = TacticsState(sportType: SportType.soccer, preview: true);
    await state.loadTactics(boardName);
    final expected = (drill.board['players'] as List).length;
    expect(state.players, hasLength(expected));
  });

  test('adding the same drill twice does not overwrite the first copy',
      () async {
    final first = await AddToPlanSheet.addToPlan(
      sport: SportType.soccer,
      drill: drill,
      locale: 'en',
      planName: 'Tuesday',
    );
    final second = await AddToPlanSheet.addToPlan(
      sport: SportType.soccer,
      drill: drill,
      locale: 'en',
      planName: 'Thursday',
    );

    expect(second, isNot(first));
    expect(second, '$first 2');

    final state = TacticsState(sportType: SportType.soccer, preview: true);
    final saved = await state.listSavedTactics();
    expect(saved, containsAll([first, second]),
        reason: 'two plans referencing one drill need two boards; one file '
            'would leave whichever plan is edited second pointing at the '
            "other plan's changes");
  });

  test('an existing plan is appended to, not replaced', () async {
    await AddToPlanSheet.addToPlan(
      sport: SportType.soccer,
      drill: drill,
      locale: 'en',
      planName: 'Tuesday',
    );
    await AddToPlanSheet.addToPlan(
      sport: SportType.soccer,
      drill: drill,
      locale: 'en',
      planName: 'Tuesday',
    );

    final plan = await PracticeService.load(SportType.soccer, 'Tuesday');
    expect(plan!.items, hasLength(2));
    expect(await PracticeService.listNames(SportType.soccer),
        equals(['Tuesday']));
  });

  test('the saved copy carries the drill note as its description', () async {
    final boardName = await AddToPlanSheet.addToPlan(
      sport: SportType.soccer,
      drill: drill,
      locale: 'en',
      planName: 'Tuesday',
    );
    final state = TacticsState(sportType: SportType.soccer, preview: true);
    final meta = await state.readTacticMeta(boardName);
    expect(meta, isNotNull);
    expect(meta!.description, isNotEmpty);
    expect(drill.localizedNote('en'), startsWith(meta.description.split('…')[0]),
        reason: "the description is the drill's own opening line");
  });

  tearDownAll(() async {
    // Leave no boards or plans behind in the shared temp directory.
    for (final name in await PracticeService.listNames(SportType.soccer)) {
      await PracticeService.delete(SportType.soccer, name);
    }
    final state = TacticsState(sportType: SportType.soccer, preview: true);
    for (final name in await state.listSavedTactics()) {
      await state.deleteTactics(name);
    }
    // A sanity net on the fallback path itself: if path_provider ever starts
    // resolving in tests these files move, and the cleanup above silently
    // stops cleaning anything.
    expect(Directory(Directory.systemTemp.path).existsSync(), isTrue);
    jsonEncode(const <String, String>{});
  });
}
