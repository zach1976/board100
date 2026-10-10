import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';

/// Turning the phone in the middle of a drill.
///
/// The step the board is stopped on is drawn from [TacticsState
/// .animatedPositions], not from the player's own position, so the rescale
/// has to carry that map too. It did not: the arrows moved with the court
/// and the men stayed on their old canvas coordinates — on a volleyball
/// board sideways, three of them standing on the net with their arrows
/// ending short of their feet.
void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  test('the step a drill is stopped on moves with the court', () {
    const portrait = Size(402, 730);
    // A phone turned sideways: the canvas is laid out portrait inside a
    // RotatedBox, so its width is the card's height.
    const landscape = Size(386, 698);
    const sport = SportType.volleyball;

    final from = sport.fieldRect(portrait);
    // The middle of the net, and a man a quarter of the way up his own half.
    final net = Offset(from.center.dx, from.center.dy);
    final back = Offset(from.left + from.width * 0.25,
        from.top + from.height * 0.75);

    final s = TacticsState(sportType: sport)..setCanvasSizeSilent(portrait);
    s.addPlayer(PlayerIcon(
        id: 'p1', label: 'P1', team: PlayerTeam.home, position: back));
    s.updateAnimatedPositions({'p1': net});

    s.setCanvasSize(landscape);

    final to = sport.fieldRect(landscape);
    Offset onCourt(Offset p) => Offset(
        (p.dx - to.left) / to.width, (p.dy - to.top) / to.height);

    // Both the man and the step he is stopped on land on the same spot of
    // the court they started on.
    expect(onCourt(s.players.single.position).dx, closeTo(0.25, 0.001));
    expect(onCourt(s.players.single.position).dy, closeTo(0.75, 0.001));
    expect(onCourt(s.animatedPositions['p1']!).dx, closeTo(0.5, 0.001));
    expect(onCourt(s.animatedPositions['p1']!).dy, closeTo(0.5, 0.001));
  });
}
