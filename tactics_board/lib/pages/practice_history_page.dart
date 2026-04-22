import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../models/practice_session.dart';
import '../models/sport_type.dart';
import '../services/practice_history_service.dart';

const _kBg = Color(0xFF0E1C22);
const _kCard = Color(0xFF213E48);
const _kAccent = Color(0xFF00E5CC);

class PracticeHistoryPage extends StatefulWidget {
  final SportType sport;
  const PracticeHistoryPage({super.key, required this.sport});

  @override
  State<PracticeHistoryPage> createState() => _PracticeHistoryPageState();
}

class _PracticeHistoryPageState extends State<PracticeHistoryPage> {
  List<PracticeSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await PracticeHistoryService.list(widget.sport);
    if (!mounted) return;
    setState(() {
      _sessions = list;
      _loading = false;
    });
  }

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
