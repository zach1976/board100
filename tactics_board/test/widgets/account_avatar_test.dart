import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/pages/main_shell.dart';

/// What the account card shows where a face goes.
///
/// Google hands over a `photoUrl`; Apple never does — Sign in with Apple
/// returns a name (first login only), an email and the tokens, and no
/// picture at all. So "the provider's avatar" is a Google-only story, and
/// the interesting case is the other one: an Apple coach must not be left
/// with the same grey silhouette as someone who has not signed in.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('initials when there is no picture — the Apple case',
      (tester) async {
    await tester.pumpWidget(host(const AccountAvatar(name: 'zach song')));
    expect(find.text('ZS'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
  });

  testWidgets('a one-word or CJK name gives one letter', (tester) async {
    await tester.pumpWidget(host(const AccountAvatar(name: 'Zach')));
    expect(find.text('Z'), findsOneWidget);

    await tester.pumpWidget(host(const AccountAvatar(name: '宋振宇')));
    // One character: the second character of a Chinese given name is not an
    // initial, and 宋振 as a monogram reads as a different name.
    expect(find.text('宋'), findsOneWidget);
  });

  testWidgets('the silhouette is only for a coach who is not signed in',
      (tester) async {
    await tester.pumpWidget(host(const AccountAvatar()));
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });

  testWidgets('a picture that will not load falls back to the initials',
      (tester) async {
    // No HTTP in a widget test: Image.network fails, which is exactly the
    // path a dead or expired avatar url takes on a phone.
    await tester.pumpWidget(host(
        const AccountAvatar(name: 'zach song', photo: 'https://example/a.png')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ZS'), findsOneWidget,
        reason: 'the card must not sit empty when the picture does not come');
  });
}
