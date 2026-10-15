import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/ui/sport_palettes.g.dart';
import 'package:tactics_board/ui/tokens.dart';

/// The family colour system (tools/design/sport_palettes.py), checked from
/// the app's side: what the generator promised is what the app carries.
void main() {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  test('every sport has a palette', () {
    for (final s in SportType.values) {
      expect(kSportColors[s], isNotNull, reason: s.name);
      expect(s.accent, kSportColors[s]!.primaryAccent);
    }
  });

  test('text on every accent and every accent on its background read', () {
    for (final e in kSportColors.entries) {
      final c = e.value;
      expect(contrast(c.onPrimaryAccent, c.primaryAccent),
          greaterThanOrEqualTo(4.5), reason: '${e.key.name} button text');
      expect(contrast(c.primaryAccent, c.background),
          greaterThanOrEqualTo(4.5), reason: '${e.key.name} accent on page');
      expect(contrast(c.primaryAccent, c.elevatedSurface),
          greaterThanOrEqualTo(3.0), reason: '${e.key.name} accent on card');
      expect(contrast(FamilyTokens.textSecondary, c.elevatedSurface),
          greaterThanOrEqualTo(4.5), reason: '${e.key.name} secondary text');
    }
  });

  test('the surfaces are equally dark in every app', () {
    for (final pick in <Color Function(SportColors)>[
      (c) => c.background,
      (c) => c.surface,
      (c) => c.elevatedSurface,
    ]) {
      final ls = kSportColors.values.map((c) => pick(c).computeLuminance());
      expect(ls.reduce(math.max) - ls.reduce(math.min), lessThan(0.002));
    }
  });

  test('a sport build takes its accent; the hub keeps teal', () {
    final saved = T.palette;
    addTearDown(() => T.palette = saved);
    T.palette = SportType.volleyball.chrome;
    expect(T.accent, kSportColors[SportType.volleyball]!.primaryAccent);
    expect(T.bg0, kSportColors[SportType.volleyball]!.background);
    T.palette = SportPalette.teal;
    expect(T.accent, const Color(0xFF20C7C3));
  });
}
