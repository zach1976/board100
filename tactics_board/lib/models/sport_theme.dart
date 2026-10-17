import 'package:flutter/material.dart';
import 'sport_type.dart';
import '../ui/sport_palettes.g.dart';

/// Per-sport visual theme — page gradient, panel colors, accent palette and
/// softened court line color. Used to give each sport a distinct, professional
/// "tactics tool" look while sharing the same accent system.
class SportTheme {
  /// Page background gradient (top → bottom).
  final List<Color> pageGradient;

  /// Side panel / toolbar / sheet container background.
  final Color panelColor;

  /// Softened white used for court lines (less harsh than pure white).
  final Color softLine;

  // Shared accents
  // The semantic team colours, shared with T.home / T.away.
  static const Color teamBlue = Color(0xFF3E8EF7);
  static const Color teamRed = Color(0xFFFF5964);
  // Selection is teal everywhere, like every other selected state in
  // the app. Amber was a third accent with no meaning of its own.
  static const Color accentSelect = Color(0xFF18C7BC);
  static const Color accentTimeline = Color(0xFF00C2B2);

  const SportTheme({
    required this.pageGradient,
    required this.panelColor,
    // 78% white, matching T.turfLine: bright enough to read, dim
    // enough that a player token is always the stronger mark.
    this.softLine = const Color(0xC7FFFFFF),
  });
}

extension SportThemeExtension on SportType {
  /// The board page's ground, from the family colour system
  /// (tools/design/sport_palettes.py): the surface at the head fading to
  /// the page background at the foot, and the panels on the surface. It was
  /// a hand-written table of fifteen gradients, half of them brown.
  ///
  /// The board page is the one page that is not light: its ground is the
  /// sport's own colour taken deep — the accent most of the way to black —
  /// so the court and the white capsules sit on it the way a pitch sits
  /// in a stadium at night, and the pale page around the board stops
  /// reading as a document with a picture in it. (Volleyball's editor
  /// mock, 2026-10-17.) The panels stay the light surface.
  SportTheme get theme {
    final c = kSportColors[this]!;
    final deep = Color.lerp(c.primaryAccent, Colors.black, 0.58)!;
    final deeper = Color.lerp(c.primaryAccent, Colors.black, 0.68)!;
    return SportTheme(
      pageGradient: [deep, deeper],
      panelColor: c.surface,
    );
  }
}
