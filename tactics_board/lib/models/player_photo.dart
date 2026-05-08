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

/// A user-uploaded photo. Stored locally in the app documents directory
/// and indexed in photos.json. Not synced across devices.
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

  const PlayerPhoto({
    required this.id,
    required this.filename,
    required this.createdAtMs,
    this.groupId,
    this.kind = PlayerPhotoKind.face,
    this.markerShapeIndex,
    this.recentUseAtMs = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'createdAtMs': createdAtMs,
    'groupId': groupId,
    'kind': kind.name,
    'markerShapeIndex': markerShapeIndex,
    'recentUseAtMs': recentUseAtMs,
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
  );

  PlayerPhoto copyWithGroup(String newGroupId) => PlayerPhoto(
    id: id,
    filename: filename,
    createdAtMs: createdAtMs,
    groupId: newGroupId,
    kind: kind,
    markerShapeIndex: markerShapeIndex,
    recentUseAtMs: recentUseAtMs,
  );
}
