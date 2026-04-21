class PracticeItem {
  final String tacticName;
  int durationMinutes;
  String note;

  PracticeItem({
    required this.tacticName,
    this.durationMinutes = 10,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'tacticName': tacticName,
        'durationMinutes': durationMinutes,
        'note': note,
      };

  factory PracticeItem.fromJson(Map<String, dynamic> j) => PracticeItem(
        tacticName: (j['tacticName'] as String?) ?? '',
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 10,
        note: (j['note'] as String?) ?? '',
      );
}

class Practice {
  String name;
  List<PracticeItem> items;
  String notes;
  final DateTime createdAt;
  DateTime updatedAt;

  Practice({
    required this.name,
    List<PracticeItem>? items,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get totalMinutes =>
      items.fold(0, (sum, it) => sum + it.durationMinutes);

  Map<String, dynamic> toJson() => {
        'name': name,
        'items': items.map((it) => it.toJson()).toList(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Practice.fromJson(Map<String, dynamic> j) => Practice(
        name: (j['name'] as String?) ?? '',
        items: ((j['items'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PracticeItem.fromJson)
            .toList(),
        notes: (j['notes'] as String?) ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
