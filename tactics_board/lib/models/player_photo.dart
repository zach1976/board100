/// A user-defined named group of avatars (typically one team's roster).
/// Multiple groups support workflows where the app is reused across many
/// teams without their photo libraries mixing together.
class PhotoGroup {
  final String id;
  final String name;
  final int createdAtMs;

  const PhotoGroup({
    required this.id,
    required this.name,
    required this.createdAtMs,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAtMs': createdAtMs,
  };

  factory PhotoGroup.fromJson(Map<String, dynamic> json) => PhotoGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAtMs: (json['createdAtMs'] as num).toInt(),
  );

  PhotoGroup copyWithName(String newName) =>
      PhotoGroup(id: id, name: newName, createdAtMs: createdAtMs);
}

/// What a saved photo is used for. `face` photos are team players; `element`
/// photos are user-defined custom markers (e.g. an obstacle / token image)
/// shown in the markers row instead of the My Teams strip.
enum PlayerPhotoKind { face, element }

/// A member of a squad — a face plus the identity that belongs to the person
/// rather than to any one board: their name, shirt number and position.
///
/// Those three fields are what make a roster survive a tactic: place the squad
/// on a new board and everyone keeps their number, and [role] lets
/// TacticsState.applyFormation drop each player into their own slot instead of
/// the next free one. A member with no photo file (empty [filename]) is still
/// a valid squad member — a number on a shirt.
///
/// Stored locally in the app documents directory and indexed in photos.json.
/// Not synced across devices.
///
/// Face photos belong to a [PhotoGroup] via [groupId]. Element photos
/// have no group — they live in their own bucket as custom markers and
/// remember the [markerShapeIndex] (mapped to MarkerShape) chosen at
/// import so they render as e.g. a square / triangle / diamond filled
/// with the user's photo, not just a circle.
class PlayerPhoto {
  final String id;
  final String filename; // file name within documents/photos/
  final int createdAtMs;
  /// References [PhotoGroup.id]. Null for `element` kind photos.
  final String? groupId;
  final PlayerPhotoKind kind;
  /// MarkerShape.index for `element` photos. -1 / null = circle.
  final int? markerShapeIndex;
  /// Wall-clock timestamps (ms since epoch) of recent uses, kept pruned to
  /// the last 3 days by the library service. Drives the elements-row sort
  /// (most-used in 3 days at the front).
  final List<int> recentUseAtMs;

  /// The player's name, shown under their marker on the board.
  final String? playerName;

  /// Shirt number. Kept as a String: "7" and "07" are different shirts, and
  /// some squads use letters (GK1).
  final String? jerseyNumber;

  /// Position code for the sport this squad plays (PlayerRoles.forSport),
  /// e.g. 'GK', 'CM', 'RW'. Null = unassigned, placed in slot order.
  final String? role;

  const PlayerPhoto({
    required this.id,
    required this.filename,
    required this.createdAtMs,
    this.groupId,
    this.kind = PlayerPhotoKind.face,
    this.markerShapeIndex,
    this.recentUseAtMs = const [],
    this.playerName,
    this.jerseyNumber,
    this.role,
  });

  /// What the board shows under this player: the shirt number when there is
  /// one (it reads at a glance from the touchline), else the name.
  String get boardLabel => (jerseyNumber?.trim().isNotEmpty ?? false)
      ? jerseyNumber!.trim()
      : (playerName?.trim() ?? '');

  /// True once this member carries any squad identity, not just a face.
  bool get hasIdentity =>
      (playerName?.trim().isNotEmpty ?? false) ||
      (jerseyNumber?.trim().isNotEmpty ?? false) ||
      (role?.isNotEmpty ?? false);

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'createdAtMs': createdAtMs,
    'groupId': groupId,
    'kind': kind.name,
    'markerShapeIndex': markerShapeIndex,
    'recentUseAtMs': recentUseAtMs,
    'playerName': playerName,
    'jerseyNumber': jerseyNumber,
    'role': role,
  };

  factory PlayerPhoto.fromJson(Map<String, dynamic> json) => PlayerPhoto(
    id: json['id'] as String,
    filename: json['filename'] as String,
    createdAtMs: (json['createdAtMs'] as num).toInt(),
    groupId: json['groupId'] as String?,
    kind: PlayerPhotoKind.values.firstWhere(
      (k) => k.name == (json['kind'] as String? ?? 'face'),
      orElse: () => PlayerPhotoKind.face,
    ),
    markerShapeIndex: (json['markerShapeIndex'] as num?)?.toInt(),
    recentUseAtMs: ((json['recentUseAtMs'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList(),
    playerName: json['playerName'] as String?,
    jerseyNumber: json['jerseyNumber'] as String?,
    role: json['role'] as String?,
  );

  PlayerPhoto copyWithGroup(String newGroupId) => copyWith(groupId: newGroupId);

  PlayerPhoto copyWith({
    String? filename,
    String? groupId,
    List<int>? recentUseAtMs,
    String? playerName,
    String? jerseyNumber,
    String? role,
    bool clearRole = false,
  }) =>
      PlayerPhoto(
        id: id,
        filename: filename ?? this.filename,
        createdAtMs: createdAtMs,
        groupId: groupId ?? this.groupId,
        kind: kind,
        markerShapeIndex: markerShapeIndex,
        recentUseAtMs: recentUseAtMs ?? this.recentUseAtMs,
        playerName: playerName ?? this.playerName,
        jerseyNumber: jerseyNumber ?? this.jerseyNumber,
        role: clearRole ? null : (role ?? this.role),
      );
}
