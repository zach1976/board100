import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ipad_harness.dart';
import 'overflow_test.dart' show kLocales;

/// The four tools keep their words in half Split View (678pt wide) in every
/// language — French "Sélectionner" included — by putting the word under
/// the icon when it does not fit beside it. A phone keeps words beside
/// icons, exactly as before.
///
/// Measured in Roboto, loaded from the Flutter SDK: the test font sets
/// every glyph a full em wide, which no real font does.
Future<void> _loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.path;
  for (final name in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
    final f = File('$root/bin/cache/artifacts/material_fonts/$name');
    if (!f.existsSync()) continue;
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(f.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  }
}

void main() {
  testWidgets('tool labels at 678pt in all 12 locales', (tester) async {
    await tester.runAsync(_loadRoboto);
    await pumpBoard(tester, const Size(678, 1376));
    final ctx = tester.element(find.byType(Scaffold).first);
    // French first: the longest four words of the twelve.
    final order = [
      const Locale('fr', 'FR'),
      ...kLocales.where((l) => l.languageCode != 'fr'),
    ];
    for (final l in order) {
      await ctx.setLocale(l);
      await settle(tester);
      for (final key in ['mode_move', 'mode_draw', 'mode_select', 'add_label']) {
        final word = key.tr();
        final hit = find.text(word);
        expect(hit, findsWidgets, reason: '$key "$word" missing in $l');
        // Whole, not ellipsised: the word's box is as wide as the word.
        final box = tester.getSize(hit.last);
        final tp = TextPainter(
          text: TextSpan(
              text: word,
              style: (tester.widget<Text>(hit.last).style ?? const TextStyle())
                  .copyWith(fontFamily: 'Roboto')),
          textDirection: TextDirection.ltr,
        )..layout();
        expect(box.width, greaterThanOrEqualTo(tp.width - 0.5),
            reason: '"$word" cut in $l');
        tp.dispose();
      }
    }

    // A phone: unchanged — the rule that drops the words on a 402pt
    // phone still drops them, and never stacks them.
    await ctx.setLocale(const Locale('en', 'US'));
    tester.view.physicalSize = kPhone * 2;
    await settle(tester);
    expect(find.byIcon(Icons.open_with_rounded), findsWidgets);
    final move = find.text('Move');
    if (move.evaluate().isNotEmpty) {
      final icon = tester.getCenter(find.byIcon(Icons.open_with_rounded).last);
      expect((tester.getCenter(move.last).dy - icon.dy).abs(), lessThan(2),
          reason: 'phone keeps the word beside its icon');
    }
  });
}
