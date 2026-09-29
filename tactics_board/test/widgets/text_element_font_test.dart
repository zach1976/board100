import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/player_icon.dart';
import 'package:tactics_board/widgets/player_icon_widget.dart';

/// 文字元素可以换字体、旋转，和它的颜色、大小一样是板子存下来的。
void main() {
  PlayerIcon text({String? font, double rotation = 0}) => PlayerIcon(
        id: 't', label: '这是啥', team: PlayerTeam.neutral,
        position: const Offset(100, 100), markerShape: MarkerShape.text,
        font: font, rotation: rotation);

  test('字体随板子保存，清掉后回到默认', () {
    final t = text(font: 'serif');
    final back = PlayerIcon.fromJson(jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>);
    expect(back.font, 'serif');
    expect(text().toJson().containsKey('font'), isFalse, reason: '默认不写这个键');
    expect(t.copyWith(clearFont: true).font, isNull);
    expect(t.copyWith().font, 'serif', reason: '不传就保持');
  });

  test('四种字体都能解析成一个平台字体名单，默认为空', () {
    for (final f in kTextFonts) {
      final faces = textFontFamily(f);
      expect(faces.isEmpty, f.isEmpty, reason: f);
    }
  });

  testWidgets('文字块整体旋转，字体进到样式里', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Center(child: TextElementChip(player: text(font: 'mono', rotation: 0.5)))));
    final rot = tester.widget<Transform>(find.byType(Transform).first);
    expect(rot.transform, isNot(Matrix4.identity()));
    final txt = tester.widget<Text>(find.text('这是啥'));
    expect(txt.style!.fontFamily, textFontFamily('mono').first);
  });
}
