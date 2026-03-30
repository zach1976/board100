import 'package:flutter/material.dart';
import 'sport_type.dart';

enum PlayerTeam { home, away, neutral }

enum PlayerGender { male, female, unspecified }

// Distinct colors for move arrows/waypoints per player
const _moveColors = [
  Color(0xFF40C4FF), // light blue
  Color(0xFFFF6D6D), // coral red
  Color(0xFF69F0AE), // light green
  Color(0xFFFFD740), // amber
  Color(0xFFEA80FC), // light purple
  Color(0xFF84FFFF), // cyan
  Color(0xFFFF9E80), // light orange
  Color(0xFFA5D6A7), // soft green
];

class PlayerIcon {
  final String id;
  final String label;
  final PlayerTeam team;
  final SportType? sportType; // only set for neutral/ball icons
  Offset position;
  bool isSelected;
  double scale;
  List<Offset> moves; // ordered waypoints after player position
  final Color moveColor; // distinct color for this player's move arrows
  final Color? customColor; // overrides team color when set
  final PlayerGender gender;

  PlayerIcon({
    required this.id,
    required this.label,
    required this.team,
    required this.position,
    this.sportType,
    this.isSelected = false,
    this.scale = 1.0,
    List<Offset>? moves,
    Color? moveColor,
    this.customColor,
    this.gender = PlayerGender.unspecified,
  })  : moves = moves ?? [],
        moveColor = moveColor ?? _moveColors[0];

  static Color moveColorForIndex(int index) =>
      _moveColors[index % _moveColors.length];

  bool get isBall => team == PlayerTeam.neutral && sportType != null;

  PlayerIcon copyWith({
    String? id,
    String? label,
    PlayerTeam? team,
    SportType? sportType,
    Offset? position,
    bool? isSelected,
    double? scale,
    List<Offset>? moves,
    Color? moveColor,
    Color? customColor,
    bool clearCustomColor = false,
    PlayerGender? gender,
  }) {
    return PlayerIcon(
      id: id ?? this.id,
      label: label ?? this.label,
      team: team ?? this.team,
      sportType: sportType ?? this.sportType,
      position: position ?? this.position,
      isSelected: isSelected ?? this.isSelected,
      scale: scale ?? this.scale,
      moves: moves ?? List.of(this.moves),
      moveColor: moveColor ?? this.moveColor,
      customColor: clearCustomColor ? null : (customColor ?? this.customColor),
      gender: gender ?? this.gender,
    );
  }

  static Color teamColor(PlayerTeam team) {
    switch (team) {
      case PlayerTeam.home:
        return const Color(0xFF1565C0);
      case PlayerTeam.away:
        return const Color(0xFFC62828);
      case PlayerTeam.neutral:
        return const Color(0xFF424242);
    }
  }

  Color get color => customColor ?? teamColor(team);
}
