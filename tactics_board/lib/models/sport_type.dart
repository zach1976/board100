import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../ui/tokens.dart' show SportPalette;
import 'player_icon.dart';
import 'court_layout.dart';
import 'drill.dart' show DrillVocabulary;
import 'sport_formation.dart';

/// How the hub's picker shelves the fifteen sports. Fifteen equal cards were
/// a wall — eight of them blue courts — and a coach looking for pickleball
/// scanned every one. Three shelves is what a sports shop does.
enum SportGroup { pitch, net, other }

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

// Display order for the sport selection grid, picked per UI locale so
// each market sees its most popular sports first. Distinct from
// SportType's declaration order because the enum's integer index is
// persisted in JSON (player_icon / tactics_state / cloud sync) — we
// can't reshuffle the enum without breaking saved data.
List<SportType> sportDisplayOrderFor(Locale locale) {
  final lang = locale.languageCode;
  final country = locale.countryCode;
  if (lang == 'zh') return _orderZh;
  if (lang == 'en' && (country == 'US' || country == 'CA')) return _orderEnUs;
  if (lang == 'en') return _orderEnGb;
  if (lang == 'ja') return _orderJa;
  if (lang == 'ko') return _orderKo;
  if (lang == 'fr') return _orderFr;
  if (lang == 'es') return _orderEs;
  if (lang == 'vi') return _orderVi;
  if (lang == 'th') return _orderTh;
  if (lang == 'id') return _orderId;
  if (lang == 'ms') return _orderMs;
  if (lang == 'de') return _orderDe;
  if (lang == 'nl') return _orderNl;
  return _orderDefault;
}

const List<SportType> _orderZh = [
  SportType.soccer, SportType.basketball, SportType.tableTennis,
  SportType.badminton, SportType.tennis, SportType.volleyball,
  SportType.pickleball, SportType.baseball, SportType.fieldHockey,
  SportType.rugby, SportType.handball, SportType.waterPolo,
  SportType.beachTennis, SportType.footvolley, SportType.sepakTakraw,
];

const List<SportType> _orderEnUs = [
  SportType.basketball, SportType.baseball, SportType.soccer,
  SportType.tennis, SportType.volleyball, SportType.pickleball,
  SportType.fieldHockey, SportType.rugby, SportType.badminton,
  SportType.tableTennis, SportType.handball, SportType.waterPolo,
  SportType.beachTennis, SportType.footvolley, SportType.sepakTakraw,
];

const List<SportType> _orderEnGb = [
  SportType.soccer, SportType.tennis, SportType.rugby,
  SportType.fieldHockey, SportType.basketball, SportType.badminton,
  SportType.tableTennis, SportType.volleyball, SportType.pickleball,
  SportType.baseball, SportType.handball, SportType.waterPolo,
  SportType.beachTennis, SportType.footvolley, SportType.sepakTakraw,
];

const List<SportType> _orderJa = [
  SportType.baseball, SportType.soccer, SportType.tennis,
  SportType.basketball, SportType.volleyball, SportType.badminton,
  SportType.tableTennis, SportType.rugby, SportType.handball,
  SportType.waterPolo, SportType.pickleball, SportType.fieldHockey,
  SportType.beachTennis, SportType.footvolley, SportType.sepakTakraw,
];

const List<SportType> _orderKo = [
  SportType.soccer, SportType.baseball, SportType.basketball,
  SportType.volleyball, SportType.tableTennis, SportType.badminton,
  SportType.tennis, SportType.handball, SportType.waterPolo,
  SportType.fieldHockey, SportType.rugby, SportType.pickleball,
  SportType.beachTennis, SportType.footvolley, SportType.sepakTakraw,
];

const List<SportType> _orderFr = [
  SportType.soccer, SportType.tennis, SportType.rugby,
  SportType.basketball, SportType.handball, SportType.volleyball,
  SportType.badminton, SportType.tableTennis, SportType.fieldHockey,
  SportType.waterPolo, SportType.baseball, SportType.pickleball,
  SportType.beachTennis, SportType.footvolley, SportType.sepakTakraw,
];

const List<SportType> _orderEs = [
  SportType.soccer, SportType.basketball, SportType.tennis,
  SportType.baseball, SportType.volleyball, SportType.handball,
  SportType.badminton, SportType.tableTennis, SportType.waterPolo,
  SportType.fieldHockey, SportType.rugby, SportType.pickleball,
  SportType.beachTennis, SportType.footvolley, SportType.sepakTakraw,
];

const List<SportType> _orderVi = [
  SportType.soccer, SportType.badminton, SportType.tableTennis,
  SportType.tennis, SportType.volleyball, SportType.basketball,
  SportType.sepakTakraw, SportType.pickleball, SportType.baseball,
  SportType.handball, SportType.fieldHockey, SportType.waterPolo,
  SportType.rugby, SportType.beachTennis, SportType.footvolley,
];

const List<SportType> _orderTh = [
  SportType.soccer, SportType.badminton, SportType.sepakTakraw,
  SportType.volleyball, SportType.tableTennis, SportType.basketball,
  SportType.tennis, SportType.pickleball, SportType.baseball,
  SportType.handball, SportType.fieldHockey, SportType.waterPolo,
  SportType.rugby, SportType.beachTennis, SportType.footvolley,
];

