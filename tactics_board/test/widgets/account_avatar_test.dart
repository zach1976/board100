import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/pages/main_shell.dart';
import 'package:tactics_board/ui/tokens.dart';

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

  test('the colour is the name\'s, the same one every time', () {
    // Not decoration: a coach who sees a teal ZS today must see a teal ZS on
    // the next launch and on their other phone. String.hashCode would not
    // promise that, which is why AccountAvatar does its own arithmetic.
    final a = AccountAvatar.colorFor('zach song');
    expect(AccountAvatar.colorFor('zach song'), a);
    expect(AccountAvatar.colorFor('zach song'), a, reason: 'and again');
    expect(AccountAvatar.palette, contains(a));

    // Different names generally differ; across a handful of real-ish names
    // more than one colour must actually come out, or the hash is broken.
    final names = [
      'zach song', 'Li Wei', '宋振宇', 'Marco Rossi', 'Ana García',
      'Nguyen Van A', 'Kim Min-jun', 'Tanaka Yuki', 'Ahmad bin Ali',
    ];
    final seen = names.map(AccountAvatar.colorFor).toSet();
    expect(seen.length, greaterThan(2),
        reason: 'nine names landing on two colours is not a hash');

    // Nothing outside the app's palette can come out.
    for (final n in names) {
      expect(AccountAvatar.palette, contains(AccountAvatar.colorFor(n)));
    }

    // No name at all keeps the accent it has always been.
    expect(AccountAvatar.colorFor(null), T.accent);
    expect(AccountAvatar.colorFor('   '), T.accent);
  });

  testWidgets('the letters and the ring are the same colour', (tester) async {
    await tester.pumpWidget(host(const AccountAvatar(name: 'Marco Rossi')));
    final hue = AccountAvatar.colorFor('Marco Rossi');
    final text = tester.widget<Text>(find.text('MR'));
    expect(text.style?.color, hue);
    final circle = tester.widget<Container>(find
        .ancestor(of: find.text('MR'), matching: find.byType(Container))
        .first);
    final deco = circle.decoration! as BoxDecoration;
    expect(deco.color, hue.withValues(alpha: 0.14));
    expect(deco.shape, BoxShape.circle);
  });
}
