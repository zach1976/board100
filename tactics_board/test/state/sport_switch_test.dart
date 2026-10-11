import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/working_board_service.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// The hub switches sport inside one TacticsState. It used to keep the board
/// NAME across the switch, so the next sport's empty board autosaved over the
/// previous sport's saved board of that name.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('switching sport forgets which board was open', () async {
    final s = TacticsState(sportType: SportType.tableTennis);
    s.currentTacticName = 'TT a';
    s.setSportType(SportType.rugby);
    expect(s.currentTacticName, isNull);
    expect(s.drillBeats, isEmpty);
  });

  test('each sport gets its own working board back', () async {
    final s = TacticsState(sportType: SportType.tableTennis);
    s.currentTacticName = 'TT a';
    s.setSportType(SportType.rugby);
    await Future<void>.delayed(Duration.zero);
    final parked = await WorkingBoardService.instance.load(SportType.tableTennis);
    expect(parked?['currentName'], 'TT a');

    s.setSportType(SportType.tableTennis);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(s.currentTacticName, 'TT a');
  });
}
