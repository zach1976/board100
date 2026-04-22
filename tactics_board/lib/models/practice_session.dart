class PracticeSession {
  final String planName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int itemsCompleted;
  final int plannedItems;
  final int totalSecondsSpent;
  final bool completed;

  PracticeSession({
    required this.planName,
    required this.startedAt,
    required this.completedAt,
    required this.itemsCompleted,
    required this.plannedItems,
    required this.totalSecondsSpent,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'planName': planName,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'itemsCompleted': itemsCompleted,
        'plannedItems': plannedItems,
        'totalSecondsSpent': totalSecondsSpent,
        'completed': completed,
      };

  factory PracticeSession.fromJson(Map<String, dynamic> j) => PracticeSession(
        planName: (j['planName'] as String?) ?? '',
        startedAt: DateTime.tryParse(j['startedAt'] as String? ?? '') ??
            DateTime.now(),
        completedAt: DateTime.tryParse(j['completedAt'] as String? ?? '') ??
            DateTime.now(),
        itemsCompleted: (j['itemsCompleted'] as num?)?.toInt() ?? 0,
        plannedItems: (j['plannedItems'] as num?)?.toInt() ?? 0,
        totalSecondsSpent: (j['totalSecondsSpent'] as num?)?.toInt() ?? 0,
        completed: (j['completed'] as bool?) ?? false,
      );
}
