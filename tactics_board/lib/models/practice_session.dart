/// One session that actually ran.
///
/// [attendeeIds] is what turns a list of sessions into a season: without it a
/// coach can see that Tuesday happened, but not who was there — and "who has
/// missed three in a row" is the question the log exists to answer. Ids are
/// squad member ids (PlayerPhoto.id). Sessions recorded before attendance
/// existed simply have none, and are still valid history.
class PracticeSession {
  final String planName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int itemsCompleted;
  final int plannedItems;
  final int totalSecondsSpent;
  final bool completed;

  /// Squad member ids present. Empty means "not recorded", not "nobody came".
  final List<String> attendeeIds;

  /// The squad this was taken against, so a coach with two teams can tell
  /// whose attendance this was.
  final String? squadId;

  PracticeSession({
    required this.planName,
    required this.startedAt,
    required this.completedAt,
    required this.itemsCompleted,
    required this.plannedItems,
    required this.totalSecondsSpent,
    required this.completed,
    this.attendeeIds = const [],
    this.squadId,
  });

  bool get hasAttendance => attendeeIds.isNotEmpty;

  PracticeSession withAttendance(List<String> ids, String? squad) =>
      PracticeSession(
        planName: planName,
        startedAt: startedAt,
        completedAt: completedAt,
        itemsCompleted: itemsCompleted,
        plannedItems: plannedItems,
        totalSecondsSpent: totalSecondsSpent,
        completed: completed,
        attendeeIds: ids,
        squadId: squad,
      );

  Map<String, dynamic> toJson() => {
        'planName': planName,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'itemsCompleted': itemsCompleted,
        'plannedItems': plannedItems,
        'totalSecondsSpent': totalSecondsSpent,
        'completed': completed,
        'attendeeIds': attendeeIds,
        'squadId': squadId,
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
        attendeeIds:
            ((j['attendeeIds'] as List?) ?? const []).map((e) => '$e').toList(),
        squadId: j['squadId'] as String?,
      );
}
