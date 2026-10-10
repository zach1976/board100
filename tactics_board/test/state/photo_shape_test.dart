import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// A picture brought in by the coach keeps its photo when its shape is
/// changed on the board, and the change can be undone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a photo element changes shape on the board', () {
    final state = TacticsState(sportType: SportType.volleyball);
    state.addPlayer(PlayerIcon(
      id: 'pic',
      label: '',
      team: PlayerTeam.neutral,
      photoId: 'photo-1',
      markerShape: MarkerShape.circle,
      position: const Offset(100, 100),
    ));
    state.updatePlayer('pic', markerShape: MarkerShape.diamond);
    final p = state.players.firstWhere((x) => x.id == 'pic');
    expect(p.markerShape, MarkerShape.diamond);
    expect(p.photoId, 'photo-1');
    state.undo();
    expect(state.players.firstWhere((x) => x.id == 'pic').markerShape,
        MarkerShape.circle);
  });
}