const List<SportType> _orderId = [
  SportType.badminton, SportType.soccer, SportType.sepakTakraw,
  SportType.tableTennis, SportType.basketball, SportType.volleyball,
  SportType.tennis, SportType.pickleball, SportType.baseball,
  SportType.handball, SportType.fieldHockey, SportType.waterPolo,
  SportType.rugby, SportType.beachTennis, SportType.footvolley,
];

const List<SportType> _orderMs = [
  SportType.badminton, SportType.soccer, SportType.sepakTakraw,
  SportType.tableTennis, SportType.basketball, SportType.tennis,
  SportType.volleyball, SportType.pickleball, SportType.baseball,
  SportType.handball, SportType.fieldHockey, SportType.waterPolo,
  SportType.rugby, SportType.beachTennis, SportType.footvolley,
];

const List<SportType> _orderDe = [
  SportType.soccer, SportType.handball, SportType.tennis,
  SportType.basketball, SportType.volleyball, SportType.tableTennis,
  SportType.fieldHockey, SportType.badminton, SportType.waterPolo,
  SportType.pickleball, SportType.beachTennis, SportType.rugby,
  SportType.baseball, SportType.footvolley, SportType.sepakTakraw,
];

const List<SportType> _orderNl = [
  SportType.soccer, SportType.fieldHockey, SportType.tennis,
  SportType.volleyball, SportType.basketball, SportType.handball,
  SportType.waterPolo, SportType.baseball, SportType.tableTennis,
  SportType.badminton, SportType.pickleball, SportType.rugby,
  SportType.beachTennis, SportType.footvolley, SportType.sepakTakraw,
];

