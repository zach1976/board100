import 'package:flutter/material.dart';

/// All positions are relative (0.0–1.0) where (0,0) = top-left, (1,1) = bottom-right.
/// Home team = bottom half, Away team = top half (for net sports / basketball).
class SportFormation {
  final String nameKey;
  final List<Offset> homePositions;
  final List<Offset> awayPositions;
  final bool addBall; // place a ball at court center

  const SportFormation({
    required this.nameKey,
    required this.homePositions,
    required this.awayPositions,
    this.addBall = true,
  });

  int get homeCount => homePositions.length;
  int get awayCount => awayPositions.length;
}
