import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'sport_formation.dart';

enum SportType {
  badminton,
  tableTennis,
  tennis,
  basketball,
  volleyball,
  pickleball,
  soccer,
  fieldHockey,
  rugby,
  baseball,
  handball,
  waterPolo,
  sepakTakraw,
  beachTennis,
  footvolley,
}

extension SportTypeExtension on SportType {
  String get translationKey {
    switch (this) {
      case SportType.badminton:    return 'sport_badminton';
      case SportType.tableTennis:  return 'sport_table_tennis';
      case SportType.tennis:       return 'sport_tennis';
      case SportType.basketball:   return 'sport_basketball';
      case SportType.volleyball:   return 'sport_volleyball';
      case SportType.pickleball:   return 'sport_pickleball';
      case SportType.soccer:       return 'sport_soccer';
      case SportType.fieldHockey:  return 'sport_field_hockey';
      case SportType.rugby:        return 'sport_rugby';
      case SportType.baseball:     return 'sport_baseball';
      case SportType.handball:     return 'sport_handball';
      case SportType.waterPolo:    return 'sport_water_polo';
      case SportType.sepakTakraw:  return 'sport_sepak_takraw';
      case SportType.beachTennis:  return 'sport_beach_tennis';
      case SportType.footvolley:   return 'sport_footvolley';
    }
  }

  String get displayName => translationKey.tr();

  String get emoji {
    switch (this) {
      case SportType.badminton:    return '🏸';
      case SportType.tableTennis:  return '🏓';
      case SportType.tennis:       return '🎾';
      case SportType.basketball:   return '🏀';
      case SportType.volleyball:   return '🏐';
      case SportType.pickleball:   return '🥒';
      case SportType.soccer:       return '⚽';
      case SportType.fieldHockey:  return '🏑';
      case SportType.rugby:        return '🏉';
      case SportType.baseball:     return '⚾';
      case SportType.handball:     return '🤾';
      case SportType.waterPolo:    return '🤽';
      case SportType.sepakTakraw:  return '🧶';
      case SportType.beachTennis:  return '🏖️';
      case SportType.footvolley:   return '👣';
    }
  }

  /// True for sports whose court is naturally landscape (horizontal).
  bool get isLandscapeCourt => false;

  /// True for sports with a net dividing the court.
  bool get hasNet {
    switch (this) {
      case SportType.badminton:
      case SportType.tableTennis:
      case SportType.tennis:
      case SportType.volleyball:
      case SportType.pickleball:
      case SportType.sepakTakraw:
      case SportType.beachTennis:
      case SportType.footvolley:
        return true;
      case SportType.basketball:
      case SportType.soccer:
      case SportType.fieldHockey:
      case SportType.rugby:
      case SportType.baseball:
      case SportType.handball:
      case SportType.waterPolo:
        return false;
    }
  }

  /// Apple numeric ID of the corresponding ScoreSyncer scoring app.
  /// Empty string means the app is not yet on the App Store.
  String get scorerAppleId {
    switch (this) {
      case SportType.badminton:    return '6747377276';
      case SportType.tableTennis:  return '6747377184';
      case SportType.tennis:       return '6748001336';
      case SportType.basketball:   return '6761400751';
      case SportType.volleyball:   return '6761400656';
      case SportType.pickleball:   return '6744628482';
      case SportType.soccer:       return ''; // not yet on App Store
      case SportType.fieldHockey:  return ''; // not yet on App Store
      case SportType.rugby:        return ''; // not yet on App Store
      case SportType.baseball:     return ''; // not yet on App Store
      case SportType.handball:     return ''; // not yet on App Store
      case SportType.waterPolo:    return ''; // not yet on App Store
      case SportType.sepakTakraw:  return ''; // not yet on App Store
      case SportType.beachTennis:  return ''; // not yet on App Store
      case SportType.footvolley:   return ''; // not yet on App Store
    }
  }

  /// Display name of the corresponding ScoreSyncer scoring app.
  String get scorerAppName {
    switch (this) {
      case SportType.badminton:    return 'BadmintonPoints';
      case SportType.tableTennis:  return 'PingpongPoints';
      case SportType.tennis:       return 'TennisKeeper';
      case SportType.basketball:   return 'BasketballPoints';
      case SportType.volleyball:   return 'VolleyballPoints';
      case SportType.pickleball:   return 'PicklePoints';
      case SportType.soccer:       return 'SoccerPoints';
      case SportType.fieldHockey:  return 'FieldHockeyPoints';
      case SportType.rugby:        return 'RugbyPoints';
      case SportType.baseball:     return 'BaseballPoints';
      case SportType.handball:     return 'HandballPoints';
      case SportType.waterPolo:    return 'WaterPoloPoints';
      case SportType.sepakTakraw:  return 'SepakTakrawPoints';
      case SportType.beachTennis:  return 'BeachTennisPoints';
      case SportType.footvolley:   return 'FootvolleyPoints';
    }
  }

