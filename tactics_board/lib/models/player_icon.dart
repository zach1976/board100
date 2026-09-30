import 'package:flutter/material.dart';
import 'sport_type.dart';

enum PlayerTeam { home, away, neutral }

enum PlayerGender { male, female, unspecified }

/// Which of the moulded figures a token is drawn from.
///
/// Not a property of the player: a sport decides the body (a water polo
/// player is barefoot in a cap, everyone else is in boots) and it decides
/// what is held (a racket, a paddle, a stick, a bat). The player decides
/// only whether they are holding it — see [PlayerIcon.holdsImplement],
/// because a feeder, a resting pair and the coach's cone-setter are all on
/// the same court as the four people swinging.
enum PlayerFigure { plain, racket, paddle, stick, bat, water }

/// The faces a text element can be set in, by the name the board stores.
/// The empty name is the app's own font. Each resolves to a platform face
/// through [textFontFamily], so nothing is bundled: a serif on the phone
/// is Georgia, on Android whatever the system calls serif.
const List<String> kTextFonts = ['', 'serif', 'mono', 'hand'];

/// Appended to, never reordered: a board stores `markerShape.index`, so
/// inserting a value in the middle would turn every saved cone into
/// something else.
enum MarkerShape {
  none, circle, square, triangle, diamond, cone, text, zone, referee,
  coach, ladder, hurdle, arrowMark,
  // 2026-09-23 — ten pieces of equipment that ship as artwork.
  goal, miniGoal, mannequin, pole, disc, ring, rebounder, bench,
  ballBag, cornerFlag,
  // 2026-09-23 — and seventeen that belong to particular sports. Which
  // sport gets which is SportType.markers, not this list.
  hoop, net, antenna, racket, paddle, shuttleTube, hopper, base, homePlate,
  battingTee, lScreen, rugbyPosts, tackleBag, hockeyStick, floatingGoal,
  laneRope, chair,
}

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
  /// How far the icon is turned, in radians, clockwise from its drawn
  /// orientation. Mutable like [scale] and [position] because a drag changes
  /// it every frame.
  ///
  /// Every element used to face one fixed way, which a coach hit the moment
  /// he drew a short corner: "when adding a person to the field they are on
  /// their side and not facing upright". Arrows, hurdles, goals and the
  /// referee all have a direction; a shirt number does not, so the label is
  /// turned back and stays upright.
  double rotation;
  List<Offset> moves; // ordered waypoints after player position
  List<int> movePhases; // phase number for each move (controls animation order)

  /// For a ball: who is carrying it on each leg, or null where it travels on
  /// its own. A carry is drawn once — a waved line on the player — and a pass
  /// is the ball's own line, and the two cannot be told apart by measuring:
  /// after a short pass to a neighbour the passer is still the man standing
  /// nearest the ball at both ends of the leg. Empty on a board that does
  /// not say, and ballEscorts falls back to measuring.
  List<String?> moveCarriers;

  /// For a ball: who has it once each leg is over — the receiver of a pass,
  /// the carrier of a carry — and, in [holder], before the first beat. The
  /// board draws a held ball at its holder's boots; found by "whoever is
  /// nearest", a short pass was drawn arriving at the passer's other foot,
  /// because after it he is often nearer the ball than the man it went to.
  /// Empty on a board that does not say, and the nearest man is used.
  List<String?> moveHolders;
  final String? holder;

  /// For a text element: which face it is set in — one of [kTextFonts],
  /// or null for the app's own. A coach labelling a zone wanted it to look
  /// like a label and not like a shirt number.
  final String? font;
  final Color moveColor; // distinct color for this player's move arrows
  final Color? customColor; // overrides team color when set
  final PlayerGender gender;
  final MarkerShape markerShape;
  /// When set, the icon renders the corresponding photo from the local
  /// PhotoLibrary as its avatar instead of the solid colour disc.
  final String? photoId;
  /// Optional fixed position/role code (e.g. 'GK', 'RB', 'CM' for soccer;
  /// 'PG'..'C' for basketball). When set, the player is placed at the matching
  /// slot whenever a formation is applied, so their identity sticks across
  /// formation changes. Null = unassigned (filled in slot order).
  final String? role;
  /// Whether this player is holding their sport's implement — a racket, a
  /// paddle, a stick, a bat. Ignored by sports that have none.
  ///
  /// Three states, not two. Null means "whatever this sport normally does",
  /// which is the only answer that is right for both a tennis court, where
  /// everyone on it is holding a racket, and a baseball diamond, where one
  /// player in nine is holding a bat. It is also what every board written
  /// before this existed reads back as, so 674 drills needed no migration
  /// and the tennis ones came out holding rackets.
  final bool? holdsImplement;

  /// Whether the coach turned this one by hand.
  ///
  /// A figure normally faces whatever the board says they are about to do —
  /// see boardHeading — and that rule wins over [rotation], which is how a
  /// drill's baked opening stance stops fighting the beat on show. But it
  /// also swallowed the edit bar's own turn buttons: a coach turned a player
  /// 45° and nothing on the pitch moved. Set the moment they do, cleared by
  /// the bar's reset, and while it is set the figure faces [rotation] and
  /// nothing else.
  final bool facingLocked;

  /// For a ball icon: the id of the player currently carrying it. When set, the
  /// ball follows that player's position during drags and animation playback.
  /// Null = loose ball. Only meaningful on a ball ([isBall]).
  final String? attachedTo;

  PlayerIcon({
    required this.id,
    required this.label,
    required this.team,
    required this.position,
    this.sportType,
    this.isSelected = false,
    this.scale = 1.0,
    this.rotation = 0.0,
    List<Offset>? moves,
    List<int>? movePhases,
    List<String?>? moveCarriers,
    List<String?>? moveHolders,
    this.holder,
    this.font,
    Color? moveColor,
    this.customColor,
    this.gender = PlayerGender.unspecified,
    this.markerShape = MarkerShape.none,
    this.photoId,
    this.role,
    this.attachedTo,
    this.holdsImplement,
    this.facingLocked = false,
  })  : moves = moves ?? [],
        movePhases = movePhases ?? [],
        moveCarriers = moveCarriers ?? [],
        moveHolders = moveHolders ?? [],
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
    // Omitted when it is zero, which is nearly every element on nearly every
    // board: a key per icon per save is not worth a number that means "as
    // drawn". A file without it reads back as 0, so old boards need no
    // migration.
    if (rotation != 0) 'rotation': rotation,
    'moves': moves.map((m) => [m.dx, m.dy]).toList(),
    'movePhases': movePhases,
    if (moveCarriers.isNotEmpty) 'moveCarriers': moveCarriers,
    if (moveHolders.isNotEmpty) 'moveHolders': moveHolders,
    if (holder != null) 'holder': holder,
    if (font != null) 'font': font,
    'moveColor': moveColor.toARGB32(),
    'customColor': customColor?.toARGB32(),
    'gender': gender.index,
    'markerShape': markerShape.index,
    'photoId': photoId,
    'role': role,
    'attachedTo': attachedTo,
    // Omitted unless a coach said otherwise, which is nearly every player.
    if (holdsImplement != null) 'holds': holdsImplement,
    if (facingLocked) 'faceLock': true,
  };

  factory PlayerIcon.fromJson(Map<String, dynamic> json) => PlayerIcon(
    id: json['id'] as String,
    label: json['label'] as String,
    team: PlayerTeam.values[json['team'] as int],
    sportType: json['sportType'] != null ? SportType.values[json['sportType'] as int] : null,
    position: Offset((json['position'][0] as num).toDouble(), (json['position'][1] as num).toDouble()),
    scale: (json['scale'] as num? ?? 1.0).toDouble(),
    rotation: (json['rotation'] as num? ?? 0.0).toDouble(),
    moves: (json['moves'] as List?)?.map((m) => Offset((m[0] as num).toDouble(), (m[1] as num).toDouble())).toList(),
    movePhases: (json['movePhases'] as List?)?.cast<int>(),
    moveCarriers: (json['moveCarriers'] as List?)
        ?.map((e) => e as String?)
        .toList(),
    moveHolders: (json['moveHolders'] as List?)
        ?.map((e) => e as String?)
        .toList(),
    holder: json['holder'] as String?,
    font: json['font'] as String?,
    moveColor: json['moveColor'] != null ? Color(json['moveColor'] as int) : null,
    customColor: json['customColor'] != null ? Color(json['customColor'] as int) : null,
    gender: json['gender'] != null ? PlayerGender.values[json['gender'] as int] : PlayerGender.unspecified,
    markerShape: json['markerShape'] != null ? MarkerShape.values[json['markerShape'] as int] : MarkerShape.none,
    photoId: json['photoId'] as String?,
    role: json['role'] as String?,
    attachedTo: json['attachedTo'] as String?,
    holdsImplement: json['holds'] as bool?,
    facingLocked: json['faceLock'] as bool? ?? false,
  );

  /// Whether the label sits inside the disc like a shirt number, or hangs
  /// below it as a name badge. A number (up to two digits) or a single
  /// letter is a shirt; anything else — "X1", "GK", "W1", a real name — is
  /// a name, and two characters crammed into a 44pt circle were unreadable.
  bool get labelInside =>
      label.isNotEmpty &&
      (label.length == 1 || (label.length <= 2 && int.tryParse(label) != null));
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
    double? rotation,
    List<Offset>? moves,
    List<int>? movePhases,
    List<String?>? moveCarriers,
    List<String?>? moveHolders,
    String? holder,
    String? font,
    bool clearFont = false,
    Color? moveColor,
    Color? customColor,
    bool clearCustomColor = false,
    PlayerGender? gender,
    MarkerShape? markerShape,
    String? photoId,
    bool clearPhotoId = false,
    String? role,
    bool clearRole = false,
    String? attachedTo,
    bool clearAttachedTo = false,
    bool? holdsImplement,
    bool clearHolds = false,
    bool? facingLocked,
  }) {
    return PlayerIcon(
      id: id ?? this.id,
      label: label ?? this.label,
      team: team ?? this.team,
      sportType: sportType ?? this.sportType,
      position: position ?? this.position,
      isSelected: isSelected ?? this.isSelected,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      moves: moves ?? List.of(this.moves),
      movePhases: movePhases ?? List.of(this.movePhases),
      moveCarriers: moveCarriers ?? List.of(this.moveCarriers),
      moveHolders: moveHolders ?? List.of(this.moveHolders),
      holder: holder ?? this.holder,
      font: clearFont ? null : (font ?? this.font),
      moveColor: moveColor ?? this.moveColor,
      customColor: clearCustomColor ? null : (customColor ?? this.customColor),
      gender: gender ?? this.gender,
      markerShape: markerShape ?? this.markerShape,
      photoId: clearPhotoId ? null : (photoId ?? this.photoId),
      role: clearRole ? null : (role ?? this.role),
      attachedTo: clearAttachedTo ? null : (attachedTo ?? this.attachedTo),
      holdsImplement: clearHolds ? null : (holdsImplement ?? this.holdsImplement),
      facingLocked: facingLocked ?? this.facingLocked,
    );
  }

  static Color teamColor(PlayerTeam team) {
    switch (team) {
      case PlayerTeam.home:
        return const Color(0xFF3A7DFF); // modern bright blue
      case PlayerTeam.away:
        return const Color(0xFFFF5A5F); // softer coral red
      case PlayerTeam.neutral:
        return const Color(0xFF424242);
    }
  }

  /// The referee and the coach: people among the equipment. They are drawn
  /// as people — the same figure as a player, facing the action — not as
  /// the top-down sprites the rest of the markers are, which put a man
  /// seen from above among players seen from the touchline.
  bool get isPersonMarker =>
      isMarker &&
      (markerShape == MarkerShape.referee || markerShape == MarkerShape.coach);

  Color get color =>
      customColor ??
      (markerShape == MarkerShape.referee
          ? const Color(0xFF212121)
          : markerShape == MarkerShape.coach
              ? const Color(0xFF455A64)
              : teamColor(team));
}
