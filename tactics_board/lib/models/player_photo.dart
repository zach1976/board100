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

/// A user-uploaded face/avatar. Stored locally in the app documents
/// directory and indexed in photos.json. Not synced across devices.
///
/// Each photo belongs to exactly one [PhotoGroup] via [groupId]. Which
/// match-side (home/away) the photo joins on the board is decided per-tap
/// when the avatar is added.
class PlayerPhoto {
  final String id;
  final String filename; // file name within documents/photos/
  final int createdAtMs;
  /// References [PhotoGroup.id]. May be null briefly during migration —
  /// the service moves orphans into the default group on init.
  final String? groupId;

  const PlayerPhoto({
    required this.id,
    required this.filename,
    required this.createdAtMs,
    this.groupId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'createdAtMs': createdAtMs,
    'groupId': groupId,
  };

  factory PlayerPhoto.fromJson(Map<String, dynamic> json) => PlayerPhoto(
    id: json['id'] as String,
    filename: json['filename'] as String,
    createdAtMs: (json['createdAtMs'] as num).toInt(),
    groupId: json['groupId'] as String?,
  );

  PlayerPhoto copyWithGroup(String newGroupId) => PlayerPhoto(
    id: id,
    filename: filename,
    createdAtMs: createdAtMs,
    groupId: newGroupId,
  );
}
