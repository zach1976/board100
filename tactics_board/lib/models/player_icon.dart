import 'package:flutter/material.dart';
import 'sport_type.dart';

enum PlayerTeam { home, away, neutral }

enum PlayerGender { male, female, unspecified }

enum MarkerShape { none, circle, square, triangle, diamond }

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
  List<int> movePhases; // phase number for each move (controls animation order)
  final Color moveColor; // distinct color for this player's move arrows
  final Color? customColor; // overrides team color when set
  final PlayerGender gender;
  final MarkerShape markerShape;

  PlayerIcon({
    required this.id,
    required this.label,
    required this.team,
    required this.position,
    this.sportType,
    this.isSelected = false,
    this.scale = 1.0,
    List<Offset>? moves,
    List<int>? movePhases,
    Color? moveColor,
    this.customColor,
    this.gender = PlayerGender.unspecified,
    this.markerShape = MarkerShape.none,
  })  : moves = moves ?? [],
        movePhases = movePhases ?? [],
        moveColor = moveColor ?? _moveColors[0];

  /// Ensures movePhases list matches moves length, filling gaps with auto-increment
  void syncPhases() {
    while (movePhases.length < moves.length) {
      final next = movePhases.isEmpty ? 0 : movePhases.last + 1;
      movePhases.add(next);
    }
    if (movePhases.length > moves.length) {
      movePhases = movePhases.sublist(0, moves.length);
    }
  }

  static Color moveColorForIndex(int index) =>
      _moveColors[index % _moveColors.length];

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'team': team.index,
    'sportType': sportType?.index,
    'position': [position.dx, position.dy],
    'scale': scale,
    'moves': moves.map((m) => [m.dx, m.dy]).toList(),
    'movePhases': movePhases,
    'moveColor': moveColor.value,
    'customColor': customColor?.value,
    'gender': gender.index,
    'markerShape': markerShape.index,
  };

  factory PlayerIcon.fromJson(Map<String, dynamic> json) => PlayerIcon(
    id: json['id'] as String,
    label: json['label'] as String,
    team: PlayerTeam.values[json['team'] as int],
    sportType: json['sportType'] != null ? SportType.values[json['sportType'] as int] : null,
    position: Offset((json['position'][0] as num).toDouble(), (json['position'][1] as num).toDouble()),
    scale: (json['scale'] as num? ?? 1.0).toDouble(),
    moves: (json['moves'] as List?)?.map((m) => Offset((m[0] as num).toDouble(), (m[1] as num).toDouble())).toList(),
    movePhases: (json['movePhases'] as List?)?.cast<int>(),
    moveColor: json['moveColor'] != null ? Color(json['moveColor'] as int) : null,
    customColor: json['customColor'] != null ? Color(json['customColor'] as int) : null,
    gender: json['gender'] != null ? PlayerGender.values[json['gender'] as int] : PlayerGender.unspecified,
    markerShape: json['markerShape'] != null ? MarkerShape.values[json['markerShape'] as int] : MarkerShape.none,
  );

  bool get isBall => team == PlayerTeam.neutral && sportType != null && markerShape == MarkerShape.none;
  bool get isMarker => markerShape != MarkerShape.none;

  PlayerIcon copyWith({
    String? id,
    String? label,
    PlayerTeam? team,
    SportType? sportType,
    Offset? position,
    bool? isSelected,
    double? scale,
    List<Offset>? moves,
    List<int>? movePhases,
    Color? moveColor,
    Color? customColor,
    bool clearCustomColor = false,
    PlayerGender? gender,
    MarkerShape? markerShape,
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
      movePhases: movePhases ?? List.of(this.movePhases),
      moveColor: moveColor ?? this.moveColor,
      customColor: clearCustomColor ? null : (customColor ?? this.customColor),
      gender: gender ?? this.gender,
      markerShape: markerShape ?? this.markerShape,
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