const List<SportType> _orderDefault = [
  SportType.soccer, SportType.basketball, SportType.tennis,
  SportType.volleyball, SportType.badminton, SportType.tableTennis,
  SportType.baseball, SportType.pickleball, SportType.fieldHockey,
  SportType.rugby, SportType.handball, SportType.waterPolo,
  SportType.beachTennis, SportType.footvolley, SportType.sepakTakraw,
];

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

  /// The sport's own colour — the one its icon is painted in and its card
  /// on the hub's picker is tinted with.
  Color get accent {
    switch (this) {
      case SportType.badminton:    return const Color(0xFF43A047);
      case SportType.tableTennis:  return const Color(0xFF1E88E5);
      case SportType.tennis:       return const Color(0xFF5C6BC0);
      case SportType.basketball:   return const Color(0xFFE65100);
      case SportType.volleyball:   return const Color(0xFFFFA000);
      case SportType.pickleball:   return const Color(0xFF00897B);
      case SportType.soccer:       return const Color(0xFF66BB6A);
      case SportType.fieldHockey:  return const Color(0xFF42A5F5);
      case SportType.rugby:        return const Color(0xFF8D6E63);
      case SportType.baseball:     return const Color(0xFFD32F2F);
      case SportType.handball:     return const Color(0xFF1976D2);
      case SportType.waterPolo:    return const Color(0xFF0288D1);
      case SportType.sepakTakraw:  return const Color(0xFFD4A017);
      case SportType.beachTennis:  return const Color(0xFFE6B058);
      case SportType.footvolley:   return const Color(0xFFFBC02D);
    }
  }

  /// The app's chrome — page, sheet, card — in this sport's colour family:
  /// the teal ladder re-hued to [accent]. A single-sport build sets
  /// [T.palette] from this before the first frame; the hub never does, and
  /// keeps [SportPalette.teal].
  SportPalette get chrome => SportPalette.hue(HSLColor.fromColor(accent).hue);

  /// Court background color, used for external display padding.
  Color get courtColor {
    switch (this) {
      case SportType.badminton:   return const Color(0xFF2E7D4F); // BWF mat green
      case SportType.tableTennis: return const Color(0xFF1D4F91); // ITTF table blue
      case SportType.tennis:      return const Color(0xFF2A65A5); // hard-court blue
      case SportType.basketball:  return const Color(0xFFB5651D);
      case SportType.volleyball:  return const Color(0xFFF57F17);
      case SportType.pickleball:  return const Color(0xFF1769B4); // blue hard court
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

  /// Selectable surface colours for the "Court" picker. The first entry is the
  /// default and reproduces the painter's original colour. Sports with a single
  /// (or no) entry offer no colour choice. Soccer manages its own turf list.
  List<CourtSurface> get courtSurfaces {
    // Each list leads with the painter's original colour so the default board
    // is visually unchanged, followed by a few alternates. One helper builds a
    // {swatch == color} entry since the picker dot is just the surface colour.
    switch (this) {
      case SportType.basketball:
        return const [
          CourtSurface(swatch: Color(0xFFD9A867), color: Color(0xFFD9A867)), // Maple
          CourtSurface(swatch: Color(0xFFB5762E), color: Color(0xFFB5762E)), // Walnut
          CourtSurface(swatch: Color(0xFFC44E3B), color: Color(0xFFC44E3B)), // Painted red
          CourtSurface(swatch: Color(0xFF2F6FB0), color: Color(0xFF2F6FB0)), // Painted blue
          CourtSurface(swatch: Color(0xFF4C5157), color: Color(0xFF4C5157)), // Slate grey
        ];
      case SportType.badminton:
        return _surfaces(const [0xFF2E7D4F, 0xFF1565C0, 0xFFB5762E, 0xFF4C5157]);
      case SportType.tableTennis:
        return _surfaces(const [0xFF1D4F91, 0xFF0D3A6B, 0xFF1B5E20, 0xFF4C5157]);
      case SportType.tennis:
        return _surfaces(const [0xFF2A65A5, 0xFF2E7D32, 0xFFB5651D, 0xFF4C5157]);
      case SportType.volleyball:
        return _surfaces(const [0xFFF57F17, 0xFF1565C0, 0xFF1B5E20, 0xFF4C5157]);
      case SportType.pickleball:
        return _surfaces(const [0xFF1769B4, 0xFF2E7D32, 0xFF5E35B1, 0xFF4C5157]);
      case SportType.fieldHockey:
        return _surfaces(const [0xFF1976D2, 0xFF2E7D32, 0xFF00897B, 0xFF4C5157]);
      case SportType.rugby:
        return _surfaces(const [0xFF2E7D32, 0xFF1B5E20, 0xFF7C784A, 0xFF4C5157]);
      case SportType.baseball:
        return _surfaces(const [0xFF2E7D32, 0xFF1B5E20, 0xFF7C784A, 0xFF4C5157]);
      case SportType.handball:
        return _surfaces(const [0xFF1565C0, 0xFF2E7D32, 0xFFC44E3B, 0xFF4C5157]);
      case SportType.waterPolo:
        return _surfaces(const [0xFF0277BD, 0xFF01579B, 0xFF00838F, 0xFF4C5157]);
      case SportType.sepakTakraw:
        return _surfaces(const [0xFF1565C0, 0xFF2E7D32, 0xFFC44E3B, 0xFF4C5157]);
      case SportType.beachTennis:
        // Sand only: dry, golden, wet, and the plain grey. A blue option
        // was offered for a sport that is never played on anything but sand.
        return _surfaces(const [0xFFEAC478, 0xFFD4A85C, 0xFFB08A55, 0xFF4C5157]);
      case SportType.footvolley:
        return _surfaces(const [0xFFE5B880, 0xFFD4A85C, 0xFFB08A55, 0xFF4C5157]);
      case SportType.soccer:
        return const []; // soccer uses its own turf palette
    }
  }

  static List<CourtSurface> _surfaces(List<int> argb) => [
        for (final c in argb) CourtSurface(swatch: Color(c), color: Color(c)),
      ];

  /// Court layouts the "Court" picker offers. A single-entry list means no
  /// layout choice. Soccer manages its own (SoccerFieldType) set. Half is
  /// offered for sports where a single-end / single-side view aids coaching.
  List<CourtLayout> get courtLayouts {
    switch (this) {
      case SportType.soccer:
        return const [CourtLayout.full]; // soccer uses its own Pitch sheet
      case SportType.baseball:
        return const [CourtLayout.full, CourtLayout.blank]; // no symmetric half
      case SportType.waterPolo:
        // Wide goal-end courts: also offer the half rotated to face left/right,
        // which fills a portrait screen better than the upright half.
        return const [
          CourtLayout.full,
          CourtLayout.half,
          CourtLayout.halfLeft,
          CourtLayout.halfRight,
          CourtLayout.blank,
        ];
      case SportType.fieldHockey:
        // As water polo, plus the two other pitches hockey is played on:
        // indoor (zaalhockey / Hallenhockey) and the Hockey5s court.
        return const [
          CourtLayout.full,
          CourtLayout.half,
          CourtLayout.halfLeft,
          CourtLayout.halfRight,
          CourtLayout.blank,
          CourtLayout.indoor,
          CourtLayout.hockey5s,
        ];
      case SportType.basketball:
        // The FIBA court, plus the three others the game is played on in
        // the US: NBA, NCAA (men's) and high school (NFHS).
        return const [
          CourtLayout.full,
          CourtLayout.half,
          CourtLayout.blank,
          CourtLayout.nba,
          CourtLayout.ncaa,
          CourtLayout.highSchool,
        ];
      default:
        // Goal sports → one goal end; net sports → one side of the net.
        return const [CourtLayout.full, CourtLayout.half, CourtLayout.blank];
    }
  }

  /// Whether the "Court" appearance picker should be offered for this sport
  /// (i.e. there is at least one colour or layout choice to make). Soccer is
  /// excluded because it has its own richer "Pitch" sheet.
  bool get hasCourtPicker =>
      this != SportType.soccer &&
      (courtSurfaces.length > 1 || courtLayouts.length > 1);

  /// The sport-specific equipment this sport's Add sheet offers.
  ///
  /// Fifteen markers are shared by everybody — cones, people, goals, the
  /// things on a sideline — and are not listed here. These are the pieces
  /// that only make sense somewhere: a home plate has no business in a
  /// soccer coach's sheet, and thirty-two pieces in one list is not a list
  /// any more, it is a search.
  ///
  /// A piece may belong to several sports. The net is the clearest case —
  /// six sports play over one — and a chair is a basketball drill's cone.
  List<MarkerShape> get markers {
    switch (this) {
      case SportType.basketball:
        return const [MarkerShape.hoop, MarkerShape.chair];
      case SportType.badminton:
        return const [
          MarkerShape.net,
          MarkerShape.racket,
          MarkerShape.shuttleTube,
        ];
      case SportType.tableTennis:
        return const [MarkerShape.net, MarkerShape.paddle];
      case SportType.tennis:
        return const [MarkerShape.net, MarkerShape.racket, MarkerShape.hopper];
      case SportType.pickleball:
        return const [
          MarkerShape.net,
          MarkerShape.paddle,
          MarkerShape.hopper,
        ];
      case SportType.beachTennis:
        return const [
          MarkerShape.net,
          MarkerShape.paddle,
          MarkerShape.racket,
          MarkerShape.hopper,
        ];
      case SportType.volleyball:
      case SportType.footvolley:
      case SportType.sepakTakraw:
        return const [MarkerShape.net, MarkerShape.antenna];
      case SportType.baseball:
        return const [
          MarkerShape.base,
          MarkerShape.homePlate,
          MarkerShape.battingTee,
          MarkerShape.lScreen,
        ];
      case SportType.rugby:
        return const [MarkerShape.rugbyPosts, MarkerShape.tackleBag];
      case SportType.fieldHockey:
        return const [MarkerShape.hockeyStick];
      case SportType.waterPolo:
        return const [MarkerShape.floatingGoal, MarkerShape.laneRope];
      case SportType.soccer:
      case SportType.handball:
        return const [];
    }
  }

  /// The body every player of this sport is drawn from.
  ///
  /// One sport is not played in boots. The app was putting a footballer in
  /// white boots and socks in a swimming pool.
  ///
  /// And two are played barefoot on sand: beach tennis and footvolley drew
  /// their players in socks and boots (audit 2026-10-11 m9).
  PlayerFigure get playerBody => switch (this) {
        SportType.waterPolo => PlayerFigure.water,
        SportType.beachTennis || SportType.footvolley => PlayerFigure.barefoot,
        _ => PlayerFigure.plain,
      };

  /// What a player of this sport holds, when they are holding it — null for
  /// the sports where nobody carries anything.
  ///
  /// Tennis and badminton share one racket and the three paddle games share
  /// one paddle: at 36pt the difference between a badminton racket and a
  /// tennis one is two pixels of shaft, and a board is symbolic anyway.
  PlayerFigure? get playerImplement {
    switch (this) {
      case SportType.tennis:
      case SportType.badminton:
        return PlayerFigure.racket;
      case SportType.tableTennis:
      case SportType.pickleball:
        return PlayerFigure.paddle;
      // The same paddle, held by the barefoot body (see playerBody).
      case SportType.beachTennis:
        return PlayerFigure.barefootPaddle;
      case SportType.fieldHockey:
        return PlayerFigure.stick;
      case SportType.baseball:
        return PlayerFigure.bat;
      case SportType.soccer:
      case SportType.basketball:
      case SportType.volleyball:
      case SportType.handball:
      case SportType.rugby:
      case SportType.waterPolo:
      case SportType.sepakTakraw:
      case SportType.footvolley:
        return null;
    }
  }

  /// Whether a player of this sport is holding the implement unless a coach
  /// says otherwise.
  ///
  /// Everyone on a tennis court has a racket in their hand and everyone on a
  /// hockey pitch has a stick. A baseball diamond has one bat and eight
  /// gloves, so there the default is empty hands and the coach marks the
  /// batter.
  bool get implementHeldByDefault => this != SportType.baseball;

  /// Whether a player of this sport can travel with the ball — dribble it,
  /// tuck it, swim with it, hold it in a glove.
  ///
  /// It decides how a moving holder's route is drawn: the squiggle a coach
  /// uses for a carry, or the plain dash of a run. On a badminton court the
  /// shuttle is struck, never carried, so a player walking to meet it was
  /// drawn dribbling it across the floor. Same list as CARRY_SPORTS in
  /// tools/drills/engine.py, which decides whether the ball goes with him
  /// at all.
  bool get canCarryBall => const {
        SportType.soccer,
        SportType.basketball,
        SportType.handball,
        SportType.rugby,
        SportType.waterPolo,
        SportType.fieldHockey,
        SportType.baseball,
      }.contains(this);

  SportGroup get group {
    switch (this) {
      case SportType.soccer:
      case SportType.basketball:
      case SportType.rugby:
      case SportType.fieldHockey:
      case SportType.handball:
        return SportGroup.pitch;
      case SportType.tennis:
      case SportType.badminton:
      case SportType.volleyball:
      case SportType.tableTennis:
      case SportType.pickleball:
      case SportType.beachTennis:
      case SportType.footvolley:
      case SportType.sepakTakraw:
        return SportGroup.net;
      case SportType.baseball:
      case SportType.waterPolo:
        return SportGroup.other;
    }
  }

  /// Normalized Y position of the net (0.5 = center). Home team plays below, away above.
  double get netY => 0.5;

  /// True for racquet/net sports that have singles/doubles variants
  bool get hasDoubles => formations.any((f) => f.nameKey == 'formation_doubles');

  /// Whether the sport's home page offers the match-day substitution sheet.
  ///
  /// Field hockey first: it is what every hockey app from the Netherlands
  /// and Belgium ships, and a coach there expects it. The sheet itself is
  /// sport-agnostic — turn another sport on here and it gets its own
  /// defaults from [matchDayDefaults].
  bool get hasMatchDay => this == SportType.fieldHockey;

  /// How a match of this sport is played, for the match-day sheet: periods,
  /// minutes per period, players on the pitch at once.
  ({int periods, int minutes, int onPitch}) get matchDayDefaults {
    switch (this) {
      case SportType.fieldHockey:
        return (periods: 4, minutes: 15, onPitch: 11);
      case SportType.soccer:
        return (periods: 2, minutes: 45, onPitch: 11);
      case SportType.basketball:
        return (periods: 4, minutes: 10, onPitch: 5);
      case SportType.handball:
        return (periods: 2, minutes: 30, onPitch: 7);
      case SportType.waterPolo:
        return (periods: 4, minutes: 8, onPitch: 7);
      case SportType.rugby:
        return (periods: 2, minutes: 40, onPitch: 15);
      default:
        return (periods: 2, minutes: 30, onPitch: 6);
    }
  }

  /// Which set of words this sport's coach uses for drill categories.
  /// See DrillVocabulary in models/drill.dart.
  DrillVocabulary get drillVocabulary {
    switch (this) {
      case SportType.badminton:
      case SportType.tableTennis:
      case SportType.tennis:
      case SportType.volleyball:
      case SportType.pickleball:
      case SportType.sepakTakraw:
      case SportType.beachTennis:
      case SportType.footvolley:
        return DrillVocabulary.net;
      case SportType.baseball:
        return DrillVocabulary.diamond;
      case SportType.rugby:
        return DrillVocabulary.oval;
      case SportType.basketball:
      case SportType.soccer:
      case SportType.fieldHockey:
      case SportType.handball:
      case SportType.waterPolo:
        return DrillVocabulary.pitch;
    }
  }

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
      // Pickleball, tennis, volleyball and beach tennis: room for a man
      // with his feet behind the far baseline (boards from the old
      // courts: TacticsState.kCourtRedraws).
      case SportType.pickleball:  aspect = 6.1 / 13.41; scaleW = 0.82; scaleH = 0.82; break;
      case SportType.tennis:      aspect = 10.97 / 23.77; scaleW = 0.84; scaleH = 0.84; break;
      case SportType.volleyball:  aspect = 9 / 18;      scaleW = 0.84; scaleH = 0.84; break;
      case SportType.tableTennis: aspect = 1.525 / 2.74; scaleW = 0.65; scaleH = 0.55; break;
      case SportType.fieldHockey: aspect = 55 / 91.4;   scaleW = 0.90; scaleH = 0.90; break;
      case SportType.rugby:       aspect = 70 / 144;    scaleW = 0.92; scaleH = 0.92; break;
      case SportType.baseball:    aspect = 1.0;         scaleW = 0.95; scaleH = 0.95; break;
      case SportType.handball:    aspect = 20 / 40;     scaleW = 0.90; scaleH = 0.90; break;
      case SportType.waterPolo:   aspect = 20 / 25;     scaleW = 0.88; scaleH = 0.88; break;
      case SportType.sepakTakraw: aspect = 6.1 / 13.4;  scaleW = 0.88; scaleH = 0.88; break;
      case SportType.beachTennis: aspect = 8 / 16;      scaleW = 0.84; scaleH = 0.84; break;
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

  /// The formations for the pitch on screen. Field hockey's indoor pitch
  /// and Hockey5s court are other pitches with other numbers (5 + GK, 4 +
  /// GK), drawn inside the same box as the full pitch but narrower
  /// (FieldHockeyCourtPainter.indoorWidthShare / hockey5sWidthShare), so
  /// their x's are pulled in to stay on it. Every other layout is a view of
  /// the full pitch and offers [formations].
  List<SportFormation> formationsOn(CourtLayout layout) {
    if (this != SportType.fieldHockey) return formations;
    switch (layout) {
      case CourtLayout.indoor:
        return const [
        // GK + 2-1-2: two backs, a centre, two up front.
        SportFormation(
          nameKey: 'formation_indoor_212',
          homePositions: [Offset(0.5, 0.94), Offset(0.3338, 0.78), Offset(0.6662, 0.78), Offset(0.5, 0.66), Offset(0.3338, 0.56), Offset(0.6662, 0.56)],
          awayPositions: [Offset(0.5, 0.06), Offset(0.6662, 0.22), Offset(0.3338, 0.22), Offset(0.5, 0.34), Offset(0.6662, 0.44), Offset(0.3338, 0.44)],
        ),
        // GK + 1-2-2: one back, two wide, two up front.
        SportFormation(
          nameKey: 'formation_indoor_122',
          homePositions: [Offset(0.5, 0.94), Offset(0.5, 0.8), Offset(0.2923, 0.68), Offset(0.7077, 0.68), Offset(0.3754, 0.56), Offset(0.6246, 0.56)],
          awayPositions: [Offset(0.5, 0.06), Offset(0.5, 0.2), Offset(0.7077, 0.32), Offset(0.2923, 0.32), Offset(0.6246, 0.44), Offset(0.3754, 0.44)],
        ),
        ];
      case CourtLayout.hockey5s:
        return const [
        // GK + 2-2: the box.
        SportFormation(
          nameKey: 'formation_5s_22',
          homePositions: [Offset(0.5, 0.94), Offset(0.2828, 0.76), Offset(0.7172, 0.76), Offset(0.2828, 0.58), Offset(0.7172, 0.58)],
          awayPositions: [Offset(0.5, 0.06), Offset(0.7172, 0.24), Offset(0.2828, 0.24), Offset(0.7172, 0.42), Offset(0.2828, 0.42)],
        ),
        // GK + 1-2-1: the diamond.
        SportFormation(
          nameKey: 'formation_5s_121',
          homePositions: [Offset(0.5, 0.94), Offset(0.5, 0.8), Offset(0.2236, 0.68), Offset(0.7764, 0.68), Offset(0.5, 0.56)],
          awayPositions: [Offset(0.5, 0.06), Offset(0.5, 0.2), Offset(0.7764, 0.32), Offset(0.2236, 0.32), Offset(0.5, 0.44)],
        ),
        ];
      default:
        return formations;
    }
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
            // Behind the baselines, ready to serve and return; 0.78 was
            // 1.2 m behind the service line, in no-man's-land. A person is
            // drawn centred on his point, so the far man stands 0.05 past
            // his line (tools/drills/tennis.py FAR_BACK): on it, his feet
            // were in the court.
            homePositions: [Offset(0.5, 1.04)],
            awayPositions: [Offset(0.5, -0.05)],
          ),
          SportFormation(
            nameKey: 'formation_doubles',
            // Server at the baseline right, partner at net left;
            // receiver at his baseline, partner at his net.
            homePositions: [Offset(0.7, 1.04), Offset(0.3, 0.60)],
            awayPositions: [Offset(0.3, -0.05), Offset(0.7, 0.40)],
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
        // Court: ~y=0.10..0.90, net at 0.50. Six zones per side.
        return const [
          // Base rotation — front row (4,3,2) + back row (5,6,1)
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
          // Serve receive — 3-passer W: setter releasing to the net, two
          // hitters at the net, three passers in a shallow receiving arc.
          SportFormation(
            nameKey: 'formation_serve_receive',
            homePositions: [
              Offset(0.70, 0.55), // setter releasing to net
              Offset(0.18, 0.58), // outside hitter at net
              Offset(0.44, 0.56), // middle blocker at net
              Offset(0.24, 0.74), // passer left
              Offset(0.54, 0.83), // passer centre (deep)
              Offset(0.84, 0.74), // passer right
            ],
            awayPositions: [
              Offset(0.30, 0.45),
              Offset(0.82, 0.42),
              Offset(0.56, 0.44),
              Offset(0.76, 0.26),
              Offset(0.46, 0.17),
              Offset(0.16, 0.26),
            ],
          ),
          // Perimeter defense — three blockers up, three diggers spread
          // deep to cover the floor.
          SportFormation(
            nameKey: 'formation_defense',
            homePositions: [
              Offset(0.18, 0.57), // wing blocker
              Offset(0.40, 0.56), // middle blocker
              Offset(0.62, 0.56), // wing blocker
              Offset(0.22, 0.79), // digger left
              Offset(0.55, 0.85), // digger deep
              Offset(0.84, 0.78), // digger right
            ],
            awayPositions: [
              Offset(0.82, 0.43),
              Offset(0.60, 0.44),
              Offset(0.38, 0.44),
              Offset(0.78, 0.21),
              Offset(0.45, 0.15),
              Offset(0.16, 0.22),
            ],
          ),
        ];

      case SportType.pickleball:
        return const [
          SportFormation(
            nameKey: 'formation_singles',
            // Singles: ready to serve and return, the FEET behind the
            // baselines. A person is drawn centred on his point, half a
            // figure (~0.043 of the court) above and below it, so the far
            // man stands 0.05 past his line (tools/drills/pickleball.py
            // FAR_BACK); on the line his feet were in the court.
            homePositions: [Offset(0.5, 1.03)],
            awayPositions: [Offset(0.5, -0.05)],
          ),
          SportFormation(
            nameKey: 'formation_doubles',
            // Doubles: all four just behind their kitchen lines (0.66 /
            // 0.34) — 0.72 / 0.28 was in the transition zone — with the
            // whole drawn figure clear of the kitchen (pickleball.py KH /
            // KA): at 0.68 the near pair's heads were over it.
            homePositions: [Offset(0.33, 0.71), Offset(0.67, 0.71)],
            awayPositions: [Offset(0.33, 0.29), Offset(0.67, 0.29)],
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
          // 9v9 (youth, U11-U12): keeper plus three lines
          SportFormation(
            nameKey: 'formation_9v9_332',
            homePositions: [
              Offset(0.5, 0.80),  // GK
              Offset(0.2, 0.71), Offset(0.5, 0.70), Offset(0.8, 0.71), // DEF
              Offset(0.18, 0.60), Offset(0.5, 0.59), Offset(0.82, 0.60), // MID
              Offset(0.36, 0.52), Offset(0.64, 0.52), // FWD (home side of halfway)
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.8, 0.29), Offset(0.5, 0.30), Offset(0.2, 0.29),
              Offset(0.82, 0.40), Offset(0.5, 0.41), Offset(0.18, 0.40),
              Offset(0.64, 0.48), Offset(0.36, 0.48), // FWD (away side of halfway)
            ],
          ),
          SportFormation(
            nameKey: 'formation_9v9_323',
            homePositions: [
              Offset(0.5, 0.80),  // GK
              Offset(0.2, 0.71), Offset(0.5, 0.70), Offset(0.8, 0.71), // DEF
              Offset(0.36, 0.61), Offset(0.64, 0.61), // MID
              Offset(0.15, 0.52), Offset(0.5, 0.51), Offset(0.85, 0.52), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.8, 0.29), Offset(0.5, 0.30), Offset(0.2, 0.29),
              Offset(0.64, 0.39), Offset(0.36, 0.39),
              Offset(0.85, 0.48), Offset(0.5, 0.49), Offset(0.15, 0.48),
            ],
          ),
          SportFormation(
            nameKey: 'formation_9v9_233',
            homePositions: [
              Offset(0.5, 0.80),  // GK
              Offset(0.3, 0.71), Offset(0.7, 0.71), // DEF
              Offset(0.28, 0.60), Offset(0.5, 0.59), Offset(0.72, 0.60), // MID
              Offset(0.15, 0.52), Offset(0.5, 0.51), Offset(0.85, 0.52), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.20),
              Offset(0.7, 0.29), Offset(0.3, 0.29),
              Offset(0.72, 0.40), Offset(0.5, 0.41), Offset(0.28, 0.40),
              Offset(0.85, 0.48), Offset(0.5, 0.49), Offset(0.15, 0.48),
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
            // Four lines in a half, evenly: on a 577pt board a line has to
            // clear the one in front by 0.09 of the height or the figures
            // overlap, and this used to crowd the last two to 0.04 — the
            // midfield standing inside the forwards. The two strikers are
            // also off the centre column, because at 0.46 and 0.54 they are
            // a stride from the OTHER team's midfield line and a board that
            // close needs the width to tell them apart.
            homePositions: [
              Offset(0.5, 0.86),  // GK
              Offset(0.22, 0.76), Offset(0.5, 0.76), Offset(0.78, 0.76), // DEF
              Offset(0.22, 0.66), Offset(0.5, 0.66), Offset(0.78, 0.66), // HALVES
              Offset(0.22, 0.56), Offset(0.5, 0.56), Offset(0.78, 0.56), // MID
              Offset(0.38, 0.46), // FWD
            ],
            awayPositions: [
              Offset(0.5, 0.14),
              Offset(0.78, 0.24), Offset(0.5, 0.24), Offset(0.22, 0.24),
              Offset(0.78, 0.34), Offset(0.5, 0.34), Offset(0.22, 0.34),
              Offset(0.78, 0.44), Offset(0.5, 0.44), Offset(0.22, 0.44),
              Offset(0.62, 0.54),
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
              Offset(0.50, 0.82), // 15 full-back, in front of his try line
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
              Offset(0.50, 0.18),
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
              // Backs (7) — all in front of the try line (y 0.847)
              Offset(0.50, 0.77), // halfback
              Offset(0.40, 0.78), // five-eighth
              Offset(0.28, 0.79), // center L
              Offset(0.70, 0.79), // center R
              Offset(0.10, 0.78), // wing L
              Offset(0.90, 0.78), // wing R
              Offset(0.50, 0.82), // fullback
            ],
            awayPositions: [
              Offset(0.60, 0.34), Offset(0.50, 0.34), Offset(0.40, 0.34),
              Offset(0.58, 0.29), Offset(0.42, 0.29),
              Offset(0.50, 0.26),
              Offset(0.50, 0.23),
              Offset(0.60, 0.22),
              Offset(0.72, 0.21),
              Offset(0.30, 0.21),
              Offset(0.90, 0.22),
              Offset(0.10, 0.22),
              Offset(0.50, 0.18),
            ],
          ),
          // 7s — Rugby Sevens
          SportFormation(
            nameKey: 'formation_7v7',
            homePositions: [
              Offset(0.42, 0.65), Offset(0.50, 0.65), Offset(0.58, 0.65), // forwards
              Offset(0.50, 0.71),                                         // scrum-half
              Offset(0.36, 0.74),                                         // fly-half
              Offset(0.22, 0.77),                                         // centre
              Offset(0.08, 0.79),                                         // wing
            ],
            awayPositions: [
              Offset(0.58, 0.35), Offset(0.50, 0.35), Offset(0.42, 0.35),
              Offset(0.50, 0.29),
              Offset(0.64, 0.26),
              Offset(0.78, 0.23),
              Offset(0.92, 0.21),
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
        // Pool 20m × 25m portrait (World Aquatics 2025 field of play).
        // Goal y=0/1, 2m=0.08, 5m=0.20, 6m=0.24, halfway 0.50. Moved from
        // the old 30 m pool line for line (goal, 2 m, 5 m, 6 m, halfway).
        return const [
          // 7v7 — each team spread in its own half (own goal end), meeting
          // near the halfway line. Home defends the bottom goal, away the top.
          SportFormation(
            nameKey: 'formation_7v7',
            homePositions: [
              Offset(0.50, 0.952), // GK
              Offset(0.50, 0.552), // hole set (CF) — most advanced, near centre
              Offset(0.10, 0.639), // LW
              Offset(0.90, 0.639), // RW
              Offset(0.30, 0.621), // L flat/driver
              Offset(0.70, 0.621), // R flat/driver
              Offset(0.50, 0.708), // point
            ],
            awayPositions: [
              Offset(0.50, 0.048), // GK
              Offset(0.50, 0.448), // hole set (CF)
              Offset(0.90, 0.361), // LW
              Offset(0.10, 0.361), // RW
              Offset(0.70, 0.379), // L flat/driver
              Offset(0.30, 0.379), // R flat/driver
              Offset(0.50, 0.292), // point
            ],
          ),
          // Power play 6 on 5, 4-2: six field attackers + GK against five
          // field defenders + GK (it was 5 on 4, with a defender standing
          // outside the attack). Two on the posts at 2.5 m, four out at
          // 4.5-6 m; the man-down has two on the posts and a zone of three,
          // all goal-side. Same spots as the wp_manup_four_two drill.
          SportFormation(
            nameKey: 'formation_6v5',
            homePositions: [
              Offset(0.50, 0.964),
              Offset(0.14, 0.184), Offset(0.37, 0.251),
              Offset(0.63, 0.251), Offset(0.86, 0.184),
              Offset(0.36, 0.10), Offset(0.64, 0.10),
            ],
            awayPositions: [
              Offset(0.50, 0.044),
              Offset(0.425, 0.064), Offset(0.575, 0.064),
              Offset(0.23, 0.176), Offset(0.50, 0.184), Offset(0.77, 0.176),
            ],
          ),
          // Power play 6 on 5, 3-3: three on the 2 m, three out.
          SportFormation(
            nameKey: 'formation_6v5_33',
            homePositions: [
              Offset(0.50, 0.964),
              Offset(0.20, 0.251), Offset(0.50, 0.286), Offset(0.80, 0.251),
              Offset(0.30, 0.10), Offset(0.50, 0.156), Offset(0.70, 0.10),
            ],
            awayPositions: [
              Offset(0.50, 0.044),
              Offset(0.365, 0.064), Offset(0.635, 0.064),
              Offset(0.32, 0.192), Offset(0.58, 0.212), Offset(0.70, 0.184),
            ],
          ),
          // Power play 6 on 5, umbrella: the point at 9 m, three across the
          // 5 m, two on the posts.
          SportFormation(
            nameKey: 'formation_6v5_umbrella',
            homePositions: [
              Offset(0.50, 0.964),
              Offset(0.50, 0.333), Offset(0.16, 0.20), Offset(0.50, 0.224),
              Offset(0.84, 0.20), Offset(0.35, 0.10), Offset(0.65, 0.10),
            ],
            awayPositions: [
              Offset(0.50, 0.044),
              Offset(0.42, 0.064), Offset(0.58, 0.064),
              Offset(0.27, 0.156), Offset(0.50, 0.136), Offset(0.73, 0.156),
            ],
          ),
          // Even strength 3-3: three on the 2 m (posts and the hole set),
          // three out at 6-7 m, every defender goal-side of his man.
          SportFormation(
            nameKey: 'formation_wp_33',
            homePositions: [
              Offset(0.50, 0.964),
              Offset(0.22, 0.257), Offset(0.50, 0.283), Offset(0.78, 0.257),
              Offset(0.28, 0.108), Offset(0.42, 0.108), Offset(0.72, 0.108),
            ],
            awayPositions: [
              Offset(0.50, 0.044),
              Offset(0.29, 0.204), Offset(0.57, 0.24), Offset(0.71, 0.204),
              Offset(0.21, 0.072), Offset(0.35, 0.072), Offset(0.79, 0.072),
            ],
          ),
          // 5+1 (training / shorter sides) — each team in its own half.
          SportFormation(
            nameKey: 'formation_5v5',
            homePositions: [
              Offset(0.50, 0.952), // GK
              Offset(0.50, 0.587), // hole
              Offset(0.24, 0.673), Offset(0.76, 0.673),
              Offset(0.50, 0.76),
            ],
            awayPositions: [
              Offset(0.50, 0.048),
              Offset(0.50, 0.413),
              Offset(0.76, 0.327), Offset(0.24, 0.327),
              Offset(0.50, 0.24),
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