  /// Court background color, used for external display padding.
  Color get courtColor {
    switch (this) {
      case SportType.badminton:   return const Color(0xFF1B5E20);
      case SportType.tableTennis: return const Color(0xFF1565C0);
      case SportType.tennis:      return const Color(0xFF1565C0);
      case SportType.basketball:  return const Color(0xFFB5651D);
      case SportType.volleyball:  return const Color(0xFFF57F17);
      case SportType.pickleball:  return const Color(0xFF2E7D32);
      case SportType.soccer:      return const Color(0xFF2D8A2D);
      case SportType.fieldHockey: return const Color(0xFF1976D2); // blue astroturf
      case SportType.rugby:       return const Color(0xFF2E7D32); // rugby grass
      case SportType.baseball:    return const Color(0xFF2E7D32); // outfield grass
      case SportType.handball:    return const Color(0xFF1565C0); // indoor blue resin
      case SportType.waterPolo:   return const Color(0xFF0277BD); // pool water blue
      case SportType.sepakTakraw: return const Color(0xFF1565C0); // indoor blue
      case SportType.beachTennis: return const Color(0xFFEAC478); // beach sand
      case SportType.footvolley:  return const Color(0xFFE5B880); // beach sand
    }
  }

  /// Normalized Y position of the net (0.5 = center). Home team plays below, away above.
  double get netY => 0.5;

  /// True for racquet/net sports that have singles/doubles variants
  bool get hasDoubles => formations.any((f) => f.nameKey == 'formation_doubles');

  /// Returns the playable field/court rect inside the canvas, matching the
  /// geometry each sport's court painter draws. Formation coordinates (0..1)
  /// are resolved against this rect so players stay inside the field lines
  /// regardless of canvas aspect ratio (important on iPad portrait).
  Rect fieldRect(Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    // aspect = field width / field height (portrait, < 1)
    late final double aspect;
    // scaleW applies when fitting by width; scaleH when fitting by height.
    late final double scaleW;
    late final double scaleH;
    switch (this) {
      case SportType.soccer:      aspect = 68 / 105;    scaleW = 0.90; scaleH = 0.90; break;
      case SportType.basketball:  aspect = 15 / 28;     scaleW = 0.90; scaleH = 0.90; break;
      case SportType.badminton:   aspect = 6.1 / 13.4;  scaleW = 0.88; scaleH = 0.88; break;
      case SportType.pickleball:  aspect = 6.1 / 13.41; scaleW = 0.88; scaleH = 0.88; break;
      case SportType.tennis:      aspect = 10.97 / 23.77; scaleW = 0.85; scaleH = 0.85; break;
      case SportType.volleyball:  aspect = 9 / 18;      scaleW = 0.85; scaleH = 0.85; break;
      case SportType.tableTennis: aspect = 1.525 / 2.74; scaleW = 0.65; scaleH = 0.55; break;
      case SportType.fieldHockey: aspect = 55 / 91.4;   scaleW = 0.90; scaleH = 0.90; break;
      case SportType.rugby:       aspect = 70 / 144;    scaleW = 0.92; scaleH = 0.92; break;
      case SportType.baseball:    aspect = 1.0;         scaleW = 0.95; scaleH = 0.95; break;
      case SportType.handball:    aspect = 20 / 40;     scaleW = 0.90; scaleH = 0.90; break;
      case SportType.waterPolo:   aspect = 20 / 30;     scaleW = 0.88; scaleH = 0.88; break;
      case SportType.sepakTakraw: aspect = 6.1 / 13.4;  scaleW = 0.88; scaleH = 0.88; break;
      case SportType.beachTennis: aspect = 8 / 16;      scaleW = 0.85; scaleH = 0.85; break;
      case SportType.footvolley:  aspect = 9 / 18;      scaleW = 0.85; scaleH = 0.85; break;
    }
    double cw, ch;
    if (w / h > aspect) {
      ch = h * scaleH;
      cw = ch * aspect;
    } else {
      cw = w * scaleW;
      ch = cw / aspect;
    }
    return Rect.fromLTWH((w - cw) / 2, (h - ch) / 2, cw, ch);
  }

