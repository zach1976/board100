import 'package:flutter/material.dart';

/// Generic court layout offered by the "Court" picker for non-soccer sports.
///
/// `full` draws the whole court; `half` draws a single half (one basket / one
/// side) scaled to fill the board; `halfLeft` / `halfRight` rotate that half
/// ±90° so the goal end faces left / right (offered only for wide goal-end
/// courts where the landscape view fills the screen better); `blank` draws just
/// the surface with no markings. Soccer keeps its own richer set
/// ([SoccerFieldType]). Appended, never reordered — persisted by index.
///
/// `indoor` and `hockey5s` are not views of the pitch but other pitches
/// (field hockey: the FIH indoor pitch and the Hockey5s court), as `nba`,
/// `ncaa` and `highSchool` are basketball's other courts beside FIBA's. A
/// board drawn on one says so (`courtLayout` in its JSON, by name) and
/// reopens on it; see [CourtLayoutPitch.isOwnPitch] and
/// TacticsState.courtLayout.
enum CourtLayout {
  full,
  half,
  blank,
  halfLeft,
  halfRight,
  indoor,
  hockey5s,
  nba,
  ncaa,
  highSchool,
}

extension CourtLayoutPitch on CourtLayout {
  /// A different pitch rather than a way of looking at the full one: the
  /// board that is drawn on it carries it, so it reopens on the same lines.
  bool get isOwnPitch =>
      this == CourtLayout.indoor ||
      this == CourtLayout.hockey5s ||
      this == CourtLayout.nba ||
      this == CourtLayout.ncaa ||
      this == CourtLayout.highSchool;

  /// The pitch a board's JSON names (`courtLayout`), or null for none, an
  /// unknown name, or a layout that is only a view.
  static CourtLayout? fromBoard(Object? name) {
    for (final l in CourtLayout.values) {
      if (l.isOwnPitch && l.name == name) return l;
    }
    return null;
  }
}

/// A selectable court surface colour. [swatch] is the dot shown in the picker;
/// [color] is the fill the painter uses for the playing surface.
class CourtSurface {
  final Color swatch;
  final Color color;
  const CourtSurface({required this.swatch, required this.color});
}
