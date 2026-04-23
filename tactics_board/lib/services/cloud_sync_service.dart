import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/practice_session.dart';
import '../models/sport_type.dart';
import 'auth_service.dart';
import 'practice_history_service.dart';
import 'sync_service.dart';

/// Orchestrates pull-from-cloud on login and exposes a manual "sync now" entry
/// point. Pushes on save/delete live in the individual services so every write
/// path is covered without threading sync through every call site.
class CloudSyncService {
  static bool _syncing = false;
  static DateTime? _lastSyncAt;
  static DateTime? _lastLocalChangeAt;
  static bool _remoteHasNewer = false;

  /// Notifies listeners (the login page status row) whenever internal state
  /// changes: sync starts/ends, a local write happens, or a probe completes.
  static final ValueNotifier<int> statusTick = ValueNotifier(0);
  static void _bump() => statusTick.value++;

  static bool get isSyncing => _syncing;
  static DateTime? get lastSyncAt => _lastSyncAt;

  /// True when there's at least one local save/delete/rename that happened
  /// after the most recent successful sync. Fire-and-forget pushes may have
  /// already covered it, but this conservatively flags "something to sync".
  static bool get hasLocalPendingChanges {
    if (_lastLocalChangeAt == null) return false;
    if (_lastSyncAt == null) return true;
    return _lastLocalChangeAt!.isAfter(_lastSyncAt!);
  }

  /// True if the last probe found server rows newer than our last pull.
  static bool get hasRemoteUpdates => _remoteHasNewer;

  static bool get needsSync => hasLocalPendingChanges || hasRemoteUpdates;

  /// Call from any local save/delete/rename path so the UI can indicate
  /// "local changes pending sync".
  static void markLocalChange() {
    _lastLocalChangeAt = DateTime.now();
    _bump();
  }

  /// Lightweight check: does the server have rows updated after our last
  /// successful pull? Uses existing list endpoints (metadata only, no data).
  static Future<void> probeRemote() async {
    if (!AuthService.instance.isLoggedIn) {
      _remoteHasNewer = false;
      _bump();
      return;
    }
    if (_lastSyncAt == null) {
      // Never synced on this device session — treat anything on the server
      // as "new" so the UI offers a sync.
      try {
        final lists = await Future.wait([
          SyncService.instance.listTactics(),
          SyncService.instance.listPractices(),
          SyncService.instance.listSessions(),
        ]);
        _remoteHasNewer = lists.any((l) => l.isNotEmpty);
      } catch (_) {
        _remoteHasNewer = false;
      }
      _bump();
      return;
    }
    try {
      final lists = await Future.wait([
        SyncService.instance.listTactics(),
        SyncService.instance.listPractices(),
        SyncService.instance.listSessions(),
      ]);
      final cutoff = _lastSyncAt!;
      bool newer = false;
      for (final items in lists) {
        for (final item in items) {
          final raw = (item['updated_at'] as String?) ??
              (item['completed_at'] as String?) ??
              (item['started_at'] as String?);
          final u = DateTime.tryParse(raw ?? '');
          if (u != null && u.isAfter(cutoff)) {
            newer = true;
            break;
          }
        }
        if (newer) break;
      }
      _remoteHasNewer = newer;
    } catch (e) {
      debugPrint('CloudSync probeRemote error: $e');
    }
    _bump();
  }

  static void reset() {
    _lastSyncAt = null;
    _lastLocalChangeAt = null;
    _remoteHasNewer = false;
    _bump();
  }

  static Future<Directory> _base() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  /// Pull remote → local. Three parallel global fetches (tactics, practices,
  /// history), then file I/O grouped by sport. Previously did 21 sequential
  /// round-trips; now does 3 parallel.
  static Future<void> pullAll() async {
    if (!AuthService.instance.isLoggedIn) return;
    if (_syncing) return;
    _syncing = true;
    _bump();
    try {
      final results = await Future.wait([
        SyncService.instance.pullAll(),
        SyncService.instance.pullAllPractices(),
        SyncService.instance.listSessions(),
      ]);
      final tacticsBySport = _groupBySport(results[0]);
      final practicesBySport = _groupBySport(results[1]);
      final sessionsBySport = _groupBySport(results[2]);

      for (final sport in SportType.values) {
        await _writeTacticsForSport(sport, tacticsBySport[sport.name] ?? const []);
        await _writePracticesForSport(sport, practicesBySport[sport.name] ?? const []);
        await _writeHistoryForSport(sport, sessionsBySport[sport.name] ?? const []);
      }
      _lastSyncAt = DateTime.now();
      _remoteHasNewer = false;
    } catch (e) {
      debugPrint('CloudSync pullAll error: $e');
    } finally {
      _syncing = false;
      _bump();
    }
  }

