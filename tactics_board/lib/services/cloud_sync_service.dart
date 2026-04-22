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

  static bool get isSyncing => _syncing;
  static DateTime? get lastSyncAt => _lastSyncAt;

  static Future<Directory> _base() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  /// Pull remote → local for tactics, practices, and history across every
  /// sport. Last-write-wins by server `updated_at` vs local mtime.
  static Future<void> pullAll() async {
    if (!AuthService.instance.isLoggedIn) return;
    if (_syncing) return;
    _syncing = true;
    try {
      for (final sport in SportType.values) {
        await _pullTactics(sport);
        await _pullPractices(sport);
        await _pullHistory(sport);
      }
      _lastSyncAt = DateTime.now();
    } catch (e) {
      debugPrint('CloudSync pullAll error: $e');
    } finally {
      _syncing = false;
    }
  }

  /// Push local → remote. Called rarely (manual sync / first login on a
  /// device with existing local data).
  static Future<void> pushAll() async {
    if (!AuthService.instance.isLoggedIn) return;
    final base = await _base();

    for (final sport in SportType.values) {
      // Tactics
      final tdir = Directory('${base.path}/tactics/${sport.name}');
      if (await tdir.exists()) {
        final payload = <Map<String, dynamic>>[];
        await for (final f in tdir.list()) {
          if (f is! File || !f.path.endsWith('.json')) continue;
          try {
            final name = f.path.split('/').last.replaceAll('.json', '');
            final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
            payload.add({'name': name, 'sport_type': sport.name, 'data': data});
          } catch (_) {}
        }
        if (payload.isNotEmpty) {
          await SyncService.instance.pushAll(payload);
        }
      }

      // Practices
      final pdir = Directory('${base.path}/practices/${sport.name}');
      if (await pdir.exists()) {
        final payload = <Map<String, dynamic>>[];
        await for (final f in pdir.list()) {
          if (f is! File || !f.path.endsWith('.json')) continue;
          try {
            final name = f.path.split('/').last.replaceAll('.json', '');
            final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
            payload.add({'name': name, 'sport_type': sport.name, 'data': data});
          } catch (_) {}
        }
        if (payload.isNotEmpty) {
          await SyncService.instance.pushAllPractices(payload);
        }
      }

      // History
      final sessions = await PracticeHistoryService.list(sport);
      if (sessions.isNotEmpty) {
        await SyncService.instance.pushAllSessions(sessions
            .map((s) => {
                  'sport_type': sport.name,
                  'plan_name': s.planName,
                  'started_at': s.startedAt.toIso8601String(),
                  'completed_at': s.completedAt.toIso8601String(),
                  'items_completed': s.itemsCompleted,
                  'planned_items': s.plannedItems,
                  'total_seconds_spent': s.totalSecondsSpent,
                  'completed': s.completed,
                })
            .toList());
      }
    }
    _lastSyncAt = DateTime.now();
  }

  /// Full sync: push local-only rows first, then pull remote to fill gaps.
  static Future<void> syncNow() async {
    await pushAll();
    await pullAll();
  }

  // ─── internal ────────────────────────────────────────────────────────

  static Future<void> _pullTactics(SportType sport) async {
    final remote = await SyncService.instance.pullAll();
    if (remote.isEmpty) return;
    final base = await _base();
    final dir = Directory('${base.path}/tactics/${sport.name}');
    if (!await dir.exists()) await dir.create(recursive: true);

    for (final r in remote) {
      if (r['sport_type'] != sport.name) continue;
      final name = r['name'] as String?;
      final data = r['data'];
      if (name == null || name.isEmpty || data == null) continue;
      final file = File('${dir.path}/$name.json');
      final updated = DateTime.tryParse(r['updated_at'] as String? ?? '');
      if (await file.exists() && updated != null) {
        final localMtime = await file.lastModified();
        if (localMtime.isAfter(updated)) continue; // local is newer
      }
      await file.writeAsString(jsonEncode(data));
      if (updated != null) {
        try {
          await file.setLastModified(updated);
        } catch (_) {}
      }
    }
  }

  static Future<void> _pullPractices(SportType sport) async {
    final remote =
        await SyncService.instance.pullAllPractices(sportType: sport.name);
    if (remote.isEmpty) return;
    final base = await _base();
    final dir = Directory('${base.path}/practices/${sport.name}');
    if (!await dir.exists()) await dir.create(recursive: true);

    for (final r in remote) {
      final name = r['name'] as String?;
      final data = r['data'];
      if (name == null || name.isEmpty || data is! Map) continue;
      final file = File('${dir.path}/$name.json');
      final updated = DateTime.tryParse(r['updated_at'] as String? ?? '');
      if (await file.exists() && updated != null) {
        try {
          final localJson = jsonDecode(await file.readAsString())
              as Map<String, dynamic>;
          final localUpdated =
              DateTime.tryParse(localJson['updatedAt'] as String? ?? '');
          if (localUpdated != null && localUpdated.isAfter(updated)) continue;
        } catch (_) {}
      }
      await file.writeAsString(jsonEncode(data));
    }
  }

  static Future<void> _pullHistory(SportType sport) async {
    final remote =
        await SyncService.instance.listSessions(sportType: sport.name);
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

    // Merge by rewriting the local file directly (avoid re-pushing via add()).
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
}
