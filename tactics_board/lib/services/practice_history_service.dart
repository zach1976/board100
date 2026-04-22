import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/practice_session.dart';
import '../models/sport_type.dart';
import 'auth_service.dart';
import 'sync_service.dart';

class PracticeHistoryService {
  static const int _maxEntries = 200;

  static Future<File> _file(SportType sport) async {
    Directory base;
    try {
      base = await getApplicationDocumentsDirectory();
    } catch (_) {
      base = Directory.systemTemp;
    }
    final dir = Directory('${base.path}/practice_history');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/${sport.name}.json');
  }

  static Future<List<PracticeSession>> list(SportType sport) async {
    final file = await _file(sport);
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString()) as List;
      return data
          .whereType<Map<String, dynamic>>()
          .map(PracticeSession.fromJson)
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(SportType sport, PracticeSession session) async {
    final all = await list(sport);
    all.insert(0, session);
    if (all.length > _maxEntries) {
      all.removeRange(_maxEntries, all.length);
    }
    final file = await _file(sport);
    await file.writeAsString(
        jsonEncode(all.map((s) => s.toJson()).toList()));
    if (AuthService.instance.isLoggedIn) {
      SyncService.instance.pushSession({
        'sport_type': sport.name,
        'plan_name': session.planName,
        'started_at': session.startedAt.toIso8601String(),
        'completed_at': session.completedAt.toIso8601String(),
        'items_completed': session.itemsCompleted,
        'planned_items': session.plannedItems,
        'total_seconds_spent': session.totalSecondsSpent,
        'completed': session.completed,
      });
    }
  }

  static Future<void> clear(SportType sport) async {
    final file = await _file(sport);
    if (await file.exists()) await file.delete();
    if (AuthService.instance.isLoggedIn) {
      SyncService.instance.clearSessions(sportType: sport.name);
    }
  }

  /// Remove history entries referencing a deleted plan.
  static Future<void> purgePlan(SportType sport, String planName) async {
    final all = await list(sport);
    final filtered = all.where((s) => s.planName != planName).toList();
    if (filtered.length == all.length) return;
    final file = await _file(sport);
    await file.writeAsString(
        jsonEncode(filtered.map((s) => s.toJson()).toList()));
  }
}
