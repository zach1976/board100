import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/services/recent_boards_service.dart';

/// What the recent list remembers.
///
/// The home page shows the last few; the list behind it is meant to answer
/// "what did I look at on Tuesday", which twelve entries cannot.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(String id) => RecentBoardsService.instance.record(
        SportType.soccer,
        RecentBoard(
          kind: RecentBoardKind.drill,
          id: id,
          label: id,
          openedAt: DateTime.now(),
        ),
      );

  test('keeps a hundred, newest first', () async {
    for (var i = 0; i < 130; i++) {
      await open('drill$i');
    }
    final list = await RecentBoardsService.instance.list(SportType.soccer);
    expect(list.length, 100);
    expect(list.first.id, 'drill129');
    expect(list.last.id, 'drill30');
  });

  test('opening one again moves it up instead of doubling it', () async {
    await open('a');
    await open('b');
    await open('a');
    final list = await RecentBoardsService.instance.list(SportType.soccer);
    expect([for (final r in list) r.id], ['a', 'b']);
  });

  test('a sport keeps its own list', () async {
    await open('a');
    final other = await RecentBoardsService.instance.list(SportType.tennis);
    expect(other, isEmpty);
  });
}
