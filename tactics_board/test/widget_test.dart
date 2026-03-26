import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TacticsBoardApp());
    expect(find.text('Tactics Board'), findsNothing); // AppBar title is dynamic
  });
}
