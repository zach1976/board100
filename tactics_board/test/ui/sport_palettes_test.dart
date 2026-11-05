import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics_board/models/sport_type.dart';
import 'package:tactics_board/ui/sport_palettes.g.dart';
import 'package:tactics_board/ui/tokens.dart';

/// Colour system V4.3 (tools/design/palette_v43.py), checked from the
/// app's side: what the generator promised is what the app carries.
void main() {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  const grounds = [
    LightTokens.surface,
    LightTokens.appBackground,
    LightTokens.elevatedSurface,
    LightTokens.pageBackground,
  ];

  test('every sport and the hub have a palette', () {
    for (final s in SportType.values) {
      expect(kSportColors[s], isNotNull, reason: s.name);
      expect(s.accent, kSportColors[s]!.primaryAccent);
    }
    expect(kSportColors[null], isNotNull, reason: 'hub');
  });

  test('button labels, brand text and strokes read on every light ground', () {
    for (final e in kSportColors.entries) {
      final c = e.value;
      final who = e.key?.name ?? 'hub';
      expect(contrast(c.primaryButtonForeground, c.primaryButtonFill),
          greaterThanOrEqualTo(4.5), reason: '$who button');
      for (final g in [...grounds, c.accentSoftBackground]) {
        expect(contrast(c.accentText, g), greaterThanOrEqualTo(4.5),
            reason: '$who accentText on $g');
        expect(contrast(c.selectedStroke, g), greaterThanOrEqualTo(3.0),
            reason: '$who selectedStroke on $g');
      }
      for (final g in grounds) {
        expect(contrast(c.secondaryAccentText, g), greaterThanOrEqualTo(4.5),
            reason: '$who secondaryAccentText');
        expect(contrast(c.secondaryAccentStroke, g), greaterThanOrEqualTo(3.0),
            reason: '$who secondaryAccentStroke');
      }
    }
  });

  test('shared text, semantic text and the input border read', () {
    for (final g in grounds) {
      for (final t in [
        LightTokens.textPrimary,
        LightTokens.textSecondary,
        LightTokens.textTertiary,
        LightTokens.success,
        LightTokens.error,
        LightTokens.information,
        LightTokens.warningText,
      ]) {
        expect(contrast(t, g), greaterThanOrEqualTo(4.5), reason: '$t on $g');
      }
      expect(contrast(LightTokens.inputBorder, g), greaterThanOrEqualTo(3.0));
      expect(contrast(LightTokens.focus, g), greaterThanOrEqualTo(3.0));
    }
    expect(contrast(LightTokens.warningText, LightTokens.warningBackground),
        greaterThanOrEqualTo(4.5));
    expect(contrast(LightTokens.warningBorder, LightTokens.warningBackground),
        greaterThanOrEqualTo(3.0));
  });

  test('a sport build takes its brand; the hub keeps its own', () {
    final saved = T.palette;
    addTearDown(() => T.palette = saved);
    T.palette = SportType.volleyball.chrome;
    expect(T.accent, kSportColors[SportType.volleyball]!.primaryAccent);
    expect(T.accentText, kSportColors[SportType.volleyball]!.accentText);
    T.palette = SportPalette.hub;
    expect(T.accent, kSportColors[null]!.primaryAccent);
    // The surfaces are the family's, not the sport's.
    expect(T.bg0, LightTokens.appBackground);
    expect(T.surface, LightTokens.surface);
  });
}
