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
  /// These are shown as-is in the selection card preview.
  /// Portrait courts are rotated 90° in the preview to fill the card.
  bool get isLandscapeCourt => false;

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
        return const [
          SportFormation(
            nameKey: 'formation_singles',
            homePositions: [Offset(0.5, 0.78)],
            awayPositions: [Offset(0.5, 0.22)],
          ),
          SportFormation(
            nameKey: 'formation_doubles',
            homePositions: [Offset(0.35, 0.72), Offset(0.65, 0.82)],
            awayPositions: [Offset(0.65, 0.28), Offset(0.35, 0.18)],
          ),
        ];

      case SportType.tennis:
        return const [
          SportFormation(
            nameKey: 'formation_singles',
            homePositions: [Offset(0.5, 0.75)],
            awayPositions: [Offset(0.5, 0.25)],
          ),
          SportFormation(
            nameKey: 'formation_doubles',
            homePositions: [Offset(0.28, 0.75), Offset(0.72, 0.75)],
            awayPositions: [Offset(0.28, 0.25), Offset(0.72, 0.25)],
          ),
        ];

      case SportType.basketball:
        return const [
          SportFormation(
            nameKey: 'formation_3v3',
            homePositions: [
              Offset(0.5, 0.82),
              Offset(0.22, 0.72),
              Offset(0.78, 0.72),
            ],
            awayPositions: [
              Offset(0.5, 0.18),
              Offset(0.78, 0.28),
              Offset(0.22, 0.28),
            ],
          ),
          SportFormation(
            nameKey: 'formation_5v5',
            homePositions: [
              Offset(0.5, 0.85),
              Offset(0.2, 0.72),
              Offset(0.8, 0.72),
              Offset(0.32, 0.60),
              Offset(0.5, 0.58),
            ],
            awayPositions: [
              Offset(0.5, 0.15),
              Offset(0.8, 0.28),
              Offset(0.2, 0.28),
              Offset(0.68, 0.40),
              Offset(0.5, 0.42),
            ],
          ),
        ];

      case SportType.volleyball:
        return const [
          SportFormation(
            nameKey: 'formation_6v6',
            homePositions: [
              Offset(0.2, 0.60), Offset(0.5, 0.58), Offset(0.8, 0.60),
              Offset(0.2, 0.83), Offset(0.5, 0.86), Offset(0.8, 0.83),
            ],
            awayPositions: [
              Offset(0.8, 0.40), Offset(0.5, 0.42), Offset(0.2, 0.40),
              Offset(0.8, 0.17), Offset(0.5, 0.14), Offset(0.2, 0.17),
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
          // 5v5: GK + 2 defenders + 2 forwards
          SportFormation(
            nameKey: 'formation_5v5',
            homePositions: [
              Offset(0.5, 0.93),
              Offset(0.28, 0.78), Offset(0.72, 0.78),
              Offset(0.28, 0.60), Offset(0.72, 0.60),
            ],
            awayPositions: [
              Offset(0.5, 0.07),
              Offset(0.28, 0.22), Offset(0.72, 0.22),
              Offset(0.28, 0.40), Offset(0.72, 0.40),
            ],
          ),
          // 7v7: GK + 2 defenders + 3 midfielders + 1 forward
          SportFormation(
            nameKey: 'formation_7v7',
            homePositions: [
              Offset(0.5, 0.94),
              Offset(0.25, 0.80), Offset(0.75, 0.80),
              Offset(0.15, 0.65), Offset(0.5, 0.64), Offset(0.85, 0.65),
              Offset(0.5, 0.52),
            ],
            awayPositions: [
              Offset(0.5, 0.06),
              Offset(0.25, 0.20), Offset(0.75, 0.20),
              Offset(0.15, 0.35), Offset(0.5, 0.36), Offset(0.85, 0.35),
              Offset(0.5, 0.48),
            ],
          ),
          // 11v11: 4-4-2 formation
          SportFormation(
            nameKey: 'formation_11v11',
            homePositions: [
              Offset(0.5, 0.95),
              Offset(0.12, 0.81), Offset(0.37, 0.79), Offset(0.63, 0.79), Offset(0.88, 0.81),
              Offset(0.12, 0.66), Offset(0.37, 0.64), Offset(0.63, 0.64), Offset(0.88, 0.66),
              Offset(0.35, 0.52), Offset(0.65, 0.52),
            ],
            awayPositions: [
              Offset(0.5, 0.05),
              Offset(0.88, 0.19), Offset(0.63, 0.21), Offset(0.37, 0.21), Offset(0.12, 0.19),
              Offset(0.88, 0.34), Offset(0.63, 0.36), Offset(0.37, 0.36), Offset(0.12, 0.34),
              Offset(0.65, 0.48), Offset(0.35, 0.48),
            ],
          ),
        ];
    }
  }
}
