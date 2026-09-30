import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/state/tactics_state.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

/// 裁判和教练是人，不是器材：用和球员一样的人形画，空手，面向动作。
/// 以前用的是俯视角的贴图，和边线视角的球员站在一起姿态就不对。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PlayerIcon marker(MarkerShape shape) => PlayerIcon(
      id: 'm', label: '', team: PlayerTeam.neutral,
      position: Offset.zero, markerShape: shape);

  test('裁判、教练是人形标记；锥筒不是', () {
    expect(marker(MarkerShape.referee).isPersonMarker, isTrue);
    expect(marker(MarkerShape.coach).isPersonMarker, isTrue);
    expect(marker(MarkerShape.cone).isPersonMarker, isFalse);
  });

  test('人形标记不拿器械，不管这项运动的球员拿什么', () {
    for (final sport in SportType.values) {
      expect(TopDownPlayerPainter.figureFor(sport, marker(MarkerShape.referee)),
          PlayerFigure.plain, reason: sport.name);
    }
  });

  test('转裁判像转球员：按八分之一圈吸附，并且锁定朝向', () {
    final st = TacticsState();
    st.addPlayer(marker(MarkerShape.referee));
    final id = st.players.first.id;
    st.rotatePlayer(id, 1.0);
    final turned = st.players.first;
    expect(turned.rotation, closeTo(0.785, 0.01), reason: '吸附到 45°');
    expect(turned.facingLocked, isTrue, reason: '不然板子下一拍又把他转回去看球');
    // A cone keeps turning freely and never locks.
    st.addPlayer(marker(MarkerShape.cone).copyWith(id: 'cone'));
    st.rotatePlayer('cone', 1.0);
    final cone = st.players.firstWhere((p) => p.id == 'cone');
    expect(cone.facingLocked, isFalse);
  });

  test('裁判默认黑衣，教练默认深灰，换过颜色就用换的', () {
    expect(marker(MarkerShape.referee).color, const Color(0xFF212121));
    expect(marker(MarkerShape.coach).color, const Color(0xFF455A64));
    expect(marker(MarkerShape.referee).copyWith(customColor: Colors.red).color, Colors.red);
  });
}
