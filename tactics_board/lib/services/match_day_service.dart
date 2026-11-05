import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/match_day.dart';
import '../models/sport_type.dart';
import 'auth_service.dart';
import 'cloud_sync_service.dart';
import 'sync_service.dart';

/// Where a match day lives: one file for the match in progress, so a phone
/// that dies in the third quarter comes back with the clock and the log
/// where they were; and one list of finished matches. Signed in, both ride
/// the same sync as the practice history: a finished match is pushed as it
/// is filed, and [CloudSyncService] pulls the other phone's.
class MatchDayService {
  static const int _maxHistory = 100;

  /// The name the match in progress is stored under on the server.
  static const String currentName = 'current';

  /// The server keeps match days as named documents next to the practice
  /// plans, under a sport key of their own so no plan list ever shows one.
  static String syncSport(SportType sport) => 'matchday.${sport.name}';

  static Future<Directory> _dir() async {
    Directory base;
    try {
      base = await getApplicationDocumentsDirectory();
    } catch (_) {
      base = Directory.systemTemp;
    }
    final dir = Directory('${base.path}/match_day');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _currentFile(SportType sport) async =>
      File('${(await _dir()).path}/${sport.name}_current.json');

  static Future<File> _historyFile(SportType sport) async =>
      File('${(await _dir()).path}/${sport.name}_history.json');

  /// The match in progress, or null.
  static Future<MatchDay?> loadCurrent(SportType sport) async {
    final file = await _currentFile(sport);
    if (!await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) return null;
      return MatchDay.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCurrent(SportType sport, MatchDay match) async {
    match.updatedAt = DateTime.now();
    await writeCurrent(sport, match);
    CloudSyncService.markLocalChange();
  }

  /// Write the match in progress as it is, its written-time untouched —
  /// for a copy that came from the server.
  static Future<void> writeCurrent(SportType sport, MatchDay match) async {
    final file = await _currentFile(sport);
    await file.writeAsString(jsonEncode(match.toJson()));
  }

  static Future<void> clearCurrent(SportType sport) async {
    final file = await _currentFile(sport);
    if (await file.exists()) await file.delete();
  }

  /// Finished matches, newest first.
  static Future<List<MatchDay>> history(SportType sport) async {
    final file = await _historyFile(sport);
    if (!await file.exists()) return [];
    try {
      final data = jsonDecode(await file.readAsString()) as List;
      return data
          .whereType<Map<String, dynamic>>()
          .map(MatchDay.fromJson)
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      return [];
    }
  }

  /// File a finished match and drop it as the one in progress.
  static Future<void> archive(SportType sport, MatchDay match) async {
    match.updatedAt = DateTime.now();
    final all = await history(sport);
    all.removeWhere((m) => m.id == match.id);
    all.insert(0, match);
    if (all.length > _maxHistory) {
      all.removeRange(_maxHistory, all.length);
    }
    await writeHistory(sport, all);
    await clearCurrent(sport);
    CloudSyncService.markLocalChange();
    if (AuthService.instance.isLoggedIn) {
      SyncService.instance.pushPractice(
          match.id, syncSport(sport), match.toJson(),
          clientUpdatedAt: match.updatedAt);
      SyncService.instance.deletePracticeByName(currentName, syncSport(sport),
          clientUpdatedAt: match.updatedAt);
    }
  }

  /// Write the finished matches as given (newest first is kept by sort).
  static Future<void> writeHistory(SportType sport, List<MatchDay> all) async {
    final file = await _historyFile(sport);
    await file.writeAsString(jsonEncode(all.map((m) => m.toJson()).toList()));
  }

  /// Two lists of finished matches as one: the same match (by id) once,
  /// the copy written last winning; newest match first; at most the
  /// hundred kept locally.
  static List<MatchDay> merge(List<MatchDay> local, List<MatchDay> remote) {
    final byId = <String, MatchDay>{};
    for (final m in [...local, ...remote]) {
      final have = byId[m.id];
      if (have == null || m.updatedAt.isAfter(have.updatedAt)) byId[m.id] = m;
    }
    final out = byId.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (out.length > _maxHistory) out.removeRange(_maxHistory, out.length);
    return out;
  }

  static Future<void> clearHistory(SportType sport) async {
    final file = await _historyFile(sport);
    if (await file.exists()) await file.delete();
  }
}
