import 'package:flutter/material.dart';

/// Generic court layout offered by the "Court" picker for non-soccer sports.
///
/// `full` draws the whole court; `half` draws a single half (one basket / one
/// side) scaled to fill the board; `blank` draws just the surface with no
/// markings. Soccer keeps its own richer set ([SoccerFieldType]) so this enum
/// stays small and shared by every other sport.
enum CourtLayout { full, half, blank }

/// A selectable court surface colour. [swatch] is the dot shown in the picker;
/// [color] is the fill the painter uses for the playing surface.
class CourtSurface {
  final Color swatch;
  final Color color;
  const CourtSurface({required this.swatch, required this.color});
}
