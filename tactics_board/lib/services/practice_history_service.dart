import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/practice_session.dart';
import '../models/sport_type.dart';

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
  }

  static Future<void> clear(SportType sport) async {
    final file = await _file(sport);
    if (await file.exists()) await file.delete();
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
