import 'package:flutter/material.dart';
import 'sport_type.dart';

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
  static const Color teamBlue = Color(0xFF3A7DFF);
  static const Color teamRed = Color(0xFFFF5A5F);
  static const Color accentSelect = Color(0xFFFFD166);
  static const Color accentTimeline = Color(0xFF00C2B2);

  const SportTheme({
    required this.pageGradient,
    required this.panelColor,
    this.softLine = const Color(0xCCFFFFFF), // white @ 80%
  });
}

extension SportThemeExtension on SportType {
  SportTheme get theme {
    switch (this) {
      case SportType.soccer:
        return const SportTheme(
          pageGradient: [Color(0xFF1E3A2F), Color(0xFF0F2A20)],
          panelColor: Color(0xFF15303A),
        );
      case SportType.basketball:
        return const SportTheme(
          pageGradient: [Color(0xFF3A2615), Color(0xFF1F1409)],
          panelColor: Color(0xFF2A1B10),
        );
      case SportType.badminton:
        return const SportTheme(
          pageGradient: [Color(0xFF16331A), Color(0xFF0A1E0E)],
          panelColor: Color(0xFF12281A),
        );
      case SportType.tableTennis:
        return const SportTheme(
          pageGradient: [Color(0xFF0E2647), Color(0xFF071633)],
          panelColor: Color(0xFF0C1F3A),
        );
      case SportType.tennis:
        return const SportTheme(
          pageGradient: [Color(0xFF1A2E4A), Color(0xFF0C1A30)],
          panelColor: Color(0xFF14253B),
        );
      case SportType.volleyball:
        return const SportTheme(
          pageGradient: [Color(0xFF2D1F0F), Color(0xFF18100A)],
          panelColor: Color(0xFF22180D),
        );
      case SportType.pickleball:
        return const SportTheme(
          pageGradient: [Color(0xFF12331A), Color(0xFF081E0F)],
          panelColor: Color(0xFF0E281A),
        );
      case SportType.fieldHockey:
        return const SportTheme(
          pageGradient: [Color(0xFF0E2A47), Color(0xFF061730)],
          panelColor: Color(0xFF0B223A),
        );
      case SportType.rugby:
        return const SportTheme(
          pageGradient: [Color(0xFF1B3A23), Color(0xFF0A2010)],
          panelColor: Color(0xFF142E1B),
        );
      case SportType.baseball:
        return const SportTheme(
          pageGradient: [Color(0xFF1A3220), Color(0xFF0A1C12)],
          panelColor: Color(0xFF142819),
        );
      case SportType.handball:
        return const SportTheme(
          pageGradient: [Color(0xFF0E2746), Color(0xFF06162F)],
          panelColor: Color(0xFF0C1F3A),
        );
      case SportType.waterPolo:
        return const SportTheme(
          pageGradient: [Color(0xFF052E55), Color(0xFF011A35)],
          panelColor: Color(0xFF062543),
        );
      case SportType.sepakTakraw:
        return const SportTheme(
          pageGradient: [Color(0xFF0E2746), Color(0xFF06162F)],
          panelColor: Color(0xFF0C1F3A),
        );
      case SportType.beachTennis:
        return const SportTheme(
          pageGradient: [Color(0xFF3B2D14), Color(0xFF1F170A)],
          panelColor: Color(0xFF2C2110),
        );
      case SportType.footvolley:
        return const SportTheme(
          pageGradient: [Color(0xFF3B2D14), Color(0xFF1F170A)],
          panelColor: Color(0xFF2C2110),
        );
    }
  }
}