  /// Push local → remote. Gathers every sport's local files into three
  /// batched payloads, then pushes them in parallel. Previously up to 21
  /// sequential round-trips; now 3 parallel.
  static Future<void> pushAll() async {
    if (!AuthService.instance.isLoggedIn) return;
    final base = await _base();

    final allTactics = <Map<String, dynamic>>[];
    final allPractices = <Map<String, dynamic>>[];
    final allSessions = <Map<String, dynamic>>[];

    for (final sport in SportType.values) {
      final tdir = Directory('${base.path}/tactics/${sport.name}');
      if (await tdir.exists()) {
        await for (final f in tdir.list()) {
          if (f is! File || !f.path.endsWith('.json')) continue;
          try {
            final name = f.path.split('/').last.replaceAll('.json', '');
            final data =
                jsonDecode(await f.readAsString()) as Map<String, dynamic>;
            // Skip placeholder tactics with no players and no strokes. The
            // plan "add tactic" flow creates these before the user edits,
            // and pushing them would overwrite a richer server version that
            // another device already synced.
            final players = (data['players'] as List?) ?? const [];
            final strokes = (data['strokes'] as List?) ?? const [];
            if (players.isEmpty && strokes.isEmpty) continue;
            allTactics
                .add({'name': name, 'sport_type': sport.name, 'data': data});
          } catch (_) {}
        }
      }
      final pdir = Directory('${base.path}/practices/${sport.name}');
      if (await pdir.exists()) {
        await for (final f in pdir.list()) {
          if (f is! File || !f.path.endsWith('.json')) continue;
          try {
            final name = f.path.split('/').last.replaceAll('.json', '');
            final data =
                jsonDecode(await f.readAsString()) as Map<String, dynamic>;
            allPractices
                .add({'name': name, 'sport_type': sport.name, 'data': data});
          } catch (_) {}
        }
      }
      final sessions = await PracticeHistoryService.list(sport);
      for (final s in sessions) {
        allSessions.add({
          'sport_type': sport.name,
          'plan_name': s.planName,
          'started_at': s.startedAt.toIso8601String(),
          'completed_at': s.completedAt.toIso8601String(),
          'items_completed': s.itemsCompleted,
          'planned_items': s.plannedItems,
          'total_seconds_spent': s.totalSecondsSpent,
          'completed': s.completed,
        });
      }
    }

    final pushes = <Future>[];
    if (allTactics.isNotEmpty) {
      pushes.add(SyncService.instance.pushAll(allTactics));
    }
    if (allPractices.isNotEmpty) {
      pushes.add(SyncService.instance.pushAllPractices(allPractices));
    }
    if (allSessions.isNotEmpty) {
      pushes.add(SyncService.instance.pushAllSessions(allSessions));
    }
    if (pushes.isNotEmpty) await Future.wait(pushes);

    _lastSyncAt = DateTime.now();
    _bump();
  }

  static Map<String, List<Map<String, dynamic>>> _groupBySport(
      List<Map<String, dynamic>> rows) {
    final m = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final s = r['sport_type'] as String?;
      if (s == null) continue;
      (m[s] ??= []).add(r);
    }
    return m;
  }

  /// Full sync: push local-only rows first, then pull remote to fill gaps.
  static Future<void> syncNow() async {
    await pushAll();
    await pullAll();
  }

  // ─── internal ────────────────────────────────────────────────────────

  static Future<void> _writeTacticsForSport(
      SportType sport, List<Map<String, dynamic>> remote) async {
    if (remote.isEmpty) return;
    final base = await _base();
    final dir = Directory('${base.path}/tactics/${sport.name}');
    if (!await dir.exists()) await dir.create(recursive: true);

    // syncNow() always pushes first, so by the time we pull, server state
    // already reflects any local-newer changes. Unconditionally write server
    // data back to disk — earlier mtime-based skip logic caused empty local
    // placeholders (e.g., created by the plan "add tactic" flow before real
    // content was synced in) to block updates from the server forever.
    for (final r in remote) {
      final name = r['name'] as String?;
      final data = _decodeDataField(r['data']);
      if (name == null || name.isEmpty || data == null) continue;
      final file = File('${dir.path}/$name.json');
      await file.writeAsString(jsonEncode(data));
    }
  }

  static Future<void> _writePracticesForSport(
      SportType sport, List<Map<String, dynamic>> remote) async {
    if (remote.isEmpty) return;
    final base = await _base();
    final dir = Directory('${base.path}/practices/${sport.name}');
    if (!await dir.exists()) await dir.create(recursive: true);

    for (final r in remote) {
      final name = r['name'] as String?;
      final data = _decodeDataField(r['data']);
      if (name == null || name.isEmpty || data == null) continue;
      final file = File('${dir.path}/$name.json');
      await file.writeAsString(jsonEncode(data));
    }
  }

  static Future<void> _writeHistoryForSport(
      SportType sport, List<Map<String, dynamic>> remote) async {
    if (remote.isEmpty) return;

    final local = await PracticeHistoryService.list(sport);
    final seen = <String>{
      for (final s in local) '${s.planName}|${s.startedAt.toIso8601String()}',
    };

    final toAdd = <PracticeSession>[];
    for (final r in remote) {
      final startedAt =
          DateTime.tryParse(r['started_at'] as String? ?? '') ?? DateTime.now();
      final planName = (r['plan_name'] as String?) ?? '';
      final key = '$planName|${startedAt.toIso8601String()}';
      if (seen.contains(key)) continue;
      seen.add(key);
      toAdd.add(PracticeSession(
        planName: planName,
        startedAt: startedAt,
        completedAt: DateTime.tryParse(r['completed_at'] as String? ?? '') ??
            startedAt,
        itemsCompleted: (r['items_completed'] as num?)?.toInt() ?? 0,
        plannedItems: (r['planned_items'] as num?)?.toInt() ?? 0,
        totalSecondsSpent: (r['total_seconds_spent'] as num?)?.toInt() ?? 0,
        completed: (r['completed'] as bool?) ?? false,
      ));
    }

    if (toAdd.isEmpty) return;
    final merged = [...local, ...toAdd]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final base = await _base();
    final dir = Directory('${base.path}/practice_history');
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/${sport.name}.json');
    await file.writeAsString(
        jsonEncode(merged.map((s) => s.toJson()).toList()));
  }

  /// Laravel's array cast normally returns an object, but if the cast ever
  /// slips a JSON string can arrive instead — decode defensively.
  static Map<String, dynamic>? _decodeDataField(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }
}
