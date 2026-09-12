import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/drill.dart';
import '../models/practice.dart';
import '../models/sport_type.dart';
import '../models/tactic_meta.dart';
import '../services/practice_service.dart';
import '../state/tactics_state.dart';
import '../ui/primitives.dart';
import '../ui/tokens.dart';

/// Put a shipped drill into one of the coach's practice plans.
///
/// A plan item points at a SAVED BOARD by name — [PracticeItem.tacticName] is
/// all the format carries, and `PracticeRunPage` resolves it with
/// `state.loadTactics(name)`. A drill is not a saved board, so adding one
/// copies its board into the coach's own boards first and the plan then
/// references that copy.
///
/// The copy is the trade this makes, and it is worth knowing about: the board
/// shows up in "my boards", and editing the drill in a later release will not
/// change a plan that already holds a copy. The alternative — teaching
/// PracticeItem to reference a drill id — changes the saved plan format and
/// everything that exports and imports it; copying changes nothing.
class AddToPlanSheet {
  const AddToPlanSheet._();

  /// Returns the plan the drill was added to, or null if the coach backed out.
  static Future<String?> show(
    BuildContext context, {
    required SportType sport,
    required Drill drill,
    required String locale,
  }) async {
    final names = await PracticeService.listNames(sport);
    if (!context.mounted) return null;

    final picked = await TacticalSheet.show<String>(
      context,
      builder: (ctx) => _PlanPicker(names: names),
    );
    if (picked == null || !context.mounted) return null;

    String planName = picked;
    if (picked == _PlanPicker.newPlan) {
      final typed = await promptForName(context,
          title: 'practice_new'.tr(),
          hint: 'practice_name'.tr(),
          taken: names.toSet(),
          takenMessage: 'practice_name_exists'.tr());
      if (typed == null || typed.isEmpty || !context.mounted) return null;
      planName = typed;
    }

    await addToPlan(
        sport: sport, drill: drill, locale: locale, planName: planName);

    if (context.mounted) {
      _toast(context, 'practice_added_to'.tr(args: [planName]));
    }
    return planName;
  }

  /// Copy [drill] into [planName], creating the plan if it is not there yet.
  ///
  /// Separated from [show] so the part that touches the coach's files can be
  /// exercised without driving a sheet. Returns the name the board was saved
  /// under, which is not always the drill's own name — see [_saveDrillAsBoard].
  static Future<String> addToPlan({
    required SportType sport,
    required Drill drill,
    required String locale,
    required String planName,
  }) async {
    final boardName = await _saveDrillAsBoard(sport, drill, locale);
    final plan =
        await PracticeService.load(sport, planName) ?? Practice(name: planName);
    plan.items.add(PracticeItem(
      tacticName: boardName,
      // The drill already knows how long it runs; a plan that says ten
      // minutes for everything is a plan nobody trusts.
      durationMinutes: drill.minutes > 0 ? drill.minutes : 10,
    ));
    plan.updatedAt = DateTime.now();
    await PracticeService.save(sport, plan);
    return boardName;
  }

  /// The drill's board, written into the coach's own boards.
  ///
  /// Saved through a throwaway [TacticsState] rather than the live one: the
  /// coach may have a board open and half drawn, and `saveTactics` writes
  /// whatever the state it is called on is holding.
  static Future<String> _saveDrillAsBoard(
      SportType sport, Drill drill, String locale) async {
    final base = drill.localizedName(locale);
    final taken = await TacticsState(sportType: sport, preview: true)
        .listSavedTactics();
    var name = base;
    // "Passing diamond", "Passing diamond 2", … — adding the same drill to two
    // plans must not have the second one silently overwrite the first.
    for (var n = 2; taken.contains(name); n++) {
      name = '$base $n';
    }

    final tmp = TacticsState(sportType: sport, preview: true)
      ..loadFromJson(Map<String, dynamic>.from(drill.board));
    final now = DateTime.now();
    await tmp.saveTactics(
      name,
      meta: TacticMeta(
        name: name,
        // The drill's own opening line, so the copy is recognisable in a list
        // of boards the coach drew themselves.
        description: _lead(drill.localizedNote(locale)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return name;
  }

  static String _lead(String note) {
    final first = note.trim().split('\n').first.trim();
    return first.length > 120 ? '${first.substring(0, 119)}…' : first;
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

}

class _PlanPicker extends StatelessWidget {
  static const newPlan = '__new__';
  final List<String> names;
  const _PlanPicker({required this.names});

  @override
  Widget build(BuildContext context) {
    return TacticalSheet(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TacticalSheetHeader(title: 'practice_add_to_plan'.tr()),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.add_circle_outline, color: T.accent),
                    title: Text('practice_new'.tr(),
                        style: const TextStyle(
                            color: T.accent, fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(context, newPlan),
                  ),
                  if (names.isNotEmpty) const TacticalDivider(),
                  for (final n in names)
                    ListTile(
                      leading: const Icon(Icons.event_note_outlined,
                          color: T.textDim),
                      title: Text(n,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: T.text)),
                      onTap: () => Navigator.pop(context, n),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
