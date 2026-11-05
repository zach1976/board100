import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/tactic_meta.dart';

/// The playbook flag on a saved board's metadata: written, read back, and
/// absent from boards saved before it existed.
void main() {
  final t = DateTime(2026, 10, 14, 10);

  test('playbook round-trips through JSON', () {
    final meta = TacticMeta(
        name: 'PC 1', folder: 'Corners', playbook: true, createdAt: t, updatedAt: t);
    final json = meta.toJson();
    expect(json['playbook'], true);
    final back = TacticMeta.fromJson(json, name: 'PC 1');
    expect(back.playbook, true);
    expect(back.folder, 'Corners');
    expect(TacticMeta.fromJson(meta.copyWith(playbook: false).toJson(), name: 'PC 1').playbook, false);
  });

  test('a board saved before the flag existed is not in the playbook', () {
    final back = TacticMeta.fromJson({
      'name': 'Old',
      'folder': '',
      'description': '',
      'coachingPoints': '',
      'createdAt': t.toIso8601String(),
      'updatedAt': t.toIso8601String(),
    }, name: 'Old');
    expect(back.playbook, false);
    expect(TacticMeta.initial('New').playbook, false);
  });

  test('copyWith keeps the flag unless told otherwise', () {
    final meta = TacticMeta(name: 'PC 1', playbook: true, createdAt: t, updatedAt: t);
    expect(meta.copyWith(description: 'left side').playbook, true);
    expect(meta.copyWith(playbook: false).playbook, false);
  });
}
