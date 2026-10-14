/// Descriptive metadata attached to a saved tactics board.
///
/// Stored under the `meta` key of the board's JSON payload rather than in a
/// sidecar file, so it rides along to the cloud through the existing
/// `SyncService.pushTactic` call without any API change. Boards saved before
/// this existed simply have no `meta` key — [fromJson] fills in defaults.
class TacticMeta {
  /// Mirrors the filename. Kept in the payload so a board pulled from the
  /// cloud still knows what it is called.
  final String name;

  /// Empty string means the board sits in the default folder.
  final String folder;

  final String description;

  /// Free-form key points a coach wants to call out when running the board.
  final String coachingPoints;

  /// In the match-day playbook: the handful of set-piece boards a coach
  /// flips through on the touchline. Boards saved before the flag existed
  /// have no key and read back as false.
  final bool playbook;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TacticMeta({
    required this.name,
    this.folder = '',
    this.description = '',
    this.coachingPoints = '',
    this.playbook = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmpty => description.isEmpty && coachingPoints.isEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'folder': folder,
        'description': description,
        'coachingPoints': coachingPoints,
        'playbook': playbook,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TacticMeta.fromJson(Map<String, dynamic> json, {required String name}) {
    DateTime parse(String key, DateTime fallback) {
      final raw = json[key];
      if (raw is! String) return fallback;
      return DateTime.tryParse(raw) ?? fallback;
    }

    final created = parse('createdAt', DateTime.fromMillisecondsSinceEpoch(0));
    return TacticMeta(
      // Trust the filename over the payload: rename only moves the file.
      name: name,
      folder: (json['folder'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      coachingPoints: (json['coachingPoints'] as String?) ?? '',
      playbook: json['playbook'] == true,
      createdAt: created,
      updatedAt: parse('updatedAt', created),
    );
  }

  /// Defaults for a board that has never carried metadata.
  factory TacticMeta.initial(String name, {DateTime? now}) {
    final t = now ?? DateTime.now();
    return TacticMeta(name: name, createdAt: t, updatedAt: t);
  }

  TacticMeta copyWith({
    String? name,
    String? folder,
    String? description,
    String? coachingPoints,
    bool? playbook,
    DateTime? updatedAt,
  }) =>
      TacticMeta(
        name: name ?? this.name,
        folder: folder ?? this.folder,
        description: description ?? this.description,
        coachingPoints: coachingPoints ?? this.coachingPoints,
        playbook: playbook ?? this.playbook,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
