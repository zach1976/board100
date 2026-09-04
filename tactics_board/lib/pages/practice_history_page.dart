import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/practice_session.dart';
import '../models/sport_type.dart';
import '../models/player_photo.dart';
import '../services/photo_library_service.dart';
import '../services/practice_history_service.dart';

const _kBg = Color(0xFF0E1C22);
const _kCard = Color(0xFF15303A);
const _kAccent = Color(0xFF00C2B2);

class PracticeHistoryPage extends StatefulWidget {
  final SportType sport;
  const PracticeHistoryPage({super.key, required this.sport});

  @override
  State<PracticeHistoryPage> createState() => _PracticeHistoryPageState();
}

class _PracticeHistoryPageState extends State<PracticeHistoryPage> {
  List<PracticeSession> _sessions = [];
  List<PlayerPhoto> _squad = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await PracticeHistoryService.list(widget.sport);
    // Attendance is recorded against a squad, so the season view needs the
    // roster to turn ids back into people.
    final groups = await PhotoLibraryService.instance.listGroups();
    final squad = groups.isEmpty
        ? const <PlayerPhoto>[]
        : await PhotoLibraryService.instance.squad(groups.first.id);
    if (!mounted) return;
    setState(() {
      _sessions = list;
      _squad = squad;
      _loading = false;
    });
  }

  /// Sessions where somebody was ticked off — the only ones attendance can be
  /// computed from. A season that predates the feature simply has none.
  List<PracticeSession> get _withAttendance =>
      _sessions.where((s) => s.hasAttendance).toList();

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCard,
        title: Text('practice_history_clear_title'.tr(),
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('clear'.tr(),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PracticeHistoryService.clear(widget.sport);
      _reload();
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final totalSessions = _sessions.length;
    final completedCount = _sessions.where((s) => s.completed).length;
    final totalMinutes =
        _sessions.fold<int>(0, (sum, s) => sum + s.totalSecondsSpent) ~/ 60;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('practice_history'.tr(),
            style: const TextStyle(color: Colors.white)),
        actions: [
          if (_sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'practice_history_clear_title'.tr(),
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history,
                          color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      Text('practice_history_empty'.tr(),
                          style: const TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatCell(
                              label: 'practice_history_sessions'.tr(),
                              value: totalSessions.toString()),
                          _StatCell(
                              label: 'practice_history_completed'.tr(),
                              value: completedCount.toString()),
                          _StatCell(
                              label: 'practice_history_total_min'.tr(),
                              value: totalMinutes.toString()),
                        ],
                      ),
                    ),
                    if (_squad.isNotEmpty && _withAttendance.isNotEmpty)
                      _AttendanceStrip(
                        squad: _squad,
                        sessions: _withAttendance,
                      ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (ctx, i) {
                          final s = _sessions[i];
                          final progress = s.plannedItems == 0
                              ? ''
                              : ' · ${s.itemsCompleted}/${s.plannedItems}';
                          return ListTile(
                            leading: Icon(
                              s.completed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: s.completed
                                  ? _kAccent
                                  : Colors.white38,
                            ),
                            title: Text(s.planName,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              '${_formatDate(s.startedAt)}  ·  ${_formatDuration(s.totalSecondsSpent)}$progress',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: _kAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

/// Who has actually been turning up.
///
/// The question a season log exists to answer isn't "how many sessions did we
/// run" — the totals above already say that — it's "who has missed three in a
/// row". So this sorts by attendance ascending: the people a coach needs to
/// call are at the front, not buried under the ever-presents.
class _AttendanceStrip extends StatelessWidget {
  final List<PlayerPhoto> squad;
  final List<PracticeSession> sessions;
  const _AttendanceStrip({required this.squad, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final s in sessions) {
      for (final id in s.attendeeIds) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    final ranked = squad.toList()
      ..sort((a, b) => (counts[a.id] ?? 0).compareTo(counts[b.id] ?? 0));
    final total = sessions.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_reg_outlined, color: _kAccent, size: 18),
              const SizedBox(width: 6),
              Text('attendance_season_title'.tr(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Text('attendance_of_sessions'.tr(args: ['$total']),
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          for (final m in ranked.take(8)) ...[
            _AttendanceRow(
              member: m,
              attended: counts[m.id] ?? 0,
              total: total,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final PlayerPhoto member;
  final int attended;
  final int total;
  const _AttendanceRow({
    required this.member,
    required this.attended,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : attended / total;
    // Red below half, amber below three quarters: the point of the row is to
    // be scannable, not precise.
    final color = ratio < 0.5
        ? const Color(0xFFFF5A5F)
        : ratio < 0.75
            ? const Color(0xFFFFB020)
            : _kAccent;
    final name = member.playerName?.trim().isNotEmpty == true
        ? member.playerName!
        : (member.boardLabel.isNotEmpty ? member.boardLabel : '—');

    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text('$attended/$total',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12, fontFeatures: [])),
        ),
      ],
    );
  }
}
