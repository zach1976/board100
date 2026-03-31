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
    }
  }

  /// True for sports whose court is naturally landscape (horizontal).
  bool get isLandscapeCourt => false;

  /// True for racquet/net sports that have singles/doubles variants
  bool get hasDoubles => formations.any((f) => f.nameKey == 'formation_doubles');

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
              Offset(0.38, 0.50), Offset(0.62, 0.50), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.86, 0.29), Offset(0.62, 0.30), Offset(0.38, 0.30), Offset(0.14, 0.29),
              Offset(0.86, 0.42), Offset(0.62, 0.43), Offset(0.38, 0.43), Offset(0.14, 0.42),
              Offset(0.62, 0.50), Offset(0.38, 0.50),
            ],
          ),
          // 11v11: 4-3-3
          SportFormation(
            nameKey: 'formation_433',
            homePositions: [
              Offset(0.5, 0.80),  // GK
              Offset(0.14, 0.71), Offset(0.38, 0.70), Offset(0.62, 0.70), Offset(0.86, 0.71), // DEF
              Offset(0.28, 0.59), Offset(0.5, 0.58), Offset(0.72, 0.59), // MID
              Offset(0.15, 0.50), Offset(0.5, 0.49), Offset(0.85, 0.50), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.86, 0.29), Offset(0.62, 0.30), Offset(0.38, 0.30), Offset(0.14, 0.29),
              Offset(0.72, 0.41), Offset(0.5, 0.42), Offset(0.28, 0.41),
              Offset(0.85, 0.50), Offset(0.5, 0.51), Offset(0.15, 0.50),
            ],
          ),
          // 11v11: 3-5-2
          SportFormation(
            nameKey: 'formation_352',
            homePositions: [
              Offset(0.5, 0.80),  // GK
              Offset(0.22, 0.71), Offset(0.5, 0.70), Offset(0.78, 0.71), // DEF
              Offset(0.10, 0.59), Offset(0.32, 0.58), Offset(0.5, 0.57), Offset(0.68, 0.58), Offset(0.90, 0.59), // MID
              Offset(0.38, 0.50), Offset(0.62, 0.50), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.78, 0.29), Offset(0.5, 0.30), Offset(0.22, 0.29),
              Offset(0.90, 0.41), Offset(0.68, 0.42), Offset(0.5, 0.43), Offset(0.32, 0.42), Offset(0.10, 0.41),
              Offset(0.62, 0.50), Offset(0.38, 0.50),
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
              Offset(0.5, 0.50),
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.25, 0.29), Offset(0.75, 0.29),
              Offset(0.15, 0.41), Offset(0.5, 0.42), Offset(0.85, 0.41),
              Offset(0.5, 0.50),
            ],
          ),
        ];
    }
  }
}