  List<SportFormation> get formations {
    switch (this) {
      case SportType.badminton:
        return const [
          SportFormation(
            nameKey: 'formation_singles',
            homePositions: [Offset(0.5, 0.75)],
            awayPositions: [Offset(0.5, 0.25)],
          ),
          SportFormation(
            nameKey: 'formation_doubles',
            homePositions: [Offset(0.35, 0.82), Offset(0.65, 0.70)],
            awayPositions: [Offset(0.65, 0.18), Offset(0.35, 0.30)],
          ),
        ];

      case SportType.tableTennis:
        // Table area: ~y=0.19..0.81 (65% width), players must be outside
        return const [
          SportFormation(
            nameKey: 'formation_singles',
            homePositions: [Offset(0.5, 0.90)],
            awayPositions: [Offset(0.5, 0.10)],
          ),
          SportFormation(
            nameKey: 'formation_doubles',
            homePositions: [Offset(0.35, 0.90), Offset(0.65, 0.90)],
            awayPositions: [Offset(0.65, 0.10), Offset(0.35, 0.10)],
          ),
        ];

      case SportType.tennis:
        return const [
          SportFormation(
            nameKey: 'formation_singles',
            homePositions: [Offset(0.5, 0.78)],
            awayPositions: [Offset(0.5, 0.22)],
          ),
          SportFormation(
            nameKey: 'formation_doubles',
            // Server at baseline right, partner at net left
            homePositions: [Offset(0.7, 0.78), Offset(0.3, 0.60)],
            awayPositions: [Offset(0.3, 0.22), Offset(0.7, 0.40)],
          ),
        ];

      case SportType.basketball:
        // Court: y≈0.05..0.95, center=0.50
        // Bottom basket≈0.87, 3pt arc top≈0.67, FT line≈0.75
        return const [
          // 5v5: 1-2-2 Horns — PG above 3pt, SG/SF at elbows, PF/C blocks
          SportFormation(
            nameKey: 'formation_122',
            homePositions: [
              Offset(0.5, 0.58),   // PG - above 3pt arc
              Offset(0.28, 0.68),  // SG - left wing at 3pt
              Offset(0.72, 0.68),  // SF - right wing at 3pt
              Offset(0.38, 0.78),  // PF - left block
              Offset(0.62, 0.78),  // C  - right block
            ],
            awayPositions: [
              Offset(0.5, 0.42),
              Offset(0.72, 0.32),
              Offset(0.28, 0.32),
              Offset(0.62, 0.22),
              Offset(0.38, 0.22),
            ],
          ),
          // 5v5: 2-3 — two guards up top, three low
          SportFormation(
            nameKey: 'formation_23',
            homePositions: [
              Offset(0.32, 0.58),  // PG - top left
              Offset(0.68, 0.58),  // SG - top right
              Offset(0.85, 0.70),  // SF - right wing
              Offset(0.30, 0.78),  // PF - left post
              Offset(0.60, 0.78),  // C  - right post
            ],
            awayPositions: [
              Offset(0.68, 0.42),
              Offset(0.32, 0.42),
              Offset(0.15, 0.30),
              Offset(0.70, 0.22),
              Offset(0.40, 0.22),
            ],
          ),
          // 5v5: 1-3-1 — PG top, wings spread, high/low post
          SportFormation(
            nameKey: 'formation_131',
            homePositions: [
              Offset(0.5, 0.56),   // PG - top
              Offset(0.13, 0.68),  // SG - left wing
              Offset(0.87, 0.68),  // SF - right wing
              Offset(0.5, 0.72),   // PF - high post (FT line)
              Offset(0.5, 0.82),   // C  - low post
            ],
            awayPositions: [
              Offset(0.5, 0.44),
              Offset(0.87, 0.32),
              Offset(0.13, 0.32),
              Offset(0.5, 0.28),
              Offset(0.5, 0.18),
            ],
          ),
          // 5v5: 1-4 Spread — PG top, 4 spread around paint
          SportFormation(
            nameKey: 'formation_14',
            homePositions: [
              Offset(0.5, 0.58),   // PG - top of key
              Offset(0.20, 0.70),  // SG - left wing
              Offset(0.80, 0.70),  // SF - right wing
              Offset(0.30, 0.82),  // PF - left block
              Offset(0.70, 0.82),  // C  - right block
            ],
            awayPositions: [
              Offset(0.5, 0.42),
              Offset(0.80, 0.30),
              Offset(0.20, 0.30),
              Offset(0.70, 0.18),
              Offset(0.30, 0.18),
            ],
          ),
          // 3v3: Triangle — spread across half court
          SportFormation(
            nameKey: 'formation_3v3',
            homePositions: [
              Offset(0.5, 0.58),   // top (above 3pt)
              Offset(0.18, 0.72),  // left wing
              Offset(0.82, 0.72),  // right wing
            ],
            awayPositions: [
              Offset(0.5, 0.42),
              Offset(0.82, 0.28),
              Offset(0.18, 0.28),
            ],
          ),
        ];

      case SportType.volleyball:
        // Court: ~y=0.10..0.90, net at 0.50
        // Standard 6 positions: front row (4,3,2) + back row (5,6,1)
        return const [
          // 5-1 formation (standard rotation 1)
          SportFormation(
            nameKey: 'formation_6v6',
            homePositions: [
              // Front row: LF(4), CF(3), RF(2)
              Offset(0.18, 0.56), Offset(0.50, 0.55), Offset(0.82, 0.56),
              // Back row: LB(5), CB(6), RB(1-server)
              Offset(0.18, 0.74), Offset(0.50, 0.76), Offset(0.82, 0.74),
            ],
            awayPositions: [
              Offset(0.82, 0.44), Offset(0.50, 0.45), Offset(0.18, 0.44),
              Offset(0.82, 0.26), Offset(0.50, 0.24), Offset(0.18, 0.26),
            ],
          ),
        ];

      case SportType.pickleball:
        return const [
          SportFormation(
            nameKey: 'formation_singles',
            homePositions: [Offset(0.5, 0.75)],
            awayPositions: [Offset(0.5, 0.25)],
          ),
          SportFormation(
            nameKey: 'formation_doubles',
            homePositions: [Offset(0.33, 0.72), Offset(0.67, 0.72)],
            awayPositions: [Offset(0.33, 0.28), Offset(0.67, 0.28)],
          ),
        ];

      case SportType.soccer:
        return const [
          // Field in canvas: ~y=0.13..0.87
          // Home=bottom(0.87), Away=top(0.13), Center=0.50
          // 11v11: 4-4-2
          SportFormation(
            nameKey: 'formation_442',
            homePositions: [
              Offset(0.5, 0.80),  // GK
              Offset(0.14, 0.71), Offset(0.38, 0.70), Offset(0.62, 0.70), Offset(0.86, 0.71), // DEF
              Offset(0.14, 0.58), Offset(0.38, 0.57), Offset(0.62, 0.57), Offset(0.86, 0.58), // MID
              Offset(0.38, 0.52), Offset(0.62, 0.52), // FWD (home side of halfway)
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.86, 0.29), Offset(0.62, 0.30), Offset(0.38, 0.30), Offset(0.14, 0.29),
              Offset(0.86, 0.42), Offset(0.62, 0.43), Offset(0.38, 0.43), Offset(0.14, 0.42),
              Offset(0.62, 0.48), Offset(0.38, 0.48), // FWD (away side of halfway)
            ],
          ),
          // 11v11: 4-3-3
          SportFormation(
            nameKey: 'formation_433',
            homePositions: [
              Offset(0.5, 0.80),  // GK
              Offset(0.14, 0.71), Offset(0.38, 0.70), Offset(0.62, 0.70), Offset(0.86, 0.71), // DEF
              Offset(0.28, 0.59), Offset(0.5, 0.58), Offset(0.72, 0.59), // MID
              Offset(0.15, 0.52), Offset(0.5, 0.51), Offset(0.85, 0.52), // FWD (home side of halfway)
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.86, 0.29), Offset(0.62, 0.30), Offset(0.38, 0.30), Offset(0.14, 0.29),
              Offset(0.72, 0.41), Offset(0.5, 0.42), Offset(0.28, 0.41),
              Offset(0.85, 0.48), Offset(0.5, 0.49), Offset(0.15, 0.48), // FWD (away side of halfway)
            ],
          ),
          // 11v11: 3-5-2
          SportFormation(
            nameKey: 'formation_352',
            homePositions: [
              Offset(0.5, 0.80),  // GK
              Offset(0.22, 0.71), Offset(0.5, 0.70), Offset(0.78, 0.71), // DEF
              Offset(0.10, 0.59), Offset(0.32, 0.58), Offset(0.5, 0.57), Offset(0.68, 0.58), Offset(0.90, 0.59), // MID
              Offset(0.38, 0.52), Offset(0.62, 0.52), // FWD (home side of halfway)
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.78, 0.29), Offset(0.5, 0.30), Offset(0.22, 0.29),
              Offset(0.90, 0.41), Offset(0.68, 0.42), Offset(0.5, 0.43), Offset(0.32, 0.42), Offset(0.10, 0.41),
              Offset(0.62, 0.48), Offset(0.38, 0.48), // FWD (away side of halfway)
            ],
          ),
          // 11v11: 4-2-3-1
          SportFormation(
            nameKey: 'formation_4231',
            homePositions: [
              Offset(0.5, 0.80),  // GK
              Offset(0.14, 0.71), Offset(0.38, 0.70), Offset(0.62, 0.70), Offset(0.86, 0.71), // DEF
              Offset(0.38, 0.62), Offset(0.62, 0.62), // DM
              Offset(0.15, 0.54), Offset(0.5, 0.53), Offset(0.85, 0.54), // AM
              Offset(0.5, 0.49), // ST
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.86, 0.29), Offset(0.62, 0.30), Offset(0.38, 0.30), Offset(0.14, 0.29),
              Offset(0.62, 0.38), Offset(0.38, 0.38),
              Offset(0.85, 0.46), Offset(0.5, 0.47), Offset(0.15, 0.46),
              Offset(0.5, 0.51),
            ],
          ),
          // 5v5 futsal
          SportFormation(
            nameKey: 'formation_5v5',
            homePositions: [
              Offset(0.5, 0.80),
              Offset(0.28, 0.70), Offset(0.72, 0.70),
              Offset(0.28, 0.56), Offset(0.72, 0.56),
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.28, 0.30), Offset(0.72, 0.30),
              Offset(0.28, 0.44), Offset(0.72, 0.44),
            ],
          ),
          // 7v7
          SportFormation(
            nameKey: 'formation_7v7',
            homePositions: [
              Offset(0.5, 0.80),
              Offset(0.25, 0.71), Offset(0.75, 0.71),
              Offset(0.15, 0.59), Offset(0.5, 0.58), Offset(0.85, 0.59),
              Offset(0.5, 0.52), // FWD (home side of halfway)
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.25, 0.29), Offset(0.75, 0.29),
              Offset(0.15, 0.41), Offset(0.5, 0.42), Offset(0.85, 0.41),
              Offset(0.5, 0.48), // FWD (away side of halfway)
            ],
          ),
        ];

      case SportType.fieldHockey:
        // Field: 55m × 91.4m; 23m line ≈ y=0.75/0.25; shooting circle at 14.63m
        return const [
          // 11v11: 4-3-3 (modern attacking)
          SportFormation(
            nameKey: 'formation_433',
            homePositions: [
              Offset(0.5, 0.82),  // GK
              Offset(0.15, 0.72), Offset(0.38, 0.71), Offset(0.62, 0.71), Offset(0.85, 0.72), // DEF
              Offset(0.28, 0.58), Offset(0.5, 0.57), Offset(0.72, 0.58), // MID
              Offset(0.18, 0.52), Offset(0.5, 0.51), Offset(0.82, 0.52), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.18),
              Offset(0.85, 0.28), Offset(0.62, 0.29), Offset(0.38, 0.29), Offset(0.15, 0.28),
              Offset(0.72, 0.42), Offset(0.5, 0.43), Offset(0.28, 0.42),
              Offset(0.82, 0.48), Offset(0.5, 0.49), Offset(0.18, 0.48),
            ],
          ),
          // 11v11: 3-3-3-1 (modern balanced)
          SportFormation(
            nameKey: 'formation_3331',
            homePositions: [
              Offset(0.5, 0.82),  // GK
              Offset(0.22, 0.72), Offset(0.5, 0.71), Offset(0.78, 0.72), // DEF
              Offset(0.22, 0.62), Offset(0.5, 0.61), Offset(0.78, 0.62), // HALVES
              Offset(0.22, 0.55), Offset(0.5, 0.54), Offset(0.78, 0.55), // MID
              Offset(0.5, 0.50), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.18),
              Offset(0.78, 0.28), Offset(0.5, 0.29), Offset(0.22, 0.28),
              Offset(0.78, 0.38), Offset(0.5, 0.39), Offset(0.22, 0.38),
              Offset(0.78, 0.45), Offset(0.5, 0.46), Offset(0.22, 0.45),
              Offset(0.5, 0.50),
            ],
          ),
          // 11v11: 5-3-2 (traditional defensive)
          SportFormation(
            nameKey: 'formation_532',
            homePositions: [
              Offset(0.5, 0.82),  // GK
              Offset(0.12, 0.72), Offset(0.32, 0.71), Offset(0.5, 0.70), Offset(0.68, 0.71), Offset(0.88, 0.72), // DEF
              Offset(0.28, 0.60), Offset(0.5, 0.59), Offset(0.72, 0.60), // MID
              Offset(0.38, 0.52), Offset(0.62, 0.52), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.18),
              Offset(0.88, 0.28), Offset(0.68, 0.29), Offset(0.5, 0.30), Offset(0.32, 0.29), Offset(0.12, 0.28),
              Offset(0.72, 0.40), Offset(0.5, 0.41), Offset(0.28, 0.40),
              Offset(0.62, 0.48), Offset(0.38, 0.48),
            ],
          ),
          // Hockey5s (5v5 + GK) — shorter pitch, but we keep same canvas
          SportFormation(
            nameKey: 'formation_5v5',
            homePositions: [
              Offset(0.5, 0.82),  // GK
              Offset(0.25, 0.68), Offset(0.75, 0.68), // BACK
              Offset(0.5, 0.58),                       // CENTER
              Offset(0.25, 0.52), Offset(0.75, 0.52), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.18),
              Offset(0.75, 0.32), Offset(0.25, 0.32),
              Offset(0.5, 0.42),
              Offset(0.75, 0.48), Offset(0.25, 0.48),
            ],
          ),
        ];

      case SportType.rugby:
        // Field 70m × 144m (incl. in-goals). Try lines ≈ y=0.153/0.847,
        // halfway = 0.5. Players placed inside the playing area.
        return const [
          // 15v15 Rugby Union — phase-play attacking shape
          SportFormation(
            nameKey: 'formation_15v15',
            homePositions: [
              // Forwards (8) — pod near halfway
              Offset(0.42, 0.65), Offset(0.50, 0.65), Offset(0.58, 0.65), // front row
              Offset(0.46, 0.69), Offset(0.54, 0.69),                     // locks
              Offset(0.40, 0.72), Offset(0.50, 0.73), Offset(0.60, 0.72), // back row
              // Backs (7)
              Offset(0.50, 0.77), // 9 scrum-half
              Offset(0.36, 0.79), // 10 fly-half
              Offset(0.27, 0.80), // 12 inside center
              Offset(0.18, 0.80), // 13 outside center
              Offset(0.07, 0.78), // 11 left wing
              Offset(0.93, 0.78), // 14 right wing
              Offset(0.50, 0.90), // 15 full-back
            ],
            awayPositions: [
              Offset(0.58, 0.35), Offset(0.50, 0.35), Offset(0.42, 0.35),
              Offset(0.54, 0.31), Offset(0.46, 0.31),
              Offset(0.60, 0.28), Offset(0.50, 0.27), Offset(0.40, 0.28),
              Offset(0.50, 0.23),
              Offset(0.64, 0.21),
              Offset(0.73, 0.20),
              Offset(0.82, 0.20),
              Offset(0.93, 0.22),
              Offset(0.07, 0.22),
              Offset(0.50, 0.10),
            ],
          ),
          // 13v13 Rugby League
          SportFormation(
            nameKey: 'formation_13v13',
            homePositions: [
              // Forwards (6)
              Offset(0.40, 0.66), Offset(0.50, 0.66), Offset(0.60, 0.66),
              Offset(0.42, 0.71), Offset(0.58, 0.71),
              Offset(0.50, 0.74),
              // Backs (7)
              Offset(0.50, 0.79), // halfback
              Offset(0.42, 0.82), // five-eighth
              Offset(0.30, 0.84), // center L
              Offset(0.70, 0.84), // center R
              Offset(0.10, 0.85), // wing L
              Offset(0.90, 0.85), // wing R
              Offset(0.50, 0.92), // fullback
            ],
            awayPositions: [
              Offset(0.60, 0.34), Offset(0.50, 0.34), Offset(0.40, 0.34),
              Offset(0.58, 0.29), Offset(0.42, 0.29),
              Offset(0.50, 0.26),
              Offset(0.50, 0.21),
              Offset(0.58, 0.18),
              Offset(0.70, 0.16),
              Offset(0.30, 0.16),
              Offset(0.90, 0.15),
              Offset(0.10, 0.15),
              Offset(0.50, 0.08),
            ],
          ),
          // 7s — Rugby Sevens
          SportFormation(
            nameKey: 'formation_7v7',
            homePositions: [
              Offset(0.42, 0.65), Offset(0.50, 0.65), Offset(0.58, 0.65), // forwards
              Offset(0.50, 0.74),                                         // scrum-half
              Offset(0.32, 0.80),                                         // fly-half
              Offset(0.10, 0.85), Offset(0.90, 0.85),                     // wings
            ],
            awayPositions: [
              Offset(0.58, 0.35), Offset(0.50, 0.35), Offset(0.42, 0.35),
              Offset(0.50, 0.26),
              Offset(0.68, 0.20),
              Offset(0.90, 0.15), Offset(0.10, 0.15),
            ],
          ),
        ];

      case SportType.baseball:
        // Square field, home plate at bottom-center (0.5, 0.92).
        // Diamond rotated 45°: 1B right, 2B top, 3B left.
        // Defensive 9 = home; batter (& runners) = away.
        return const [
          // Standard defense (9 fielders + batter at plate)
          SportFormation(
            nameKey: 'formation_defense',
            homePositions: [
              Offset(0.50, 0.78), // P  - mound
              Offset(0.50, 0.96), // C  - behind plate
              Offset(0.68, 0.74), // 1B
              Offset(0.58, 0.62), // 2B
              Offset(0.42, 0.62), // SS
              Offset(0.32, 0.74), // 3B
              Offset(0.20, 0.30), // LF
              Offset(0.50, 0.18), // CF
              Offset(0.80, 0.30), // RF
            ],
            awayPositions: [
              Offset(0.55, 0.94), // batter (RHB)
            ],
            addBall: false,
          ),
          // Bases loaded (defense + batter + 3 runners)
          SportFormation(
            nameKey: 'formation_bases_loaded',
            homePositions: [
              Offset(0.50, 0.78), Offset(0.50, 0.96),
              Offset(0.68, 0.74), Offset(0.58, 0.62),
              Offset(0.42, 0.62), Offset(0.32, 0.74),
              Offset(0.20, 0.30), Offset(0.50, 0.18), Offset(0.80, 0.30),
            ],
            awayPositions: [
              Offset(0.55, 0.94), // batter
              Offset(0.66, 0.76), // R1 on 1B
              Offset(0.50, 0.60), // R2 on 2B
              Offset(0.34, 0.76), // R3 on 3B
            ],
            addBall: false,
          ),
          // Infield shift (vs pull-hitter, e.g. LHB)
          SportFormation(
            nameKey: 'formation_shift',
            homePositions: [
              Offset(0.50, 0.78), // P
              Offset(0.50, 0.96), // C
              Offset(0.78, 0.70), // 1B  (deep right)
              Offset(0.66, 0.58), // 2B  (shallow right field)
              Offset(0.55, 0.62), // SS  (between bases, right side)
              Offset(0.45, 0.62), // 3B  (where SS would be)
              Offset(0.18, 0.30), Offset(0.50, 0.20), Offset(0.82, 0.32), // OF shift right
            ],
            awayPositions: [
              Offset(0.45, 0.94), // LHB batter (left side of plate)
            ],
            addBall: false,
          ),
        ];

      case SportType.handball:
        // Court 20m × 40m portrait. Goals at y=0/1; 6m line ≈ 6/40=0.15;
        // 9m line ≈ 0.225. Halfway = 0.5.
        return const [
          // 7v7 — standard 6+1 attack vs 6-0 defense
          SportFormation(
            nameKey: 'formation_7v7',
            homePositions: [
              Offset(0.50, 0.96),  // GK
              Offset(0.08, 0.70),  // LW
              Offset(0.28, 0.66),  // LB
              Offset(0.50, 0.64),  // CB
              Offset(0.72, 0.66),  // RB
              Offset(0.92, 0.70),  // RW
              Offset(0.50, 0.56),  // CR pivot
            ],
            awayPositions: [
              Offset(0.50, 0.04),
              Offset(0.08, 0.30),
              Offset(0.28, 0.34),
              Offset(0.50, 0.36),
              Offset(0.72, 0.34),
              Offset(0.92, 0.30),
              Offset(0.50, 0.44),
            ],
          ),
          // 7v7 — attack at opponent's 9m vs 6-0 defense
          SportFormation(
            nameKey: 'formation_attack_60',
            homePositions: [
              Offset(0.50, 0.96),
              Offset(0.07, 0.32),  // LW high
              Offset(0.28, 0.27),  // LB
              Offset(0.50, 0.26),  // CB
              Offset(0.72, 0.27),  // RB
              Offset(0.93, 0.32),  // RW high
              Offset(0.50, 0.18),  // CR on 6m
            ],
            awayPositions: [
              Offset(0.50, 0.04),
              Offset(0.12, 0.13),  // 6 defenders on own 6m
              Offset(0.27, 0.16),
              Offset(0.42, 0.17),
              Offset(0.58, 0.17),
              Offset(0.73, 0.16),
              Offset(0.88, 0.13),
            ],
          ),
          // 4v4 (beach handball / training)
          SportFormation(
            nameKey: 'formation_4v4',
            homePositions: [
              Offset(0.50, 0.96),  // GK
              Offset(0.20, 0.62),
              Offset(0.50, 0.58),
              Offset(0.80, 0.62),
            ],
            awayPositions: [
              Offset(0.50, 0.04),
              Offset(0.80, 0.38),
              Offset(0.50, 0.42),
              Offset(0.20, 0.38),
            ],
          ),
        ];

      case SportType.waterPolo:
        // Pool 20m × 30m portrait. Goal y=0/1, 2m=0.067, 5m=0.167, 6m=0.20.
        return const [
          // 7v7 — umbrella attack vs M-zone defense
          SportFormation(
            nameKey: 'formation_7v7',
            homePositions: [
              Offset(0.50, 0.97), // GK
              Offset(0.50, 0.10), // hole set (CF) at opp 2m
              Offset(0.10, 0.20), // LW
              Offset(0.90, 0.20), // RW
              Offset(0.30, 0.18), // L flat/driver
              Offset(0.70, 0.18), // R flat/driver
              Offset(0.50, 0.30), // point
            ],
            awayPositions: [
              Offset(0.50, 0.03), // GK
              Offset(0.50, 0.13), // center back (hole D)
              Offset(0.18, 0.18),
              Offset(0.82, 0.18),
              Offset(0.32, 0.22),
              Offset(0.68, 0.22),
              Offset(0.50, 0.28),
            ],
          ),
          // Power play 6v5 (man-up attack)
          SportFormation(
            nameKey: 'formation_6v5',
            homePositions: [
              Offset(0.50, 0.97),
              Offset(0.20, 0.10), Offset(0.50, 0.08), Offset(0.80, 0.10),
              Offset(0.30, 0.20), Offset(0.70, 0.20),
            ],
            awayPositions: [
              Offset(0.50, 0.03),
              Offset(0.30, 0.16), Offset(0.50, 0.14), Offset(0.70, 0.16),
              Offset(0.50, 0.24),
            ],
          ),
          // 5+1 (training / shorter sides)
          SportFormation(
            nameKey: 'formation_5v5',
            homePositions: [
              Offset(0.50, 0.97), // GK
              Offset(0.50, 0.12), // hole
              Offset(0.20, 0.22), Offset(0.80, 0.22),
              Offset(0.50, 0.32),
            ],
            awayPositions: [
              Offset(0.50, 0.03),
              Offset(0.50, 0.16),
              Offset(0.25, 0.20), Offset(0.75, 0.20),
              Offset(0.50, 0.28),
            ],
          ),
        ];

      case SportType.sepakTakraw:
        // Court 6.1m × 13.4m portrait (same as badminton doubles).
        // Net at y=0.5. Service circle center at 2.45m from back line
        //  → home y = 1 - 2.45/13.4 ≈ 0.817; away y ≈ 0.183.
        // Quarter arcs (0.9m radius) sit at the sides of the net.
        return const [
          // Regu — 3v3 standard sepak takraw. Tekong (server) in service
          // circle; Apit Kiri (left) and Apit Kanan (right) near the net
          // quarter-arcs ready to spike.
          SportFormation(
            nameKey: 'formation_regu',
            homePositions: [
              Offset(0.50, 0.82), // Tekong (server)
              Offset(0.20, 0.60), // Apit Kiri (inside left)
              Offset(0.80, 0.60), // Apit Kanan (inside right)
            ],
            awayPositions: [
              Offset(0.50, 0.18),
              Offset(0.80, 0.40),
              Offset(0.20, 0.40),
            ],
          ),
          // Doubles — 2v2 variant
          SportFormation(
            nameKey: 'formation_doubles',
            homePositions: [
              Offset(0.50, 0.82), // server
              Offset(0.50, 0.62), // striker near net
            ],
            awayPositions: [
              Offset(0.50, 0.18),
              Offset(0.50, 0.38),
            ],
          ),
          // Quadrant — 4v4 training variant
          SportFormation(
            nameKey: 'formation_4v4',
            homePositions: [
              Offset(0.50, 0.82),
              Offset(0.20, 0.70), Offset(0.80, 0.70),
              Offset(0.50, 0.60),
            ],
            awayPositions: [
              Offset(0.50, 0.18),
              Offset(0.80, 0.30), Offset(0.20, 0.30),
              Offset(0.50, 0.40),
            ],
          ),
        ];

      case SportType.beachTennis:
        // Sand court 8m × 16m portrait. Net at y=0.5.
        return const [
          // Doubles — 2v2 standard beach tennis
          SportFormation(
            nameKey: 'formation_doubles',
            homePositions: [
              Offset(0.30, 0.70), // left
              Offset(0.70, 0.70), // right
            ],
            awayPositions: [
              Offset(0.70, 0.30),
              Offset(0.30, 0.30),
            ],
          ),
          // Singles — 1v1
          SportFormation(
            nameKey: 'formation_singles',
            homePositions: [Offset(0.50, 0.78)],
            awayPositions: [Offset(0.50, 0.22)],
          ),
        ];

      case SportType.footvolley:
        // Beach court 9m × 18m portrait. Net at y=0.5.
        return const [
          // Doubles — 2v2 standard footvolley
          SportFormation(
            nameKey: 'formation_doubles',
            homePositions: [
              Offset(0.30, 0.72),
              Offset(0.70, 0.72),
            ],
            awayPositions: [
              Offset(0.70, 0.28),
              Offset(0.30, 0.28),
            ],
          ),
          // 4v4 training variant
          SportFormation(
            nameKey: 'formation_4v4',
            homePositions: [
              Offset(0.25, 0.60), Offset(0.75, 0.60),
              Offset(0.25, 0.82), Offset(0.75, 0.82),
            ],
            awayPositions: [
              Offset(0.75, 0.40), Offset(0.25, 0.40),
              Offset(0.75, 0.18), Offset(0.25, 0.18),
            ],
          ),
        ];
    }
  }
}
